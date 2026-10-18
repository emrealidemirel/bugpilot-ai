import 'package:flutter/foundation.dart';

import 'package:bugpilot_ai/models/app_settings.dart';
import 'package:bugpilot_ai/models/app_theme_mode.dart';
import 'package:bugpilot_ai/repositories/settings_repository.dart';
import 'package:bugpilot_ai/models/bug_platform.dart';

class SettingsController extends ChangeNotifier {
  factory SettingsController({
    required SettingsRepository repository,
    AppSettings initialSettings = AppSettings.defaults,
  }) {
    return SettingsController._(repository, initialSettings);
  }

  SettingsController._(this._repository, this._settings);

  final SettingsRepository _repository;
  AppSettings _settings;

  AppSettings get settings => _settings;

  Future<bool> setThemeMode(AppThemeMode themeMode) {
    return _persist(_settings.copyWith(themeMode: themeMode));
  }

  Future<bool> setAiSeverityEnabled(bool enabled) {
    return _persist(_settings.copyWith(aiSeverityEnabled: enabled));
  }

  Future<bool> setAiPriorityEnabled(bool enabled) {
    return _persist(_settings.copyWith(aiPriorityEnabled: enabled));
  }

  Future<bool> setAiTestCasesEnabled(bool enabled) {
    return _persist(_settings.copyWith(aiTestCasesEnabled: enabled));
  }

  Future<bool> setAiRootCauseEnabled(bool enabled) {
    return _persist(_settings.copyWith(aiRootCauseEnabled: enabled));
  }

  Future<bool> setDuplicateDetectionEnabled(bool enabled) {
    return _persist(_settings.copyWith(duplicateDetectionEnabled: enabled));
  }

  Future<bool> setScreenshotAnalysisEnabled(bool enabled) {
    return _persist(_settings.copyWith(screenshotAnalysisEnabled: enabled));
  }

  Future<bool> setDefaultEnvironment({
    required BugPlatform platform,
    String? device,
    String? osVersion,
    String? appVersion,
  }) {
    return _persist(
      _settings.copyWith(
        defaultPlatform: platform,
        defaultDevice: device,
        defaultOsVersion: osVersion,
        defaultAppVersion: appVersion,
      ),
    );
  }

  Future<bool> reset() async {
    return _persist(AppSettings.defaults);
  }

  Future<bool> _persist(AppSettings next) async {
    if (next == _settings) {
      return true;
    }

    final previous = _settings;
    _settings = next;
    notifyListeners();

    try {
      await _repository.save(next);
      return true;
    } on Object {
      _settings = previous;
      notifyListeners();
      return false;
    }
  }
}
