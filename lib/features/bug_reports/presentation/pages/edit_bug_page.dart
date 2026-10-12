import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/localization_extensions.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/enums/bug_platform.dart';
import '../../domain/enums/bug_priority.dart';
import '../../domain/enums/bug_severity.dart';
import '../../domain/models/bug_report.dart';
import '../../domain/models/bug_screenshot.dart';
import '../../domain/repositories/bug_repository.dart';
import '../validation/bug_form_validators.dart';
import '../../../report_bug/presentation/widgets/screenshot_picker.dart';
import 'bug_reports_page.dart';

class EditBugPage extends StatefulWidget {
  const EditBugPage({
    required this.bugId,
    required this.bugRepository,
    required this.onBugChanged,
    super.key,
  });

  final String bugId;
  final BugRepository bugRepository;
  final VoidCallback onBugChanged;

  @override
  State<EditBugPage> createState() => _EditBugPageState();
}

class _EditBugPageState extends State<EditBugPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _expectedBehaviorController = TextEditingController();
  final _actualBehaviorController = TextEditingController();
  final _deviceController = TextEditingController();
  final _osVersionController = TextEditingController();
  final _appVersionController = TextEditingController();
  final _logsController = TextEditingController();

  late Future<BugReport?> _bugFuture;
  BugReport? _originalBug;
  BugPlatform? _platform;
  BugSeverity? _severity;
  BugPriority? _priority;
  BugScreenshot? _screenshot;
  bool _isSaving = false;
  bool _allowNextPop = false;

  @override
  void initState() {
    super.initState();
    _bugFuture = _loadBug();
    for (final controller in _controllers) {
      controller.addListener(_handleInputChanged);
    }
  }

  @override
  void dispose() {
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
    final bug = _originalBug;
    if (bug == null) {
      return false;
    }

    return _titleController.text.trim() != bug.title ||
        _descriptionController.text.trim() != bug.description ||
        _expectedBehaviorController.text.trim() != bug.expectedBehavior ||
        _actualBehaviorController.text.trim() != bug.actualBehavior ||
        _optionalValue(_deviceController) != bug.device ||
        _optionalValue(_osVersionController) != bug.osVersion ||
        _optionalValue(_appVersionController) != bug.appVersion ||
        _optionalValue(_logsController) != bug.logs ||
        _platform != bug.platform ||
        _severity != bug.severity ||
        _priority != bug.priority ||
        _screenshot != bug.screenshot;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowNextPop || !_hasUnsavedChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: SafeArea(
        child: FutureBuilder<BugReport?>(
          future: _bugFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const _EditLoadErrorState();
            }

            if (snapshot.data == null) {
              return const _EditNotFoundState();
            }

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppDimensions.pagePadding,
                  AppDimensions.pagePadding,
                  AppDimensions.pagePadding,
                  AppDimensions.pagePadding +
                      MediaQuery.viewInsetsOf(context).bottom,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Back',
                              onPressed: _isSaving ? null : _returnToDetail,
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const SizedBox(width: AppDimensions.spacingSmall),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit Bug',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(
                                    height: AppDimensions.spacingSmall,
                                  ),
                                  Text(
                                    'Update the report details and human review fields.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingXLarge),
                        _FormSection(
                          title: context.l10n.issueSectionTitle,
                          children: [
                            TextFormField(
                              controller: _titleController,
                              enabled: !_isSaving,
                              decoration: InputDecoration(
                                labelText: context.l10n.bugTitleFieldLabel,
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.next,
                              maxLength: 120,
                              validator: (value) =>
                                  BugFormValidators.title(context, value),
                            ),
                            const SizedBox(height: AppDimensions.spacingMedium),
                            TextFormField(
                              controller: _descriptionController,
                              enabled: !_isSaving,
                              decoration: InputDecoration(
                                labelText: context.l10n.descriptionFieldLabel,
                              ),
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.newline,
                              minLines: 4,
                              maxLines: 6,
                              validator: (value) =>
                                  BugFormValidators.description(context, value),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingLarge),
                        _FormSection(
                          title: context.l10n.behaviorSectionTitle,
                          children: [
                            TextFormField(
                              controller: _expectedBehaviorController,
                              enabled: !_isSaving,
                              decoration: InputDecoration(
                                labelText:
                                    context.l10n.expectedBehaviorFieldLabel,
                              ),
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.newline,
                              minLines: 3,
                              maxLines: 5,
                              validator: (value) =>
                                  BugFormValidators.requiredText(
                                    context,
                                    value,
                                  ),
                            ),
                            const SizedBox(height: AppDimensions.spacingMedium),
                            TextFormField(
                              controller: _actualBehaviorController,
                              enabled: !_isSaving,
                              decoration: InputDecoration(
                                labelText:
                                    context.l10n.actualBehaviorFieldLabel,
                              ),
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.newline,
                              minLines: 3,
                              maxLines: 5,
                              validator: (value) =>
                                  BugFormValidators.requiredText(
                                    context,
                                    value,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingLarge),
                        _FormSection(
                          title: context.l10n.environmentSectionTitle,
                          children: [
                            DropdownButtonFormField<BugPlatform>(
                              initialValue: _platform,
                              decoration: InputDecoration(
                                labelText: context.l10n.platformFieldLabel,
                              ),
                              items: [
                                for (final platform in BugPlatform.values)
                                  DropdownMenuItem(
                                    value: platform,
                                    child: Text(platform.label),
                                  ),
                              ],
                              onChanged: _isSaving
                                  ? null
                                  : (platform) {
                                      setState(() {
                                        _platform = platform;
                                      });
                                    },
                              validator: (value) => value == null
                                  ? context.l10n.platformRequiredValidation
                                  : null,
                            ),
                            const SizedBox(height: AppDimensions.spacingMedium),
                            TextFormField(
                              controller: _deviceController,
                              enabled: !_isSaving,
                              decoration: InputDecoration(
                                labelText: context.l10n.deviceFieldLabel,
                              ),
                              textInputAction: TextInputAction.next,
                              maxLength: 80,
                              validator: (value) =>
                                  BugFormValidators.optionalMax(context, value),
                            ),
                            const SizedBox(height: AppDimensions.spacingMedium),
                            TextFormField(
                              controller: _osVersionController,
                              enabled: !_isSaving,
                              decoration: InputDecoration(
                                labelText: context.l10n.osVersionFieldLabel,
                              ),
                              textInputAction: TextInputAction.next,
                              maxLength: 80,
                              validator: (value) =>
                                  BugFormValidators.optionalMax(context, value),
                            ),
                            const SizedBox(height: AppDimensions.spacingMedium),
                            TextFormField(
                              controller: _appVersionController,
                              enabled: !_isSaving,
                              decoration: InputDecoration(
                                labelText: context.l10n.appVersionFieldLabel,
                              ),
                              textInputAction: TextInputAction.next,
                              maxLength: 40,
                              validator: (value) =>
                                  BugFormValidators.appVersion(context, value),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingLarge),
                        _FormSection(
                          title: 'Screenshot',
                          children: [
                            ScreenshotPicker(
                              screenshot: _screenshot,
                              enabled: !_isSaving,
                              onChanged: (screenshot) {
                                setState(() {
                                  _screenshot = screenshot;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingLarge),
                        _FormSection(
                          title: 'Review',
                          children: [
                            DropdownButtonFormField<BugSeverity?>(
                              initialValue: _severity,
                              decoration: const InputDecoration(
                                labelText: 'Severity',
                              ),
                              items: [
                                const DropdownMenuItem<BugSeverity?>(
                                  value: null,
                                  child: Text('Unassigned'),
                                ),
                                for (final severity in BugSeverity.values)
                                  DropdownMenuItem<BugSeverity?>(
                                    value: severity,
                                    child: Text(severity.label),
                                  ),
                              ],
                              onChanged: _isSaving
                                  ? null
                                  : (severity) {
                                      setState(() {
                                        _severity = severity;
                                      });
                                    },
                            ),
                            const SizedBox(height: AppDimensions.spacingMedium),
                            DropdownButtonFormField<BugPriority?>(
                              initialValue: _priority,
                              decoration: const InputDecoration(
                                labelText: 'Priority',
                              ),
                              items: [
                                const DropdownMenuItem<BugPriority?>(
                                  value: null,
                                  child: Text('Unassigned'),
                                ),
                                for (final priority in BugPriority.values)
                                  DropdownMenuItem<BugPriority?>(
                                    value: priority,
                                    child: Text(priority.label),
                                  ),
                              ],
                              onChanged: _isSaving
                                  ? null
                                  : (priority) {
                                      setState(() {
                                        _priority = priority;
                                      });
                                    },
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingLarge),
                        _FormSection(
                          title: context.l10n.technicalDetailsSectionTitle,
                          children: [
                            TextFormField(
                              controller: _logsController,
                              enabled: !_isSaving,
                              decoration: InputDecoration(
                                labelText: context.l10n.logsFieldLabel,
                                alignLabelWithHint: true,
                              ),
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                height: 1.45,
                              ),
                              minLines: 6,
                              maxLines: 10,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingXLarge),
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _saveChanges,
                          icon: _isSaving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<BugReport?> _loadBug() async {
    final bug = await widget.bugRepository.getBugById(widget.bugId);
    if (bug != null) {
      _populateForm(bug);
    }

    return bug;
  }

  void _populateForm(BugReport bug) {
    _originalBug = bug;
    _titleController.text = bug.title;
    _descriptionController.text = bug.description;
    _expectedBehaviorController.text = bug.expectedBehavior;
    _actualBehaviorController.text = bug.actualBehavior;
    _deviceController.text = bug.device ?? '';
    _osVersionController.text = bug.osVersion ?? '';
    _appVersionController.text = bug.appVersion ?? '';
    _logsController.text = bug.logs ?? '';
    _platform = bug.platform;
    _severity = bug.severity;
    _priority = bug.priority;
    _screenshot = bug.screenshot;
  }

  void _handleInputChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handlePopInvoked(bool didPop, Object? result) async {
    if (didPop || _allowNextPop || !_hasUnsavedChanges || _isSaving) {
      return;
    }

    final shouldDiscard = await _confirmDiscard();
    if (!mounted || !shouldDiscard) {
      return;
    }

    _allowNextPop = true;
    _returnToDetail();
  }

  Future<bool> _confirmDiscard() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Discard changes?'),
              content: const Text('Your unsaved changes will be lost.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Keep Editing'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Discard'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();
    final formState = _formKey.currentState;
    final originalBug = _originalBug;
    if (formState == null || !formState.validate() || originalBug == null) {
      return;
    }

    final platform = _platform;
    if (platform == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedBug = originalBug.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      expectedBehavior: _expectedBehaviorController.text.trim(),
      actualBehavior: _actualBehaviorController.text.trim(),
      platform: platform,
      device: _optionalValue(_deviceController),
      osVersion: _optionalValue(_osVersionController),
      appVersion: _optionalValue(_appVersionController),
      logs: _optionalValue(_logsController),
      severity: _severity,
      priority: _priority,
      screenshot: _screenshot,
      updatedAt: DateTime.now(),
    );

    try {
      await widget.bugRepository.updateBug(updatedBug);
      if (!mounted) {
        return;
      }

      _originalBug = updatedBug;
      widget.onBugChanged();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bug report updated.')));
      context.go('/bugs/${updatedBug.id}');
    } on Object {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not update the bug report.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _returnToDetail() {
    context.go('/bugs/${widget.bugId}');
  }

  String? _optionalValue(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
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
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimaryFor(context),
            fontSize: 18,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        ...children,
      ],
    );
  }
}

class _EditNotFoundState extends StatelessWidget {
  const _EditNotFoundState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bug report not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            FilledButton(
              onPressed: () => context.go(BugReportsPage.routePath),
              child: const Text('Back to Bugs'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditLoadErrorState extends StatelessWidget {
  const _EditLoadErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Unable to load bug report.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}
