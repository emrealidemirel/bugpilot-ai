import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:bugpilot_ai/utils/localization_extensions.dart';
import 'package:bugpilot_ai/theme/app_theme.dart';
import 'package:bugpilot_ai/constants/app_dimensions.dart';
import 'package:bugpilot_ai/utils/date_label_formatter.dart';
import 'package:bugpilot_ai/widgets/bugpilot_components.dart';
import 'package:bugpilot_ai/pages/ai_analysis/ai_analysis_page.dart';
import 'package:bugpilot_ai/models/bug_platform.dart';
import 'package:bugpilot_ai/models/bug_status.dart';
import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:bugpilot_ai/models/bug_screenshot.dart';
import 'package:bugpilot_ai/repositories/bug_repository.dart';
import 'package:bugpilot_ai/pages/bug_reports/bug_reports_page.dart';
import 'package:bugpilot_ai/utils/bug_form_validators.dart';
import 'package:bugpilot_ai/widgets/bug_metadata_item.dart';
import 'package:bugpilot_ai/widgets/bug_status_chip.dart';
import 'package:bugpilot_ai/pages/dashboard/dashboard_page.dart';
import 'package:bugpilot_ai/widgets/priority_badge.dart';
import 'package:bugpilot_ai/widgets/severity_badge.dart';
import 'package:bugpilot_ai/models/duplicate_check_result.dart';
import 'package:bugpilot_ai/models/similar_bug_candidate.dart';
import 'package:bugpilot_ai/services/bug_duplicate_detection_service.dart';
import 'package:bugpilot_ai/services/local_bug_similarity_service.dart';
import 'package:bugpilot_ai/controllers/settings_controller.dart';
import 'package:bugpilot_ai/widgets/screenshot_picker.dart';

class ReportBugPage extends StatefulWidget {
  const ReportBugPage({
    required this.bugRepository,
    required this.duplicateDetectionService,
    required this.settingsController,
    this.localSimilarityService = const LocalBugSimilarityService(),
    this.resetSignal,
    super.key,
  });

  static const routePath = '/report';

  final BugRepository bugRepository;
  final BugDuplicateDetectionService duplicateDetectionService;
  final SettingsController settingsController;
  final LocalBugSimilarityService localSimilarityService;
  final ValueListenable<int>? resetSignal;

  @override
  State<ReportBugPage> createState() => _ReportBugPageState();
}

