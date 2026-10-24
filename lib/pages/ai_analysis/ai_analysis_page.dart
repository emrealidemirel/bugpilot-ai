import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:bugpilot_ai/widgets/privacy_controls.dart';
import 'package:go_router/go_router.dart';

import 'package:bugpilot_ai/utils/localization_extensions.dart';
import 'package:bugpilot_ai/theme/app_theme.dart';
import 'package:bugpilot_ai/constants/app_dimensions.dart';
import 'package:bugpilot_ai/widgets/bugpilot_components.dart';
import 'package:bugpilot_ai/models/bug_priority.dart';
import 'package:bugpilot_ai/models/bug_severity.dart';
import 'package:bugpilot_ai/models/bug_test_case_type.dart';
import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:bugpilot_ai/models/bug_test_case.dart';
import 'package:bugpilot_ai/repositories/bug_repository.dart';
import 'package:bugpilot_ai/pages/bug_reports/bug_reports_page.dart';
import 'package:bugpilot_ai/controllers/settings_controller.dart';
import 'package:bugpilot_ai/services/ai_analysis_exception.dart';
import 'package:bugpilot_ai/models/ai_api_error.dart';
import 'package:bugpilot_ai/models/ai_analysis_preferences.dart';
import 'package:bugpilot_ai/models/ai_bug_analysis.dart';
import 'package:bugpilot_ai/services/ai_bug_analysis_service.dart';
import 'package:bugpilot_ai/widgets/ai_analysis_cards.dart';

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
  bool _initialAnalysisStarted = false;
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The request reads the locale, which is not available during initState.
    if (!_initialAnalysisStarted && widget.draft != null) {
      _initialAnalysisStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _runAnalysis();
      });
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
        message: _analysisErrorMessage ?? 'analysisErrorFallback'.tr(),
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
    if (!await requestAiConsent(context) || !mounted) return;
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
        languageCode: context.locale.languageCode,
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
            ? _localizedAnalysisError(error.code)
            : 'analysisErrorFallback'.tr();
        _isAnalyzing = false;
      });
    }
  }

  String _localizedAnalysisError(AiAnalysisErrorCode code) => switch (code) {
    AiAnalysisErrorCode.invalidRequest => 'analysisErrorInvalidRequest'.tr(),
    AiAnalysisErrorCode.aiAnalysisFailed ||
    AiAnalysisErrorCode.unknownError => 'analysisErrorGeneric'.tr(),
    AiAnalysisErrorCode.invalidApiKey => 'analysisErrorInvalidApiKey'.tr(),
    AiAnalysisErrorCode.aiResponseInvalid =>
      'analysisErrorInvalidResponse'.tr(),
    AiAnalysisErrorCode.rateLimited => 'analysisErrorBusy'.tr(),
    AiAnalysisErrorCode.quotaExceeded => 'analysisErrorQuota'.tr(),
    AiAnalysisErrorCode.serviceUnavailable => 'analysisErrorUnavailable'.tr(),
    AiAnalysisErrorCode.requestTimeout => 'analysisErrorTimeout'.tr(),
    AiAnalysisErrorCode.networkError => 'analysisErrorNetwork'.tr(),
    AiAnalysisErrorCode.screenshotUploadFailed =>
      'analysisErrorScreenshot'.tr(),
  };

  Future<void> _regenerateSection(_AnalysisSection section) async {
    if (!await requestAiConsent(context) || !mounted) return;
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
        languageCode: context.locale.languageCode,
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
          content: Text('regenerateAnalysisError'.tr()),
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
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to save bug report ${finalReport.id}: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _saveErrorMessage = 'saveBugReportError'.tr();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('saveBugReportError'.tr()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    widget.onBugSaved();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('analysisSavedSuccess'.tr())));
    setState(() {
      _isSaving = false;
    });
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(BugReportsPage.routePath);
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
      _showSaveValidationError('reproductionStepsRequired'.tr());
      return null;
    }

    final testCases = <BugTestCase>[];
    for (final testCase in analysis.testCases) {
      final title = testCase.title.trim();
      final given = testCase.given.trim();
      final when = testCase.when.trim();
      final then = testCase.then.trim();
      if (title.isEmpty || given.isEmpty || when.isEmpty || then.isEmpty) {
        _showSaveValidationError('testCaseFieldsRequired'.tr());
        return null;
      }
      testCases.add(
        testCase.copyWith(title: title, given: given, when: when, then: then),
      );
    }
    if (_analysisPreferences.testCases && testCases.isEmpty) {
      _showSaveValidationError('validTestCaseRequired'.tr());
      return null;
    }

    final rootCause = analysis.possibleRootCause?.trim();
    if (_analysisPreferences.rootCause &&
        (rootCause == null || rootCause.isEmpty)) {
      _showSaveValidationError('rootCauseRequired'.tr());
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
            title: Text('editSeverityTitle'.tr()),
            content: SegmentedButton<BugSeverity>(
              segments: [
                for (final severity in BugSeverity.values)
                  ButtonSegment(
                    value: severity,
                    label: Text(context.l10n.bugSeverityLabel(severity)),
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
                child: Text('cancelAction'.tr()),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(selected),
                child: Text('applyAction'.tr()),
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
            title: Text('editPriorityTitle'.tr()),
            content: SegmentedButton<BugPriority>(
              segments: [
                for (final priority in BugPriority.values)
                  ButtonSegment(
                    value: priority,
                    label: Text(context.l10n.priorityDescription(priority)),
                    tooltip: context.l10n.priorityDescription(priority),
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
                child: Text('cancelAction'.tr()),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(selected),
                child: Text('applyAction'.tr()),
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
            title: Text('editReproductionStepsTitle'.tr()),
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
                                decoration: InputDecoration(
                                  labelText: 'stepFieldLabel'.tr(),
                                ),
                                onChanged: (value) {
                                  steps[index] = value;
                                },
                              ),
                            ),
                            IconButton(
                              tooltip: 'removeStepTooltip'.tr(),
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
                        label: Text('addStepAction'.tr()),
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
                child: Text('cancelAction'.tr()),
              ),
              FilledButton(
                onPressed: () {
                  final trimmed = steps.map((step) => step.trim()).toList();
                  if (trimmed.isEmpty || trimmed.any((step) => step.isEmpty)) {
                    setDialogState(() {
                      errorText = 'reproductionStepsDialogError'.tr();
                    });
                    return;
                  }
                  Navigator.of(context).pop(trimmed);
                },
                child: Text('applyAction'.tr()),
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
                  ? 'addTestCaseAction'.tr()
                  : 'editTestCaseAction'.tr(),
            ),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<BugTestCaseType>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        labelText: 'testCaseTypeLabel'.tr(),
                      ),
                      items: [
                        for (final type in BugTestCaseType.values)
                          DropdownMenuItem(
                            value: type,
                            child: Text(
                              context.l10n.localizedTestCaseType(type),
                            ),
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
                      decoration: InputDecoration(
                        labelText: 'titleFieldLabel'.tr(),
                      ),
                      onChanged: (value) {
                        title = value;
                      },
                    ),
                    const SizedBox(height: AppDimensions.spacingMedium),
                    TextFormField(
                      initialValue: given,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: 'givenLabel'.tr()),
                      onChanged: (value) {
                        given = value;
                      },
                    ),
                    const SizedBox(height: AppDimensions.spacingMedium),
                    TextFormField(
                      initialValue: when,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: 'whenLabel'.tr()),
                      onChanged: (value) {
                        when = value;
                      },
                    ),
                    const SizedBox(height: AppDimensions.spacingMedium),
                    TextFormField(
                      initialValue: then,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: 'thenLabel'.tr()),
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
                child: Text('cancelAction'.tr()),
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
                      errorText = 'testCaseDialogError'.tr();
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
                child: Text('applyAction'.tr()),
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
            title: Text('editPossibleRootCauseTitle'.tr()),
            content: SizedBox(
              width: 560,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: rootCause,
                    minLines: 4,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: 'possibleRootCauseTitle'.tr(),
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
                child: Text('cancelAction'.tr()),
              ),
              FilledButton(
                onPressed: () {
                  final trimmedRootCause = rootCause.trim();
                  if (trimmedRootCause.isEmpty) {
                    setDialogState(() {
                      errorText = 'rootCauseRequired'.tr();
                    });
                    return;
                  }
                  Navigator.of(context).pop(trimmedRootCause);
                },
                child: Text('applyAction'.tr()),
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
          leading: IconButton(
            tooltip: 'editReportAction'.tr(),
            onPressed: isReviewBusy ? null : onEditReport,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          trailing: const _AiGeneratedLabel(),
        ),
        Text(
          'generatedByAiLabel'.tr(),
          style: textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXSmall),
        Text('analysisReviewDescription'.tr(), style: textTheme.bodyMedium),
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
          label: Text(
            isSaving
                ? 'savingBugReportAction'.tr()
                : 'saveBugReportAction'.tr(),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        TextButton.icon(
          onPressed: isReviewBusy ? null : onEditReport,
          icon: const Icon(Icons.edit_outlined),
          label: Text('editReportAction'.tr()),
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
          Text('analysisLoadingTitle'.tr(), style: textTheme.titleLarge),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            hasScreenshot
                ? 'analysisLoadingWithScreenshot'.tr()
                : 'analysisLoadingWithoutScreenshot'.tr(),
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
          Text('analysisFailedTitle'.tr(), style: textTheme.titleLarge),
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
            label: Text('tryAgainAction'.tr()),
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
            'missingReportDraftTitle'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            'missingReportDraftDescription'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppDimensions.spacingLarge),
          FilledButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text('editReportAction'.tr()),
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
