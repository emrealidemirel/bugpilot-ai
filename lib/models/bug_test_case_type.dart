enum BugTestCaseType { positive, negative, edgeCase }

extension BugTestCaseTypePresentation on BugTestCaseType {
  String get label {
    return switch (this) {
      BugTestCaseType.positive => 'Positive',
      BugTestCaseType.negative => 'Negative',
      BugTestCaseType.edgeCase => 'Edge Case',
    };
  }

  String get jsonValue {
    return switch (this) {
      BugTestCaseType.positive => 'positive',
      BugTestCaseType.negative => 'negative',
      BugTestCaseType.edgeCase => 'edgeCase',
    };
  }
}

BugTestCaseType bugTestCaseTypeFromJson(String value) {
  return switch (value) {
    'positive' => BugTestCaseType.positive,
    'negative' => BugTestCaseType.negative,
    'edgeCase' => BugTestCaseType.edgeCase,
    _ => throw ArgumentError.value(value, 'value', 'Unknown test case type'),
  };
}
