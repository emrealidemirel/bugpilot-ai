import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/bugpilot_components.dart';
import '../../../bug_reports/domain/enums/bug_priority.dart';
import '../../../bug_reports/domain/enums/bug_severity.dart';
import '../../../bug_reports/domain/enums/bug_test_case_type.dart';
import '../../../bug_reports/domain/models/bug_report.dart';
import '../../../bug_reports/domain/models/bug_test_case.dart';
import '../../../bug_reports/domain/repositories/bug_repository.dart';
import '../../../bug_reports/presentation/pages/bug_reports_page.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../data/exceptions/ai_analysis_exception.dart';
import '../../domain/models/ai_analysis_preferences.dart';
import '../../domain/models/ai_bug_analysis.dart';
import '../../domain/services/ai_bug_analysis_service.dart';
import '../widgets/ai_analysis_cards.dart';

class AiAnalysisPage extends StatefulWidget {
  const AiAnalysisPage({
    required this.draft,
    required this.bugRepository,
    required this.analysisService,
    required this.settingsController,
    required this.onBugSaved,
    super.key,
  });

  static const routePath = '/report/analysis';

  final BugReport? draft;
  final BugRepository bugRepository;
  final AiBugAnalysisService analysisService;
  final SettingsController settingsController;
  final VoidCallback onBugSaved;

  @override
  State<AiAnalysisPage> createState() => _AiAnalysisPageState();
}

enum _AnalysisSection {
  severity,
  priority,
  reproductionSteps,
  testCases,
  rootCause,
}

class _AiAnalysisPageState extends State<AiAnalysisPage> {
  AiBugAnalysis? _originalAnalysis;
  AiBugAnalysis? _analysis;
  Object? _analysisError;
  String? _analysisErrorMessage;
  bool _isAnalyzing = false;
  _AnalysisSection? _regeneratingSection;
  bool _isSaving = false;
  String? _saveErrorMessage;
  bool _severityEdited = false;
  bool _priorityEdited = false;
  bool _reproductionStepsEdited = false;
  bool _testCasesEdited = false;
  bool _rootCauseEdited = false;
  late AiAnalysisPreferences _analysisPreferences;

  @override
  void initState() {
    super.initState();
    _analysisPreferences = AiAnalysisPreferences.fromSettings(
      widget.settingsController.settings,
    );
    if (widget.draft != null) {
      _runAnalysis();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding,
          AppDimensions.pagePadding,
          AppDimensions.pagePadding,
          AppDimensions.pagePadding + AppDimensions.bottomNavigationClearance,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (widget.draft == null) {
      return _MissingDraftState(onBack: _editReport);
    }

    if (_isAnalyzing && _analysis == null) {
      return _AnalyzingState(
        hasScreenshot:
            _analysisPreferences.screenshotAnalysis &&
            widget.draft?.screenshot != null,
      );
    }

    if (_analysisError != null && _analysis == null) {
      return _AnalysisErrorState(
        message:
            _analysisErrorMessage ?? "We couldn't analyze this bug report.",
        onRetry: _runAnalysis,
      );
    }

    final analysis = _analysis;
    if (analysis == null) {
      return _AnalyzingState(
        hasScreenshot:
            _analysisPreferences.screenshotAnalysis &&
            widget.draft?.screenshot != null,
      );
    }

    return _AnalysisSuccessContent(
      draft: widget.draft!,
      analysis: analysis,
      preferences: _analysisPreferences,
      isSaving: _isSaving,
      regeneratingSection: _regeneratingSection,
      severityEdited: _severityEdited,
      priorityEdited: _priorityEdited,
      reproductionStepsEdited: _reproductionStepsEdited,
      testCasesEdited: _testCasesEdited,
      rootCauseEdited: _rootCauseEdited,
      saveErrorMessage: _saveErrorMessage,
      onEditSeverity: _editSeverity,
      onEditPriority: _editPriority,
      onEditReproductionSteps: _editReproductionSteps,
      onAddTestCase: _addTestCase,
      onEditTestCase: _editTestCase,
      onDeleteTestCase: _deleteTestCase,
      onEditRootCause: _editRootCause,
      onRegenerateSection: _regenerateSection,
      onEditReport: _editReport,
      onSave: _saveBugReport,
    );
  }

  Future<void> _runAnalysis() async {
    final draft = widget.draft;
    if (draft == null) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
      _analysisErrorMessage = null;
      _saveErrorMessage = null;
    });

