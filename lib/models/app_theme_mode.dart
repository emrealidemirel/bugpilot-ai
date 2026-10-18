enum AppThemeMode { system, light, dark }

extension AppThemeModeSerialization on AppThemeMode {
  String get storageValue {
    return switch (this) {
      AppThemeMode.system => 'system',
      AppThemeMode.light => 'light',
      AppThemeMode.dark => 'dark',
    };
  }

  String get label {
    return switch (this) {
      AppThemeMode.system => 'System',
      AppThemeMode.light => 'Light',
      AppThemeMode.dark => 'Dark',
    };
  }
}

AppThemeMode appThemeModeFromStorage(String? value) {
  return switch (value) {
    'light' => AppThemeMode.light,
    'dark' => AppThemeMode.dark,
    'system' || null => AppThemeMode.system,
    _ => AppThemeMode.system,
  };
}
