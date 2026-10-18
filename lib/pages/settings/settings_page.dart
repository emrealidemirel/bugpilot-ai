import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:bugpilot_ai/utils/localization_extensions.dart';
import 'package:bugpilot_ai/constants/app_dimensions.dart';
import 'package:bugpilot_ai/widgets/bugpilot_components.dart';
import 'package:bugpilot_ai/models/bug_platform.dart';
import 'package:bugpilot_ai/models/app_settings.dart';
import 'package:bugpilot_ai/models/app_theme_mode.dart';
import 'package:bugpilot_ai/controllers/settings_controller.dart';

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
    // The translation helper reads EasyLocalization's current locale without
    // registering a dependency, so listen here to rebuild every settings
    // section when the selected locale changes.
    Localizations.localeOf(context);

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
                    BugPilotAppHeader(),
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
          saved ? context.l10n.settingsSaved : context.l10n.settingsSaveError,
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
          title: Text(context.l10n.resetSettingsTitle),
          content: Text(context.l10n.resetSettingsDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.cancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.resetAction),
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
        content: Text(
          saved
              ? context.l10n.resetSettingsSuccess
              : context.l10n.settingsSaveError,
        ),
        backgroundColor: saved ? null : Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSaveError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.settingsSaveError),
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
      title: context.l10n.appearanceTitle,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.themeLabel,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppDimensions.spacingSmall),
              SegmentedButton<AppThemeMode>(
                segments: [
                  for (final mode in AppThemeMode.values)
                    ButtonSegment(
                      value: mode,
                      label: Text(context.l10n.localizedThemeLabel(mode)),
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
      title: context.l10n.aiPreferencesTitle,
      children: [
        _SettingsSwitchTile(
          title: context.l10n.severitySuggestion,
          subtitle: context.l10n.severitySuggestionDescription,
          value: settings.aiSeverityEnabled,
          onChanged: onSeverityChanged,
        ),
        _SettingsSwitchTile(
          title: context.l10n.prioritySuggestion,
          subtitle: context.l10n.prioritySuggestionDescription,
          value: settings.aiPriorityEnabled,
          onChanged: onPriorityChanged,
        ),
        _SettingsSwitchTile(
          title: context.l10n.generateTestCases,
          subtitle: context.l10n.generateTestCasesDescription,
          value: settings.aiTestCasesEnabled,
          onChanged: onTestCasesChanged,
        ),
        _SettingsSwitchTile(
          title: context.l10n.rootCauseHypothesis,
          subtitle: context.l10n.rootCauseHypothesisDescription,
          value: settings.aiRootCauseEnabled,
          onChanged: onRootCauseChanged,
        ),
        _SettingsSwitchTile(
          title: context.l10n.duplicateDetection,
          subtitle: context.l10n.duplicateDetectionDescription,
          value: settings.duplicateDetectionEnabled,
          onChanged: onDuplicateDetectionChanged,
        ),
        _SettingsSwitchTile(
          title: context.l10n.screenshotAnalysis,
          subtitle: settings.screenshotAnalysisEnabled
              ? context.l10n.screenshotAnalysisDescriptionOn
              : context.l10n.screenshotAnalysisDescriptionOff,
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
      title: context.l10n.defaultEnvironmentTitle,
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
                            BugPilotFieldLabel(
                              context.l10n.defaultPlatformLabel,
                            ),
                            DropdownButtonFormField<BugPlatform>(
                              initialValue: platform,
                              decoration: const InputDecoration(),
                              items: [
                                for (final value in BugPlatform.values)
                                  DropdownMenuItem(
                                    value: value,
                                    child: Text(
                                      context.l10n.localizedPlatformLabel(
                                        value,
                                      ),
                                    ),
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
                            BugPilotFieldLabel(context.l10n.defaultDeviceLabel),
                            TextField(
                              controller: deviceController,
                              decoration: InputDecoration(
                                hintText: context.l10n.deviceFieldHint,
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
                            BugPilotFieldLabel(
                              context.l10n.defaultOsVersionLabel,
                            ),
                            TextField(
                              controller: osVersionController,
                              decoration: InputDecoration(
                                hintText: context.l10n.osVersionFieldHint,
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
                            BugPilotFieldLabel(
                              context.l10n.defaultAppVersionLabel,
                            ),
                            TextField(
                              controller: appVersionController,
                              decoration: InputDecoration(
                                hintText: context.l10n.appVersionFieldHint,
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
                      label: Text(context.l10n.saveDefaultsAction),
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
      title: context.l10n.privacyAiTitle,
      children: [
        _PrivacyInfoRow(
          icon: Icons.shield_outlined,
          title: context.l10n.aiDataUseTitle,
          description: context.l10n.aiDataUseDescription,
        ),
        _PrivacyInfoRow(
          icon: Icons.image_outlined,
          title: context.l10n.screenshotAnalysis,
          description: screenshotAnalysisEnabled
              ? context.l10n.screenshotAnalysisDescriptionOn
              : context.l10n.screenshotAnalysisDescriptionOff,
        ),
        _PrivacyInfoRow(
          icon: Icons.article_outlined,
          title: context.l10n.reviewLogsTitle,
          description: context.l10n.reviewLogsDescription,
        ),
      ],
    );
  }
}

class _PrivacyInfoRow extends StatelessWidget {
  const _PrivacyInfoRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) {
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
                selected: {context.locale},
                onSelectionChanged: (selection) {
                  context.setLocale(selection.first);
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
      title: context.l10n.aboutTitle,
      children: [
        ListTile(
          leading: Icon(Icons.bug_report_outlined),
          title: Text('BugPilot AI'),
          subtitle: Text(context.l10n.aboutDescription),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(context.l10n.openSourceLicenses),
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
            context.l10n.settingsResetLabel,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          onTap: onReset,
        ),
      ],
    );
  }
}
