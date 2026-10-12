enum BugSeverity { critical, high, medium, low }

extension BugSeverityPresentation on BugSeverity {
  String get label {
    return switch (this) {
      BugSeverity.critical => 'Critical',
      BugSeverity.high => 'High',
      BugSeverity.medium => 'Medium',
      BugSeverity.low => 'Low',
    };
  }

  String get jsonValue {
    return switch (this) {
      BugSeverity.critical => 'critical',
      BugSeverity.high => 'high',
      BugSeverity.medium => 'medium',
      BugSeverity.low => 'low',
    };
  }
}

BugSeverity bugSeverityFromJson(String value) {
  return switch (value) {
    'critical' => BugSeverity.critical,
    'high' => BugSeverity.high,
    'medium' => BugSeverity.medium,
    'low' => BugSeverity.low,
    _ => throw ArgumentError.value(value, 'value', 'Unknown bug severity'),
  };
}