class _ReportBugPageState extends State<ReportBugPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _expectedBehaviorController = TextEditingController();
  final _actualBehaviorController = TextEditingController();
  final _deviceController = TextEditingController();
  final _osVersionController = TextEditingController();
  final _appVersionController = TextEditingController();
  final _logsController = TextEditingController();

  BugPlatform? _platform;
  BugScreenshot? _screenshot;
  bool _isAnalyzing = false;
  bool _allowNextPop = false;
  int? _lastResetValue;

  @override
  void initState() {
    super.initState();
    _lastResetValue = widget.resetSignal?.value;
    widget.resetSignal?.addListener(_handleExternalReset);
    for (final controller in _controllers) {
      controller.addListener(_handleInputChanged);
    }
    _applyDefaultEnvironment();
  }

  @override
  void didUpdateWidget(covariant ReportBugPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetSignal == widget.resetSignal) {
      return;
    }

    oldWidget.resetSignal?.removeListener(_handleExternalReset);
    _lastResetValue = widget.resetSignal?.value;
    widget.resetSignal?.addListener(_handleExternalReset);
  }

  @override
  void dispose() {
    widget.resetSignal?.removeListener(_handleExternalReset);
    for (final controller in _controllers) {
      controller
        ..removeListener(_handleInputChanged)
        ..dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get _controllers {
    return [
      _titleController,
      _descriptionController,
      _expectedBehaviorController,
      _actualBehaviorController,
      _deviceController,
      _osVersionController,
      _appVersionController,
      _logsController,
    ];
  }

  bool get _hasUnsavedChanges {
    return _platform != null ||
        _screenshot != null ||
        _controllers.any((controller) => controller.text.trim().isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: _allowNextPop || !_hasUnsavedChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.pagePadding,
              AppDimensions.pagePadding,
              AppDimensions.pagePadding,
              AppDimensions.pagePadding +
                  AppDimensions.bottomNavigationClearance +
                  MediaQuery.viewInsetsOf(context).bottom,
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BugPilotAppHeader(),
                    _FormSection(
                      title: l10n.issueSectionTitle,
                      children: [
                        _LabeledField(
                          label: l10n.bugTitleFieldLabel,
                          child: TextFormField(
                            controller: _titleController,
                            enabled: !_isAnalyzing,
                            decoration: InputDecoration(
                              hintText: l10n.bugTitleFieldHint,
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.next,
                            maxLength: 120,
                            validator: (value) =>
                                BugFormValidators.title(context, value),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingXLarge),
                        _LabeledField(
                          label: l10n.descriptionFieldLabel,
                          child: TextFormField(
                            controller: _descriptionController,
                            enabled: !_isAnalyzing,
                            decoration: InputDecoration(
                              hintText: l10n.descriptionFieldHint,
                            ),
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.newline,
                            minLines: 4,
                            maxLines: 6,
                            validator: (value) =>
                                BugFormValidators.description(context, value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingXXLarge),
                    _FormSection(
                      title: l10n.behaviorSectionTitle,
                      children: [
                        _LabeledField(
                          label: l10n.expectedBehaviorFieldLabel,
                          child: TextFormField(
                            controller: _expectedBehaviorController,
                            enabled: !_isAnalyzing,
                            decoration: InputDecoration(
                              hintText: l10n.expectedBehaviorFieldHint,
                            ),
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.newline,
                            minLines: 3,
                            maxLines: 5,
                            validator: (value) =>
                                BugFormValidators.requiredText(context, value),
                          ),
                        ),
                        const Divider(height: 40),
                        _LabeledField(
                          label: l10n.actualBehaviorFieldLabel,
                          child: TextFormField(
                            controller: _actualBehaviorController,
                            enabled: !_isAnalyzing,
                            decoration: InputDecoration(
                              hintText: l10n.actualBehaviorFieldHint,
                            ),
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.newline,
                            minLines: 3,
                            maxLines: 5,
                            validator: (value) =>
                                BugFormValidators.requiredText(context, value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingXXLarge),
                    _FormSection(
                      title: l10n.environmentSectionTitle,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final useTwoColumns =
                                constraints.maxWidth >= 560 &&
                                MediaQuery.textScalerOf(context).scale(16) <=
                                    20;
                            final fieldWidth =
                                (constraints.maxWidth -
                                    AppDimensions.spacingMedium) /
                                2;

                            return Wrap(
                              spacing: AppDimensions.spacingMedium,
                              runSpacing: AppDimensions.spacingLarge,
                              children: [
                                SizedBox(
                                  width: useTwoColumns
                                      ? fieldWidth
                                      : constraints.maxWidth,
                                  child: _LabeledField(
                                    label: l10n.platformFieldLabel,
                                    child: DropdownButtonFormField<BugPlatform>(
                                      key: ValueKey(_platform),
                                      isExpanded: true,
                                      initialValue: _platform,
                                      decoration: const InputDecoration(),
                                      items: [
                                        for (final platform
                                            in BugPlatform.values)
                                          DropdownMenuItem(
                                            value: platform,
                                            child: Text(
                                              l10n.localizedPlatformLabel(
                                                platform,
                                              ),
                                            ),
                                          ),
                                      ],
                                      onChanged: _isAnalyzing
                                          ? null
                                          : (platform) {
                                              setState(() {
                                                _platform = platform;
                                              });
                                            },
                                      validator: (value) => value == null
                                          ? l10n.platformRequiredValidation
                                          : null,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: useTwoColumns
                                      ? fieldWidth
                                      : constraints.maxWidth,
                                  child: _LabeledField(
                                    label: l10n.deviceFieldLabel,
                                    child: TextFormField(
                                      controller: _deviceController,
                                      enabled: !_isAnalyzing,
                                      decoration: InputDecoration(
                                        hintText: l10n.deviceFieldHint,
                                      ),
                                      textInputAction: TextInputAction.next,
                                      maxLength: 80,
                                      validator: (value) =>
                                          BugFormValidators.optionalMax(
                                            context,
                                            value,
                                          ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: useTwoColumns
                                      ? fieldWidth
                                      : constraints.maxWidth,
                                  child: _LabeledField(
                                    label: l10n.osVersionFieldLabel,
                                    child: TextFormField(
                                      controller: _osVersionController,
                                      enabled: !_isAnalyzing,
                                      decoration: InputDecoration(
                                        hintText: l10n.osVersionFieldHint,
                                      ),
                                      textInputAction: TextInputAction.next,
                                      maxLength: 80,
                                      validator: (value) =>
                                          BugFormValidators.optionalMax(
                                            context,
                                            value,
                                          ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: useTwoColumns
                                      ? fieldWidth
                                      : constraints.maxWidth,
                                  child: _LabeledField(
                                    label: l10n.appVersionFieldLabel,
                                    child: TextFormField(
                                      controller: _appVersionController,
                                      enabled: !_isAnalyzing,
                                      decoration: InputDecoration(
                                        hintText: l10n.appVersionFieldHint,
                                      ),
                                      textInputAction: TextInputAction.next,
                                      maxLength: 40,
                                      validator: (value) =>
                                          BugFormValidators.appVersion(
                                            context,
                                            value,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingXXLarge),
                    _FormSection(
                      title: 'screenshotSectionTitle'.tr(),
                      children: [
                        ScreenshotPicker(
                          screenshot: _screenshot,
                          enabled: !_isAnalyzing,
                          onChanged: (screenshot) {
                            setState(() {
                              _screenshot = screenshot;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingXXLarge),
                    _FormSection(
                      title: l10n.technicalDetailsSectionTitle,
                      children: [
                        _LabeledField(
                          label: l10n.logsFieldLabel,
                          child: BugPilotTechnicalBox(
                            child: TextFormField(
                              controller: _logsController,
                              enabled: !_isAnalyzing,
                              decoration: InputDecoration(
                                hintText: 'pasteLogsHint'.tr(),
                                filled: true,
                                fillColor: Colors.transparent,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: AppTheme.monoFontFamily,
                                fontSize: 13,
                                height: 1.45,
                              ),
                              minLines: 6,
                              maxLines: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingXLarge),
                    FilledButton.icon(
                      onPressed: _isAnalyzing ? null : _analyzeBugReport,
                      icon: _isAnalyzing
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(
                        _isAnalyzing
                            ? 'checkingAction'.tr()
                            : 'analyzeWithAiAction'.tr(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleInputChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handlePopInvoked(bool didPop, Object? result) async {
    if (didPop || _allowNextPop || !_hasUnsavedChanges || _isAnalyzing) {
      return;
    }

    final shouldDiscard = await _confirmDiscard();
    if (!mounted || !shouldDiscard) {
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      _resetForm();
      setState(() {
        _allowNextPop = true;
      });
      navigator.pop(result);
    } else {
      _resetForm();
      context.go(DashboardPage.routePath);
    }
  }

  Future<bool> _confirmDiscard() async {
    final l10n = context.l10n;

    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(l10n.discardReportTitle),
              content: Text(l10n.discardReportMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.keepEditingAction),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.discardAction),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _analyzeBugReport() async {
    FocusScope.of(context).unfocus();
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final platform = _platform;
    if (platform == null) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    final draft = _buildDraft(platform);
    final shouldContinue =
        widget.settingsController.settings.duplicateDetectionEnabled
        ? await _runDuplicateReview(draft)
        : true;
    if (!mounted) {
      return;
    }
    if (!shouldContinue) {
      setState(() {
        _isAnalyzing = false;
      });
      return;
    }

    final wasSaved = await _openAiAnalysis(draft);
    if (!mounted) {
      return;
    }

    setState(() {
      _isAnalyzing = false;
    });

    if (wasSaved) {
      context.go(BugReportsPage.routePath);
    }
  }

  BugReport _buildDraft(BugPlatform platform) {
    final now = DateTime.now();
    return BugReport(
      id: 'bug-${now.microsecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      expectedBehavior: _expectedBehaviorController.text.trim(),
      actualBehavior: _actualBehaviorController.text.trim(),
      platform: platform,
      device: _optionalValue(_deviceController),
      osVersion: _optionalValue(_osVersionController),
      appVersion: _optionalValue(_appVersionController),
      logs: _optionalValue(_logsController),
      severity: null,
      priority: null,
      status: BugStatus.open,
      reproductionSteps: const [],
      testCases: const [],
      possibleRootCause: null,
      rootCauseConfidence: null,
      screenshot: _screenshot,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<bool> _runDuplicateReview(BugReport draft) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final existingBugs = await widget.bugRepository.getBugs();
    final candidates = widget.localSimilarityService.findCandidates(
      draft: draft,
      existingBugs: existingBugs,
    );
    if (candidates.isEmpty) {
      return true;
    }

    DuplicateCheckResult result;
    try {
      result = await widget.duplicateDetectionService.checkDuplicates(
        draft: draft,
        candidates: candidates,
        languageCode: languageCode,
      );
    } on Object {
      if (!mounted) {
        return false;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('duplicateCheckUnavailable'.tr())));
      return true;
    }

    final matches = _buildSimilarBugMatches(candidates, result);
    if (matches.isEmpty) {
      return true;
    }

    while (mounted) {
      if (!mounted) {
        return false;
      }
      final action = await showModalBottomSheet<_SimilarBugAction>(
        context: context,
        useRootNavigator: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) =>
            _SimilarBugsSheet(matches: matches.take(3).toList(growable: false)),
      );

      if (action == null || action.type == _SimilarBugActionType.editReport) {
        return false;
      }
      if (action.type == _SimilarBugActionType.continueAnyway) {
        return true;
      }

      final bugId = action.bugId;
      if (bugId != null) {
        if (!mounted) {
          return false;
        }
        await context.push('/bugs/$bugId');
      }
    }

    return false;
  }

  Future<bool> _openAiAnalysis(BugReport draft) async {
    return await context.push<bool>(AiAnalysisPage.routePath, extra: draft) ??
        false;
  }

  List<_SimilarBugMatch> _buildSimilarBugMatches(
    List<SimilarBugCandidate> candidates,
    DuplicateCheckResult result,
  ) {
    final candidatesById = {
      for (final candidate in candidates) candidate.bug.id: candidate,
    };
    final matches = [
      for (final match in result.matches)
        if (match.similarity != DuplicateSimilarity.notDuplicate &&
            candidatesById.containsKey(match.bugId))
          _SimilarBugMatch(
            candidate: candidatesById[match.bugId]!,
            match: match,
          ),
    ];

    matches.sort((a, b) {
      final similarityComparison = _similarityRank(
        b.match.similarity,
      ).compareTo(_similarityRank(a.match.similarity));
      if (similarityComparison != 0) {
        return similarityComparison;
      }

      final confidenceComparison = b.match.confidence.compareTo(
        a.match.confidence,
      );
      if (confidenceComparison != 0) {
        return confidenceComparison;
      }

      return b.candidate.localScore.compareTo(a.candidate.localScore);
    });

    return matches;
  }

  void _resetForm() {
    _screenshot = null;
    _allowNextPop = false;
    _formKey.currentState?.reset();
    for (final controller in _controllers) {
      controller.clear();
    }
    _applyDefaultEnvironment();
  }

  void _handleExternalReset() {
    final resetValue = widget.resetSignal?.value;
    if (resetValue == null || resetValue == _lastResetValue) {
      return;
    }

    _lastResetValue = resetValue;
    if (!mounted) {
      return;
    }

    setState(_resetForm);
  }

  String? _optionalValue(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  void _applyDefaultEnvironment() {
    final settings = widget.settingsController.settings;
    _platform = settings.defaultPlatform;
    _deviceController.text = settings.defaultDevice ?? '';
    _osVersionController.text = settings.defaultOsVersion ?? '';
    _appVersionController.text = settings.defaultAppVersion ?? '';
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppDimensions.spacingLarge),
        BugPilotCard(
          radius: AppDimensions.radiusDashboardCard,
          padding: const EdgeInsets.all(20),
          shadow: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        child,
      ],
    );
  }
}

enum _SimilarBugActionType { viewBug, continueAnyway, editReport }

class _SimilarBugAction {
  const _SimilarBugAction._(this.type, [this.bugId]);

  const _SimilarBugAction.viewBug(String bugId)
    : this._(_SimilarBugActionType.viewBug, bugId);

  const _SimilarBugAction.continueAnyway()
    : this._(_SimilarBugActionType.continueAnyway);

  const _SimilarBugAction.editReport()
    : this._(_SimilarBugActionType.editReport);

  final _SimilarBugActionType type;
  final String? bugId;
}

class _SimilarBugMatch {
  const _SimilarBugMatch({required this.candidate, required this.match});

  final SimilarBugCandidate candidate;
  final DuplicateMatch match;
}

class _SimilarBugsSheet extends StatelessWidget {
  const _SimilarBugsSheet({required this.matches});

  final List<_SimilarBugMatch> matches;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimensions.pagePadding,
          0,
          AppDimensions.pagePadding,
          AppDimensions.pagePadding + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.amber.shade800.withAlpha(24),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMedium,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                AppDimensions.spacingSmall,
                              ),
                              child: Icon(
                                Icons.manage_search_rounded,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingMedium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'similarBugsFoundTitle'.tr(),
                                  style: textTheme.titleLarge,
                                ),
                                const SizedBox(
                                  height: AppDimensions.spacingXSmall,
                                ),
                                Text(
                                  'similarBugsFoundDescription'.tr(),
                                  style: textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingLarge),
                      for (var index = 0; index < matches.length; index++) ...[
                        _SimilarBugCard(match: matches[index]),
                        if (index != matches.length - 1)
                          const SizedBox(height: AppDimensions.spacingMedium),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLarge),
              FilledButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).pop(const _SimilarBugAction.continueAnyway()),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text('continueAnywayAction'.tr()),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSmall),
              TextButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).pop(const _SimilarBugAction.editReport()),
                icon: const Icon(Icons.edit_outlined),
                label: Text('editReportAction'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimilarBugCard extends StatelessWidget {
  const _SimilarBugCard({required this.match});

  final _SimilarBugMatch match;

  @override
  Widget build(BuildContext context) {
    final bug = match.candidate.bug;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.mutedSurfaceFor(context),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppDimensions.spacingSmall,
              runSpacing: AppDimensions.spacingSmall,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _SimilarityBadge(similarity: match.match.similarity),
                _ConfidenceLabel(confidence: match.match.confidence),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingSmall),
            Text(
              bug.title,
              style: textTheme.bodyLarge?.copyWith(
                color: AppTheme.textPrimaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSmall),
            Text(match.match.reason, style: textTheme.bodyMedium),
            const SizedBox(height: AppDimensions.spacingMedium),
            Wrap(
              spacing: AppDimensions.spacingSmall,
              runSpacing: AppDimensions.spacingSmall,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SeverityBadge(severity: bug.severity),
                PriorityBadge(priority: bug.priority),
                BugStatusChip(status: bug.status),
                BugMetadataItem(
                  icon: bugPlatformIcon(bug.platform),
                  label: context.l10n.localizedPlatformLabel(bug.platform),
                ),
                BugMetadataItem(
                  icon: Icons.calendar_today_outlined,
                  label: formatRecentDateLabel(
                    bug.createdAt,
                    localeCode: Localizations.localeOf(context).languageCode,
                    todayLabel: 'todayLabel'.tr(),
                    yesterdayLabel: 'yesterdayLabel'.tr(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).pop(_SimilarBugAction.viewBug(bug.id)),
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text('viewBugAction'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimilarityBadge extends StatelessWidget {
  const _SimilarityBadge({required this.similarity});

  final DuplicateSimilarity similarity;

  @override
  Widget build(BuildContext context) {
    final isLikelyDuplicate = similarity == DuplicateSimilarity.likelyDuplicate;
    final color = isLikelyDuplicate ? Colors.amber.shade900 : AppTheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSmall,
          vertical: AppDimensions.spacingXSmall,
        ),
        child: Text(
          isLikelyDuplicate
              ? 'possibleDuplicateLabel'.tr()
              : 'aiSimilarityLabel'.tr(),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ConfidenceLabel extends StatelessWidget {
  const _ConfidenceLabel({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final label = confidence >= 0.75
        ? 'highSimilarityLabel'.tr()
        : confidence >= 0.50
        ? 'moderateSimilarityLabel'.tr()
        : 'lowSimilarityLabel'.tr();

    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppTheme.textPrimaryFor(context),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

int _similarityRank(DuplicateSimilarity similarity) {
  return switch (similarity) {
    DuplicateSimilarity.likelyDuplicate => 3,
    DuplicateSimilarity.related => 2,
    DuplicateSimilarity.notDuplicate => 1,
  };
}
