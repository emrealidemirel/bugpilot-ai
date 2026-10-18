import 'package:bugpilot_ai/models/bug_platform.dart';
import 'app_theme_mode.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.aiSeverityEnabled = true,
    this.aiPriorityEnabled = true,
    this.aiTestCasesEnabled = true,
    this.aiRootCauseEnabled = true,
    this.duplicateDetectionEnabled = true,
    this.screenshotAnalysisEnabled = true,
    this.defaultPlatform = BugPlatform.android,
    this.defaultDevice,
    this.defaultOsVersion,
    this.defaultAppVersion,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final defaults = AppSettings.defaults;
    return AppSettings(
      themeMode: appThemeModeFromStorage(json['themeMode'] as String?),
      aiSeverityEnabled:
          json['aiSeverityEnabled'] as bool? ?? defaults.aiSeverityEnabled,
      aiPriorityEnabled:
          json['aiPriorityEnabled'] as bool? ?? defaults.aiPriorityEnabled,
      aiTestCasesEnabled:
          json['aiTestCasesEnabled'] as bool? ?? defaults.aiTestCasesEnabled,
      aiRootCauseEnabled:
          json['aiRootCauseEnabled'] as bool? ?? defaults.aiRootCauseEnabled,
      duplicateDetectionEnabled:
          json['duplicateDetectionEnabled'] as bool? ??
          defaults.duplicateDetectionEnabled,
      screenshotAnalysisEnabled:
          json['screenshotAnalysisEnabled'] as bool? ??
          defaults.screenshotAnalysisEnabled,
      defaultPlatform: _platformFromJson(json['defaultPlatform']),
      defaultDevice: _optionalText(json['defaultDevice']),
      defaultOsVersion: _optionalText(json['defaultOsVersion']),
      defaultAppVersion: _optionalText(json['defaultAppVersion']),
    );
  }

  static const defaults = AppSettings();

  final AppThemeMode themeMode;
  final bool aiSeverityEnabled;
  final bool aiPriorityEnabled;
  final bool aiTestCasesEnabled;
  final bool aiRootCauseEnabled;
  final bool duplicateDetectionEnabled;
  final bool screenshotAnalysisEnabled;
  final BugPlatform defaultPlatform;
  final String? defaultDevice;
  final String? defaultOsVersion;
  final String? defaultAppVersion;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? aiSeverityEnabled,
    bool? aiPriorityEnabled,
    bool? aiTestCasesEnabled,
    bool? aiRootCauseEnabled,
    bool? duplicateDetectionEnabled,
    bool? screenshotAnalysisEnabled,
    BugPlatform? defaultPlatform,
    Object? defaultDevice = _unset,
    Object? defaultOsVersion = _unset,
    Object? defaultAppVersion = _unset,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      aiSeverityEnabled: aiSeverityEnabled ?? this.aiSeverityEnabled,
      aiPriorityEnabled: aiPriorityEnabled ?? this.aiPriorityEnabled,
      aiTestCasesEnabled: aiTestCasesEnabled ?? this.aiTestCasesEnabled,
      aiRootCauseEnabled: aiRootCauseEnabled ?? this.aiRootCauseEnabled,
      duplicateDetectionEnabled:
          duplicateDetectionEnabled ?? this.duplicateDetectionEnabled,
      screenshotAnalysisEnabled:
          screenshotAnalysisEnabled ?? this.screenshotAnalysisEnabled,
      defaultPlatform: defaultPlatform ?? this.defaultPlatform,
      defaultDevice: identical(defaultDevice, _unset)
          ? this.defaultDevice
          : _optionalText(defaultDevice),
      defaultOsVersion: identical(defaultOsVersion, _unset)
          ? this.defaultOsVersion
          : _optionalText(defaultOsVersion),
      defaultAppVersion: identical(defaultAppVersion, _unset)
          ? this.defaultAppVersion
          : _optionalText(defaultAppVersion),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.storageValue,
      'aiSeverityEnabled': aiSeverityEnabled,
      'aiPriorityEnabled': aiPriorityEnabled,
      'aiTestCasesEnabled': aiTestCasesEnabled,
      'aiRootCauseEnabled': aiRootCauseEnabled,
      'duplicateDetectionEnabled': duplicateDetectionEnabled,
      'screenshotAnalysisEnabled': screenshotAnalysisEnabled,
      'defaultPlatform': defaultPlatform.jsonValue,
      'defaultDevice': defaultDevice,
      'defaultOsVersion': defaultOsVersion,
      'defaultAppVersion': defaultAppVersion,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppSettings &&
            runtimeType == other.runtimeType &&
            themeMode == other.themeMode &&
            aiSeverityEnabled == other.aiSeverityEnabled &&
            aiPriorityEnabled == other.aiPriorityEnabled &&
            aiTestCasesEnabled == other.aiTestCasesEnabled &&
            aiRootCauseEnabled == other.aiRootCauseEnabled &&
            duplicateDetectionEnabled == other.duplicateDetectionEnabled &&
            screenshotAnalysisEnabled == other.screenshotAnalysisEnabled &&
            defaultPlatform == other.defaultPlatform &&
            defaultDevice == other.defaultDevice &&
            defaultOsVersion == other.defaultOsVersion &&
            defaultAppVersion == other.defaultAppVersion;
  }

  @override
  int get hashCode {
    return Object.hash(
      themeMode,
      aiSeverityEnabled,
      aiPriorityEnabled,
      aiTestCasesEnabled,
      aiRootCauseEnabled,
      duplicateDetectionEnabled,
      screenshotAnalysisEnabled,
      defaultPlatform,
      defaultDevice,
      defaultOsVersion,
      defaultAppVersion,
    );
  }
}

const _unset = Object();

String? _optionalText(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

BugPlatform _platformFromJson(Object? value) {
  if (value is! String) {
    return AppSettings.defaults.defaultPlatform;
  }

  try {
    return bugPlatformFromJson(value);
  } on ArgumentError {
    return AppSettings.defaults.defaultPlatform;
  }
}
