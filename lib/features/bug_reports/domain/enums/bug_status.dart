enum BugStatus { open, inProgress, resolved, closed }

extension BugStatusPresentation on BugStatus {
  String get label {
    return switch (this) {
      BugStatus.open => 'Open',
      BugStatus.inProgress => 'In Progress',
      BugStatus.resolved => 'Resolved',
      BugStatus.closed => 'Closed',
    };
  }

  String get jsonValue {
    return switch (this) {
      BugStatus.open => 'open',
      BugStatus.inProgress => 'inProgress',
      BugStatus.resolved => 'resolved',
      BugStatus.closed => 'closed',
    };
  }
}

BugStatus bugStatusFromJson(String value) {
  return switch (value) {
    'open' => BugStatus.open,
    'inProgress' => BugStatus.inProgress,
    'resolved' => BugStatus.resolved,
    'closed' => BugStatus.closed,
    _ => throw ArgumentError.value(value, 'value', 'Unknown bug status'),
  };
}