    try {
      final analysis = await widget.analysisService.analyze(
        draft,
        preferences: _analysisPreferences,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _originalAnalysis = analysis;
        _analysis = analysis;
        _severityEdited = false;
        _priorityEdited = false;
        _reproductionStepsEdited = false;
        _testCasesEdited = false;
        _rootCauseEdited = false;
        _isAnalyzing = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _analysisError = error;
        _analysisErrorMessage = error is AiAnalysisException
            ? error.userMessage
            : "We couldn't analyze this bug report.";
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _regenerateSection(_AnalysisSection section) async {
    final draft = widget.draft;
    final current = _analysis;
    if (draft == null || current == null || _regeneratingSection != null) {
      return;
    }

    setState(() {
      _regeneratingSection = section;
      _saveErrorMessage = null;
    });

    try {
      final analysis = await widget.analysisService.analyze(
        draft,
        preferences: _analysisPreferences,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _analysis = _mergeRegeneratedSection(
          current: current,
          regenerated: analysis,
          section: section,
        );
        _setEditedFlag(section, false);
        _regeneratingSection = null;
      });
    } on Object {
      if (!mounted) {
        return;
      }

      setState(() {
        _regeneratingSection = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Could not regenerate the analysis. Please try again.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _saveBugReport() async {
    final draft = widget.draft;
    final analysis = _validatedAnalysisForSave();
    if (draft == null || analysis == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    final finalReport = draft.copyWith(
      severity: analysis.severity,
      priority: analysis.priority,
      reproductionSteps: analysis.reproductionSteps,
      testCases: analysis.testCases,
      possibleRootCause: analysis.possibleRootCause,
      rootCauseConfidence: analysis.rootCauseConfidence,
      updatedAt: DateTime.now(),
    );

    try {
      await widget.bugRepository.createBug(finalReport);
      if (!mounted) {
        return;
      }

      widget.onBugSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bug report saved successfully.')),
      );
      context.go(BugReportsPage.routePath);
    } on Object {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _saveErrorMessage = 'Could not save the bug report. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Could not save the bug report. Please try again.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _editReport() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go('/report');
    }
  }

  AiBugAnalysis _mergeRegeneratedSection({
    required AiBugAnalysis current,
    required AiBugAnalysis regenerated,
    required _AnalysisSection section,
  }) {
    return switch (section) {
      _AnalysisSection.severity => current.copyWith(
        severity: regenerated.severity,
        severityReason: regenerated.severityReason,
      ),
      _AnalysisSection.priority => current.copyWith(
        priority: regenerated.priority,
        priorityReason: regenerated.priorityReason,
      ),
      _AnalysisSection.reproductionSteps => current.copyWith(
        reproductionSteps: regenerated.reproductionSteps,
      ),
      _AnalysisSection.testCases => current.copyWith(
        testCases: regenerated.testCases,
      ),
      _AnalysisSection.rootCause => current.copyWith(
        possibleRootCause: regenerated.possibleRootCause,
        rootCauseConfidence: regenerated.rootCauseConfidence,
      ),
    };
  }

  void _setEditedFlag(_AnalysisSection section, bool edited) {
    switch (section) {
      case _AnalysisSection.severity:
        _severityEdited = edited;
      case _AnalysisSection.priority:
        _priorityEdited = edited;
      case _AnalysisSection.reproductionSteps:
        _reproductionStepsEdited = edited;
      case _AnalysisSection.testCases:
        _testCasesEdited = edited;
      case _AnalysisSection.rootCause:
        _rootCauseEdited = edited;
    }
  }

  Future<void> _editSeverity() async {
    final analysis = _analysis;
    if (analysis == null) {
      return;
    }

    final severity = await _showSeverityDialog(context, analysis.severity);
    if (severity == null || !mounted) {
      return;
    }

    setState(() {
      _analysis = analysis.copyWith(severity: severity);
      _severityEdited = severity != _originalAnalysis?.severity;
      _saveErrorMessage = null;
    });
  }

  Future<void> _editPriority() async {
    final analysis = _analysis;
    if (analysis == null) {
      return;
    }

    final priority = await _showPriorityDialog(context, analysis.priority);
    if (priority == null || !mounted) {
      return;
    }

    setState(() {
      _analysis = analysis.copyWith(priority: priority);
      _priorityEdited = priority != _originalAnalysis?.priority;
      _saveErrorMessage = null;
    });
  }

  Future<void> _editReproductionSteps() async {
    final analysis = _analysis;
    if (analysis == null) {
      return;
    }

    final steps = await _showReproductionStepsDialog(
      context,
      analysis.reproductionSteps,
    );
    if (steps == null || !mounted) {
      return;
    }

    setState(() {
      _analysis = analysis.copyWith(reproductionSteps: steps);
      _reproductionStepsEdited = true;
      _saveErrorMessage = null;
    });
  }

  Future<void> _addTestCase() async {
    final analysis = _analysis;
    if (analysis == null) {
      return;
    }

    final testCase = await _showTestCaseDialog(
      context,
      BugTestCase(
        id: _nextTestCaseId(analysis.testCases),
        type: BugTestCaseType.positive,
        title: '',
        given: '',
        when: '',
        then: '',
      ),
    );
    if (testCase == null || !mounted) {
      return;
    }

    setState(() {
      _analysis = analysis.copyWith(
        testCases: [...analysis.testCases, testCase],
      );
      _testCasesEdited = true;
      _saveErrorMessage = null;
    });
  }

  Future<void> _editTestCase(BugTestCase testCase) async {
    final analysis = _analysis;
    if (analysis == null) {
      return;
    }

    final updated = await _showTestCaseDialog(context, testCase);
    if (updated == null || !mounted) {
      return;
    }

    setState(() {
      _analysis = analysis.copyWith(
        testCases: [
          for (final item in analysis.testCases)
            if (item.id == testCase.id) updated else item,
        ],
      );
      _testCasesEdited = true;
      _saveErrorMessage = null;
    });
  }

  void _deleteTestCase(BugTestCase testCase) {
    final analysis = _analysis;
    if (analysis == null) {
      return;
    }

    setState(() {
      _analysis = analysis.copyWith(
        testCases: [
          for (final item in analysis.testCases)
            if (item.id != testCase.id) item,
        ],
      );
      _testCasesEdited = true;
      _saveErrorMessage = null;
    });
  }

  Future<void> _editRootCause() async {
    final analysis = _analysis;
    if (analysis == null) {
      return;
    }

    final rootCause = await _showRootCauseDialog(
      context,
      analysis.possibleRootCause ?? '',
    );
    if (rootCause == null || !mounted) {
      return;
    }

    setState(() {
      _analysis = analysis.copyWith(possibleRootCause: rootCause);
      _rootCauseEdited = rootCause != _originalAnalysis?.possibleRootCause;
      _saveErrorMessage = null;
    });
  }

  AiBugAnalysis? _validatedAnalysisForSave() {
    final analysis = _analysis;
    if (analysis == null) {
      return null;
    }

    final steps = analysis.reproductionSteps
        .map((step) => step.trim())
        .where((step) => step.isNotEmpty)
        .toList();
    if (steps.length != analysis.reproductionSteps.length || steps.isEmpty) {
      _showSaveValidationError(
        'Add at least one reproduction step and remove empty steps before saving.',
      );
      return null;
    }

    final testCases = <BugTestCase>[];
    for (final testCase in analysis.testCases) {
      final title = testCase.title.trim();
      final given = testCase.given.trim();
      final when = testCase.when.trim();
      final then = testCase.then.trim();
      if (title.isEmpty || given.isEmpty || when.isEmpty || then.isEmpty) {
        _showSaveValidationError(
          'Complete every test case field before saving.',
        );
        return null;
      }
      testCases.add(
        testCase.copyWith(title: title, given: given, when: when, then: then),
      );
    }
    if (_analysisPreferences.testCases && testCases.isEmpty) {
      _showSaveValidationError(
        'Add at least one valid test case before saving.',
      );
      return null;
    }

    final rootCause = analysis.possibleRootCause?.trim();
    if (_analysisPreferences.rootCause &&
        (rootCause == null || rootCause.isEmpty)) {
      _showSaveValidationError(
        'Enter a possible root-cause hypothesis before saving.',
      );
      return null;
    }

    final trimmedAnalysis = analysis.copyWith(
      reproductionSteps: steps,
      testCases: testCases,
      possibleRootCause: rootCause,
    );
    _analysis = trimmedAnalysis;
    return trimmedAnalysis;
  }

  void _showSaveValidationError(String message) {
    setState(() {
      _saveErrorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  String _nextTestCaseId(List<BugTestCase> testCases) {
    final idPattern = RegExp(r'^TC-(\d+)$');
    var maxNumber = 0;
    for (final testCase in testCases) {
      final match = idPattern.firstMatch(testCase.id);
      if (match == null) {
        continue;
      }
      final number = int.tryParse(match.group(1)!);
      if (number != null && number > maxNumber) {
        maxNumber = number;
      }
    }

    final next = maxNumber == 0 ? testCases.length + 1 : maxNumber + 1;
    return 'TC-${next.toString().padLeft(2, '0')}';
  }
}

Future<BugSeverity?> _showSeverityDialog(
  BuildContext context,
  BugSeverity? current,
) {
  var selected = current ?? BugSeverity.medium;

  return showDialog<BugSeverity>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Severity'),
            content: SegmentedButton<BugSeverity>(
              segments: [
                for (final severity in BugSeverity.values)
                  ButtonSegment(value: severity, label: Text(severity.label)),
              ],
              selected: {selected},
              onSelectionChanged: (values) {
                setDialogState(() {
                  selected = values.single;
                });
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(selected),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<BugPriority?> _showPriorityDialog(
  BuildContext context,
  BugPriority? current,
) {
  var selected = current ?? BugPriority.p2;

  return showDialog<BugPriority>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Priority'),
            content: SegmentedButton<BugPriority>(
              segments: [
                for (final priority in BugPriority.values)
                  ButtonSegment(
                    value: priority,
                    label: Text(priority.label),
                    tooltip: priority.description,
                  ),
              ],
              selected: {selected},
              onSelectionChanged: (values) {
                setDialogState(() {
                  selected = values.single;
                });
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(selected),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<List<String>?> _showReproductionStepsDialog(
  BuildContext context,
  List<String> currentSteps,
) async {
  final steps = currentSteps.isEmpty ? [''] : [...currentSteps];
  String? errorText;

  return showDialog<List<String>>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Reproduction Steps'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < steps.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppDimensions.spacingSmall,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Text('${index + 1}.'),
                            ),
                            const SizedBox(width: AppDimensions.spacingSmall),
                            Expanded(
                              child: TextFormField(
                                initialValue: steps[index],
                                minLines: 1,
                                maxLines: 3,
                                textInputAction: TextInputAction.newline,
                                decoration: const InputDecoration(
                                  labelText: 'Step',
                                ),
                                onChanged: (value) {
                                  steps[index] = value;
                                },
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove step',
                              onPressed: steps.length == 1
                                  ? null
                                  : () {
                                      setDialogState(() {
                                        steps.removeAt(index);
                                        errorText = null;
                                      });
                                    },
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            steps.add('');
                            errorText = null;
                          });
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Step'),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: AppDimensions.spacingSmall),
                      Text(
                        errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final trimmed = steps.map((step) => step.trim()).toList();
                  if (trimmed.isEmpty || trimmed.any((step) => step.isEmpty)) {
                    setDialogState(() {
                      errorText =
                          'Add at least one step and remove empty steps.';
                    });
                    return;
                  }
                  Navigator.of(context).pop(trimmed);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<BugTestCase?> _showTestCaseDialog(
  BuildContext context,
  BugTestCase testCase,
) async {
  var title = testCase.title;
  var given = testCase.given;
  var when = testCase.when;
  var then = testCase.then;
  var selectedType = testCase.type ?? BugTestCaseType.positive;
  String? errorText;

  return showDialog<BugTestCase>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              testCase.title.trim().isEmpty
                  ? 'Add Test Case'
                  : 'Edit Test Case',
            ),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<BugTestCaseType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: [
                        for (final type in BugTestCaseType.values)
                          DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedType = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppDimensions.spacingMedium),
                    TextFormField(
                      initialValue: title,
                      decoration: const InputDecoration(labelText: 'Title'),
                      onChanged: (value) {
                        title = value;
                      },
                    ),
                    const SizedBox(height: AppDimensions.spacingMedium),
                    TextFormField(
                      initialValue: given,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Given'),
                      onChanged: (value) {
                        given = value;
                      },
                    ),
                    const SizedBox(height: AppDimensions.spacingMedium),
                    TextFormField(
                      initialValue: when,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'When'),
                      onChanged: (value) {
                        when = value;
                      },
                    ),
                    const SizedBox(height: AppDimensions.spacingMedium),
                    TextFormField(
                      initialValue: then,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Then'),
                      onChanged: (value) {
                        then = value;
                      },
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: AppDimensions.spacingMedium),
                      Text(
                        errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final trimmedTitle = title.trim();
                  final trimmedGiven = given.trim();
                  final trimmedWhen = when.trim();
                  final trimmedThen = then.trim();
                  if (trimmedTitle.isEmpty ||
                      trimmedGiven.isEmpty ||
                      trimmedWhen.isEmpty ||
                      trimmedThen.isEmpty) {
                    setDialogState(() {
                      errorText = 'Complete Title, Given, When, and Then.';
                    });
                    return;
                  }
                  Navigator.of(context).pop(
                    testCase.copyWith(
                      type: selectedType,
                      title: trimmedTitle,
                      given: trimmedGiven,
                      when: trimmedWhen,
                      then: trimmedThen,
                    ),
                  );
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<String?> _showRootCauseDialog(
  BuildContext context,
  String currentRootCause,
) async {
  var rootCause = currentRootCause;
  String? errorText;

  return showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Possible Root Cause'),
            content: SizedBox(
              width: 560,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: rootCause,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Possible Root Cause',
                    ),
                    onChanged: (value) {
                      rootCause = value;
                    },
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: AppDimensions.spacingMedium),
                    Text(
                      errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final trimmedRootCause = rootCause.trim();
                  if (trimmedRootCause.isEmpty) {
                    setDialogState(() {
                      errorText = 'Enter a possible root-cause hypothesis.';
                    });
                    return;
                  }
                  Navigator.of(context).pop(trimmedRootCause);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _AnalysisSuccessContent extends StatelessWidget {
  const _AnalysisSuccessContent({
    required this.draft,
    required this.analysis,
    required this.preferences,
    required this.isSaving,
    required this.regeneratingSection,
    required this.severityEdited,
    required this.priorityEdited,
    required this.reproductionStepsEdited,
    required this.testCasesEdited,
    required this.rootCauseEdited,
    required this.onEditSeverity,
    required this.onEditPriority,
    required this.onEditReproductionSteps,
    required this.onAddTestCase,
    required this.onEditTestCase,
    required this.onDeleteTestCase,
    required this.onEditRootCause,
    required this.onRegenerateSection,
    required this.onEditReport,
    required this.onSave,
    this.saveErrorMessage,
  });

  final BugReport draft;
  final AiBugAnalysis analysis;
  final AiAnalysisPreferences preferences;
  final bool isSaving;
  final _AnalysisSection? regeneratingSection;
  final bool severityEdited;
  final bool priorityEdited;
  final bool reproductionStepsEdited;
  final bool testCasesEdited;
  final bool rootCauseEdited;
  final String? saveErrorMessage;
  final VoidCallback onEditSeverity;
  final VoidCallback onEditPriority;
  final VoidCallback onEditReproductionSteps;
  final VoidCallback onAddTestCase;
  final ValueChanged<BugTestCase> onEditTestCase;
  final ValueChanged<BugTestCase> onDeleteTestCase;
  final VoidCallback onEditRootCause;
  final ValueChanged<_AnalysisSection> onRegenerateSection;
  final VoidCallback onEditReport;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isReviewBusy = isSaving || regeneratingSection != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BugPilotAppHeader(
          title: 'AI Analysis',
          subtitle: 'Review the suggestions before saving the bug report.',
          leading: IconButton(
            tooltip: 'Edit Report',
            onPressed: isReviewBusy ? null : onEditReport,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          trailing: const _AiGeneratedLabel(),
        ),
        Text(
          'GENERATED BY AI',
          style: textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXSmall),
        Text(
          'AI has drafted triage metadata, reproduction guidance and QA coverage from your report.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppDimensions.spacingLarge),
        const AiDisclaimerCard(),
        const SizedBox(height: AppDimensions.spacingMedium),
        AnalysisSummaryCard(
          analysis: analysis,
          preferences: preferences,
          severityEdited: severityEdited,
          priorityEdited: priorityEdited,
          isRegeneratingSeverity:
              regeneratingSection == _AnalysisSection.severity,
          isRegeneratingPriority:
              regeneratingSection == _AnalysisSection.priority,
          onEditSeverity: isReviewBusy ? null : onEditSeverity,
          onEditPriority: isReviewBusy ? null : onEditPriority,
          onRegenerateSeverity: isReviewBusy || !preferences.severity
              ? null
              : () => onRegenerateSection(_AnalysisSection.severity),
          onRegeneratePriority: isReviewBusy || !preferences.priority
              ? null
              : () => onRegenerateSection(_AnalysisSection.priority),
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        ReproductionStepsCard(
          steps: analysis.reproductionSteps,
          isEdited: reproductionStepsEdited,
          isRegenerating:
              regeneratingSection == _AnalysisSection.reproductionSteps,
          onEdit: isReviewBusy ? null : onEditReproductionSteps,
          onRegenerate: isReviewBusy
              ? null
              : () => onRegenerateSection(_AnalysisSection.reproductionSteps),
        ),
        if (preferences.testCases) ...[
          const SizedBox(height: AppDimensions.spacingMedium),
          TestCasesCard(
            testCases: analysis.testCases,
            isEdited: testCasesEdited,
            isRegenerating: regeneratingSection == _AnalysisSection.testCases,
            onAdd: isReviewBusy ? null : onAddTestCase,
            onEdit: isReviewBusy ? null : onEditTestCase,
            onDelete: isReviewBusy ? null : onDeleteTestCase,
            onRegenerate: isReviewBusy
                ? null
                : () => onRegenerateSection(_AnalysisSection.testCases),
          ),
        ],
        if (preferences.rootCause) ...[
          const SizedBox(height: AppDimensions.spacingMedium),
          PossibleRootCauseCard(
            possibleRootCause: analysis.possibleRootCause ?? '',
            confidence: analysis.rootCauseConfidence,
            isEdited: rootCauseEdited,
            isRegenerating: regeneratingSection == _AnalysisSection.rootCause,
            onEdit: isReviewBusy ? null : onEditRootCause,
            onRegenerate: isReviewBusy
                ? null
                : () => onRegenerateSection(_AnalysisSection.rootCause),
          ),
        ],
        const SizedBox(height: AppDimensions.spacingMedium),
        MissingInformationCard(items: analysis.missingInformation),
        const SizedBox(height: AppDimensions.spacingMedium),
        QualityScoreCard(analysis: analysis, draft: draft),
        if (saveErrorMessage != null) ...[
          const SizedBox(height: AppDimensions.spacingMedium),
          Text(
            saveErrorMessage!,
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: AppDimensions.spacingXLarge),
        FilledButton.icon(
          onPressed: isReviewBusy ? null : onSave,
          icon: isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text(isSaving ? 'Saving...' : 'SAVE BUG REPORT'),
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        TextButton.icon(
          onPressed: isReviewBusy ? null : onEditReport,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Report'),
        ),
      ],
    );
  }
}

class _AnalyzingState extends StatelessWidget {
  const _AnalyzingState({required this.hasScreenshot});

  final bool hasScreenshot;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.spacingXLarge,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 44,
            color: AppTheme.primary,
          ),
          const SizedBox(height: AppDimensions.spacingLarge),
          Text('Analyzing bug report...', style: textTheme.titleLarge),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            hasScreenshot
                ? 'Analyzing bug details and screenshot for reproduction steps, test cases, severity, priority and possible root cause.'
                : 'Generating reproduction steps, test cases, severity, priority and possible root cause.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: AppDimensions.spacingLarge),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }
}

class _AnalysisErrorState extends StatelessWidget {
  const _AnalysisErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.spacingXLarge,
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 44,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppDimensions.spacingLarge),
          Text('Analysis failed', style: textTheme.titleLarge),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: AppDimensions.spacingLarge),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _MissingDraftState extends StatelessWidget {
  const _MissingDraftState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.spacingXLarge,
      ),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 44,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppDimensions.spacingLarge),
          Text(
            'No report draft found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            'Start from the report form so the analysis has bug details to review.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppDimensions.spacingLarge),
          FilledButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Edit Report'),
          ),
        ],
      ),
    );
  }
}

class _AiGeneratedLabel extends StatelessWidget {
  const _AiGeneratedLabel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSmall,
          vertical: AppDimensions.spacingXSmall,
        ),
        child: Text(
          'AI',
          style: TextStyle(
            color: AppTheme.primary,
            fontFamily: AppTheme.uiFontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
