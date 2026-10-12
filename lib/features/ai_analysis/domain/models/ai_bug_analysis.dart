import '../../../bug_reports/domain/enums/bug_priority.dart';
import '../../../bug_reports/domain/enums/bug_severity.dart';
import '../../../bug_reports/domain/models/bug_test_case.dart';

const _unset = Object();

class AiBugAnalysis {
  AiBugAnalysis({
    required this.severity,
    required this.severityReason,
    required this.priority,
    required this.priorityReason,
    required List<String> reproductionSteps,
    required List<BugTestCase> testCases,
    required this.possibleRootCause,
    required this.rootCauseConfidence,
    required List<String> missingInformation,
    required this.qualityScore,
  }) : reproductionSteps = List.unmodifiable(reproductionSteps),
       testCases = List.unmodifiable(testCases),
       missingInformation = List.unmodifiable(missingInformation);

  factory AiBugAnalysis.fromJson(Map<String, dynamic> json) {
    final severity = json['severity'];
    final priority = json['priority'];
    return AiBugAnalysis(
      severity: severity == null
          ? null
          : bugSeverityFromJson(severity as String),
      severityReason: json['severityReason'] as String?,
      priority: priority == null
          ? null
          : bugPriorityFromJson(priority as String),
      priorityReason: json['priorityReason'] as String?,
      reproductionSteps:
          (json['reproductionSteps'] as List<dynamic>? ?? const [])
              .map((step) => step as String)
              .toList(),
      testCases: (json['testCases'] as List<dynamic>? ?? const [])
          .map(
            (testCase) =>
                BugTestCase.fromJson(testCase as Map<String, dynamic>),
          )
          .toList(),
      possibleRootCause: json['possibleRootCause'] as String?,
      rootCauseConfidence: (json['rootCauseConfidence'] as num?)?.toDouble(),
      missingInformation:
          (json['missingInformation'] as List<dynamic>? ?? const [])
              .map((item) => item as String)
              .toList(),
      qualityScore: (json['qualityScore'] as num).round(),
    );
  }

  final BugSeverity? severity;
  final String? severityReason;
  final BugPriority? priority;
  final String? priorityReason;
  final List<String> reproductionSteps;
  final List<BugTestCase> testCases;
  final String? possibleRootCause;
  final double? rootCauseConfidence;
  final List<String> missingInformation;
  final int qualityScore;

  AiBugAnalysis copyWith({
    Object? severity = _unset,
    Object? severityReason = _unset,
    Object? priority = _unset,
    Object? priorityReason = _unset,
    List<String>? reproductionSteps,
    List<BugTestCase>? testCases,
    Object? possibleRootCause = _unset,
    Object? rootCauseConfidence = _unset,
    List<String>? missingInformation,
    int? qualityScore,
  }) {
    return AiBugAnalysis(
      severity: identical(severity, _unset)
          ? this.severity
          : severity as BugSeverity?,
      severityReason: identical(severityReason, _unset)
          ? this.severityReason
          : severityReason as String?,
      priority: identical(priority, _unset)
          ? this.priority
          : priority as BugPriority?,
      priorityReason: identical(priorityReason, _unset)
          ? this.priorityReason
          : priorityReason as String?,
      reproductionSteps: reproductionSteps ?? this.reproductionSteps,
      testCases: testCases ?? this.testCases,
      possibleRootCause: identical(possibleRootCause, _unset)
          ? this.possibleRootCause
          : possibleRootCause as String?,
      rootCauseConfidence: identical(rootCauseConfidence, _unset)
          ? this.rootCauseConfidence
          : rootCauseConfidence as double?,
      missingInformation: missingInformation ?? this.missingInformation,
      qualityScore: qualityScore ?? this.qualityScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'severity': severity?.jsonValue,
      'severityReason': severityReason,
      'priority': priority?.jsonValue,
      'priorityReason': priorityReason,
      'reproductionSteps': reproductionSteps,
      'testCases': testCases.map((testCase) => testCase.toJson()).toList(),
      'possibleRootCause': possibleRootCause,
      'rootCauseConfidence': rootCauseConfidence,
      'missingInformation': missingInformation,
      'qualityScore': qualityScore,
    };
  }
}
