enum BugPriority { p0, p1, p2, p3 }

extension BugPriorityPresentation on BugPriority {
  String get label {
    return switch (this) {
      BugPriority.p0 => 'P0',
      BugPriority.p1 => 'P1',
      BugPriority.p2 => 'P2',
      BugPriority.p3 => 'P3',
    };
  }

  String get description {
    return switch (this) {
      BugPriority.p0 => 'Immediate',
      BugPriority.p1 => 'High priority',
      BugPriority.p2 => 'Normal priority',
      BugPriority.p3 => 'Low priority',
    };
  }

  String get jsonValue {
    return switch (this) {
      BugPriority.p0 => 'p0',
      BugPriority.p1 => 'p1',
      BugPriority.p2 => 'p2',
      BugPriority.p3 => 'p3',
    };
  }
}

BugPriority bugPriorityFromJson(String value) {
  return switch (value) {
    'p0' => BugPriority.p0,
    'p1' => BugPriority.p1,
    'p2' => BugPriority.p2,
    'p3' => BugPriority.p3,
    _ => throw ArgumentError.value(value, 'value', 'Unknown bug priority'),
  };
}
