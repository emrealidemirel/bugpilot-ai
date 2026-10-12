enum BugPlatform { android, ios, web, other }

extension BugPlatformPresentation on BugPlatform {
  String get label {
    return switch (this) {
      BugPlatform.android => 'Android',
      BugPlatform.ios => 'iOS',
      BugPlatform.web => 'Web',
      BugPlatform.other => 'Other',
    };
  }

  String get jsonValue {
    return switch (this) {
      BugPlatform.android => 'android',
      BugPlatform.ios => 'ios',
      BugPlatform.web => 'web',
      BugPlatform.other => 'other',
    };
  }
}

BugPlatform bugPlatformFromJson(String value) {
  return switch (value) {
    'android' => BugPlatform.android,
    'ios' => BugPlatform.ios,
    'web' => BugPlatform.web,
    'other' => BugPlatform.other,
    _ => throw ArgumentError.value(value, 'value', 'Unknown bug platform'),
  };
}
