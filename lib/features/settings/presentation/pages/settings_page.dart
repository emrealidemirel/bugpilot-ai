import 'package:flutter/material.dart';

import '../../../../app/localization/locale_controller_scope.dart';
import '../../../../app/localization/localization_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/bugpilot_components.dart';
import '../../../bug_reports/domain/enums/bug_platform.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/app_theme_mode.dart';
import '../controllers/settings_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({required this.controller, super.key});

  static const routePath = '/settings';

  final SettingsController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _deviceController;
  late final TextEditingController _osVersionController;
  late final TextEditingController _appVersionController;
  late BugPlatform _defaultPlatform;

  @override
  void initState() {
    super.initState();
    final settings = widget.controller.settings;
    _defaultPlatform = settings.defaultPlatform;
    _deviceController = TextEditingController(text: settings.defaultDevice);
    _osVersionController = TextEditingController(
      text: settings.defaultOsVersion,
    );
    _appVersionController = TextEditingController(
      text: settings.defaultAppVersion,
    );
  }

  @override
  void dispose() {
    _deviceController.dispose();
    _osVersionController.dispose();
    _appVersionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, child) {
          final settings = widget.controller.settings;
          return SingleChildScrollView(
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
                    BugPilotAppHeader(
                      title: l10n.settingsTitle,
                      subtitle: l10n.settingsDescription,
                    ),
                    _AppearanceSection(
                      themeMode: settings.themeMode,
                      onThemeModeChanged: _setThemeMode,
                    ),
                    const SizedBox(height: AppDimensions.spacingLarge),
                    _AiPreferencesSection(
                      settings: settings,
                      onSeverityChanged: _saveToggle(
                        widget.controller.setAiSeverityEnabled,
                      ),
                      onPriorityChanged: _saveToggle(
                        widget.controller.setAiPriorityEnabled,
                      ),
                      onTestCasesChanged: _saveToggle(
                        widget.controller.setAiTestCasesEnabled,
                      ),
                      onRootCauseChanged: _saveToggle(
                        widget.controller.setAiRootCauseEnabled,
                      ),
                      onDuplicateDetectionChanged: _saveToggle(
                        widget.controller.setDuplicateDetectionEnabled,
                      ),
                      onScreenshotAnalysisChanged: _saveToggle(
                        widget.controller.setScreenshotAnalysisEnabled,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingLarge),
                    _DefaultEnvironmentSection(
                      platform: _defaultPlatform,
                      deviceController: _deviceController,
                      osVersionController: _osVersionController,
                      appVersionController: _appVersionController,
                      onPlatformChanged: (platform) {
                        setState(() {
                          _defaultPlatform = platform;
                        });
                      },
                      onSave: _saveDefaultEnvironment,
                    ),
                    const SizedBox(height: AppDimensions.spacingLarge),
                    _PrivacySection(
                      screenshotAnalysisEnabled:
                          settings.screenshotAnalysisEnabled,
                    ),
                    const SizedBox(height: AppDimensions.spacingLarge),
                    const _LanguageSection(),
                    const SizedBox(height: AppDimensions.spacingLarge),
                    _AboutSection(onReset: _confirmResetSettings),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  ValueChanged<bool> _saveToggle(Future<bool> Function(bool value) save) {
    return (value) async {
      final saved = await save(value);
      if (!mounted || saved) {
        return;
      }
      _showSaveError();
    };
  }

  Future<void> _setThemeMode(AppThemeMode mode) async {
    final saved = await widget.controller.setThemeMode(mode);
    if (!mounted || saved) {
      return;
    }
    _showSaveError();
  }

  Future<void> _saveDefaultEnvironment() async {
    FocusScope.of(context).unfocus();
    final saved = await widget.controller.setDefaultEnvironment(
      platform: _defaultPlatform,
      device: _deviceController.text,
      osVersion: _osVersionController.text,
      appVersion: _appVersionController.text,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? 'Default environment saved.' : 'Could not save settings.',
        ),
        backgroundColor: saved ? null : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _confirmResetSettings() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset settings?'),
          content: const Text(
            'Your preferences and default environment values will return to their defaults.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
    if (shouldReset != true) {
      return;
    }

    final saved = await widget.controller.reset();
    if (!mounted) {
      return;
    }
    if (saved) {
      final settings = widget.controller.settings;
      setState(() {
        _defaultPlatform = settings.defaultPlatform;
        _deviceController.text = settings.defaultDevice ?? '';
        _osVersionController.text = settings.defaultOsVersion ?? '';
        _appVersionController.text = settings.defaultAppVersion ?? '';
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? 'Settings reset.' : 'Could not save settings.'),
        backgroundColor: saved ? null : Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSaveError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Could not save settings.'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppDimensions.spacingSmall),
        BugPilotCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection({
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final AppThemeMode themeMode;
  final ValueChanged<AppThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Appearance',
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Theme', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: AppDimensions.spacingSmall),
              SegmentedButton<AppThemeMode>(
                segments: [
                  for (final mode in AppThemeMode.values)
                    ButtonSegment(
                      value: mode,
                      label: Text(mode.label),
                      icon: Icon(_themeIcon(mode)),
                    ),
                ],
                selected: {themeMode},
                onSelectionChanged: (selection) {
                  onThemeModeChanged(selection.single);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _themeIcon(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.system => Icons.brightness_auto_rounded,
      AppThemeMode.light => Icons.light_mode_outlined,
      AppThemeMode.dark => Icons.dark_mode_outlined,
    };
  }
}

class _AiPreferencesSection extends StatelessWidget {
  const _AiPreferencesSection({
    required this.settings,
    required this.onSeverityChanged,
    required this.onPriorityChanged,
    required this.onTestCasesChanged,
    required this.onRootCauseChanged,
    required this.onDuplicateDetectionChanged,
    required this.onScreenshotAnalysisChanged,
  });

  final AppSettings settings;
  final ValueChanged<bool> onSeverityChanged;
  final ValueChanged<bool> onPriorityChanged;
  final ValueChanged<bool> onTestCasesChanged;
  final ValueChanged<bool> onRootCauseChanged;
  final ValueChanged<bool> onDuplicateDetectionChanged;
  final ValueChanged<bool> onScreenshotAnalysisChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'AI Preferences',
      children: [
        _SettingsSwitchTile(
          title: 'Severity Suggestion',
          subtitle: 'Let AI recommend bug severity.',
          value: settings.aiSeverityEnabled,
          onChanged: onSeverityChanged,
        ),
        _SettingsSwitchTile(
          title: 'Priority Suggestion',
          subtitle: 'Let AI recommend bug priority.',
          value: settings.aiPriorityEnabled,
          onChanged: onPriorityChanged,
        ),
        _SettingsSwitchTile(
          title: 'Generate Test Cases',
          subtitle: 'Generate QA test cases during analysis.',
          value: settings.aiTestCasesEnabled,
          onChanged: onTestCasesChanged,
        ),
        _SettingsSwitchTile(
          title: 'Root Cause Hypothesis',
          subtitle: 'Generate a possible root-cause hypothesis.',
          value: settings.aiRootCauseEnabled,
          onChanged: onRootCauseChanged,
        ),
        _SettingsSwitchTile(
          title: 'Duplicate Detection',
          subtitle: 'Check existing bug reports for similar issues.',
          value: settings.duplicateDetectionEnabled,
          onChanged: onDuplicateDetectionChanged,
        ),
        _SettingsSwitchTile(
          title: 'Screenshot Analysis',
          subtitle: settings.screenshotAnalysisEnabled
              ? 'Attached screenshots may be sent for AI analysis.'
              : 'Screenshots stay local and are not included in AI analysis.',
          value: settings.screenshotAnalysisEnabled,
          onChanged: onScreenshotAnalysisChanged,
        ),
      ],
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(18),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingSmall),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppDimensions.spacingXSmall),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSmall),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _DefaultEnvironmentSection extends StatelessWidget {
  const _DefaultEnvironmentSection({
    required this.platform,
    required this.deviceController,
    required this.osVersionController,
    required this.appVersionController,
    required this.onPlatformChanged,
    required this.onSave,
  });

  final BugPlatform platform;
  final TextEditingController deviceController;
  final TextEditingController osVersionController;
  final TextEditingController appVersionController;
  final ValueChanged<BugPlatform> onPlatformChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Default Environment',
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMedium),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useTwoColumns = constraints.maxWidth >= 360;
              final fieldWidth =
                  (constraints.maxWidth - AppDimensions.spacingMedium) / 2;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: AppDimensions.spacingMedium,
                    runSpacing: AppDimensions.spacingMedium,
                    children: [
                      SizedBox(
                        width: useTwoColumns
                            ? fieldWidth
                            : constraints.maxWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const BugPilotFieldLabel('Default Platform'),
                            DropdownButtonFormField<BugPlatform>(
                              initialValue: platform,
                              decoration: const InputDecoration(),
                              items: [
                                for (final value in BugPlatform.values)
                                  DropdownMenuItem(
                                    value: value,
                                    child: Text(value.label),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  onPlatformChanged(value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: useTwoColumns
                            ? fieldWidth
                            : constraints.maxWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const BugPilotFieldLabel('Default Device'),
                            TextField(
                              controller: deviceController,
                              decoration: const InputDecoration(
                                hintText: 'Pixel 9',
                              ),
                              maxLength: 80,
                              textInputAction: TextInputAction.next,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: useTwoColumns
                            ? fieldWidth
                            : constraints.maxWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const BugPilotFieldLabel('Default OS Version'),
                            TextField(
                              controller: osVersionController,
                              decoration: const InputDecoration(
                                hintText: 'Android 16',
                              ),
                              maxLength: 80,
                              textInputAction: TextInputAction.next,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: useTwoColumns
                            ? fieldWidth
                            : constraints.maxWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const BugPilotFieldLabel('Default App Version'),
                            TextField(
                              controller: appVersionController,
                              decoration: const InputDecoration(
                                hintText: '1.0.0',
                              ),
                              maxLength: 40,
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: onSave,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Defaults'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({required this.screenshotAnalysisEnabled});

  final bool screenshotAnalysisEnabled;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Privacy & AI',
      children: [
        const ListTile(
          leading: Icon(Icons.shield_outlined),
          title: Text('AI Data Use'),
          subtitle: Text(
            'Bug details and optional screenshots are sent to the configured AI backend only when analysis is requested.',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.image_outlined),
          title: const Text('Screenshot analysis'),
          subtitle: Text(
            screenshotAnalysisEnabled
                ? 'Attached screenshots may be sent for AI analysis.'
                : 'Screenshots stay local and are not included in AI analysis.',
          ),
        ),
        const ListTile(
          leading: Icon(Icons.article_outlined),
          title: Text('Review logs before analysis'),
          subtitle: Text(
            'Logs may contain tokens, credentials, or sensitive application data.',
          ),
        ),
      ],
    );
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) {
    final controller = LocaleControllerScope.of(context);
    final l10n = context.l10n;

    return _SettingsSection(
      title: l10n.languageSectionTitle,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.languageSectionDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              SegmentedButton<Locale>(
                segments: [
                  ButtonSegment(
                    value: const Locale('en'),
                    label: Text(l10n.englishLanguage),
                    icon: const Icon(Icons.language_rounded),
                  ),
                  ButtonSegment(
                    value: const Locale('tr'),
                    label: Text(l10n.turkishLanguage),
                    icon: const Icon(Icons.translate_rounded),
                  ),
                ],
                selected: {controller.locale},
                onSelectionChanged: (selection) {
                  controller.setLocale(selection.first);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'About',
      children: [
        const ListTile(
          leading: Icon(Icons.bug_report_outlined),
          title: Text('BugPilot AI'),
          subtitle: Text('AI-powered bug reporting and QA assistant.'),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Open-source licenses'),
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: 'BugPilot AI',
              applicationVersion: '1.0.0',
            );
          },
        ),
        ListTile(
          leading: Icon(
            Icons.restart_alt_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(
            'Reset Settings',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          onTap: onReset,
        ),
      ],
    );
  }
}
