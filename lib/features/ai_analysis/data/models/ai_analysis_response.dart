import '../../../bug_reports/domain/enums/bug_priority.dart';
import '../../../bug_reports/domain/enums/bug_severity.dart';
import '../../../bug_reports/domain/enums/bug_test_case_type.dart';
import '../../../bug_reports/domain/models/bug_test_case.dart';
import '../../domain/models/ai_bug_analysis.dart';

class AiAnalysisResponse {
  AiAnalysisResponse({required this.analysis, this.meta});

  factory AiAnalysisResponse.fromJson(Map<String, dynamic> json) {
    final analysisJson = json['analysis'];
    if (analysisJson is! Map<String, dynamic>) {
      throw const FormatException('AI analysis response is missing analysis.');
    }

    final metaJson = json['meta'];

    return AiAnalysisResponse(
      analysis: AiAnalysisPayloadResponse.fromJson(analysisJson),
      meta: metaJson is Map<String, dynamic>
          ? AiAnalysisMetaResponse.fromJson(metaJson)
          : null,
    );
  }

  final AiAnalysisPayloadResponse analysis;
  final AiAnalysisMetaResponse? meta;

  AiBugAnalysis toDomain() {
    return analysis.toDomain();
  }

  Map<String, dynamic> toJson() {
    return {
      'analysis': analysis.toJson(),
      if (meta != null) 'meta': meta!.toJson(),
    };
  }
}

class AiAnalysisPayloadResponse {
  AiAnalysisPayloadResponse({
    required this.severity,
    required this.severityReason,
    required this.priority,
    required this.priorityReason,
    required List<String> reproductionSteps,
    required List<AiTestCaseResponse> testCases,
    required this.possibleRootCause,
    required this.rootCauseConfidence,
    required List<String> missingInformation,
    required this.qualityScore,
  }) : reproductionSteps = List.unmodifiable(reproductionSteps),
       testCases = List.unmodifiable(testCases),
       missingInformation = List.unmodifiable(missingInformation) {
    final severityReason = this.severityReason;
    final priorityReason = this.priorityReason;
    final possibleRootCause = this.possibleRootCause;
    final rootCauseConfidence = this.rootCauseConfidence;
    if (severity != null) {
      _validateNonEmpty('severityReason', severityReason);
    }
    if (priority != null) {
      _validateNonEmpty('priorityReason', priorityReason);
    }
    if (possibleRootCause != null) {
      _validateNonEmpty('possibleRootCause', possibleRootCause);
    }
    if (this.reproductionSteps.isEmpty) {
      throw const FormatException(
        'AI analysis must include reproduction steps.',
      );
    }
    if (rootCauseConfidence != null &&
        (rootCauseConfidence < 0 || rootCauseConfidence > 1)) {
      throw const FormatException(
        'rootCauseConfidence must be between 0.0 and 1.0.',
      );
    }
    if (qualityScore < 0 || qualityScore > 100) {
      throw const FormatException('qualityScore must be between 0 and 100.');
    }
  }

  factory AiAnalysisPayloadResponse.fromJson(Map<String, dynamic> json) {
    final reproductionSteps = _requiredStringList(json, 'reproductionSteps');
    final testCasesJson = json['testCases'];
    if (testCasesJson is! List) {
      throw const FormatException('testCases must be a list.');
    }
    final severity = json['severity'];
    final priority = json['priority'];

    return AiAnalysisPayloadResponse(
      severity: severity == null
          ? null
          : bugSeverityFromJson(_requiredString(json, 'severity')),
      severityReason: _nullableString(json, 'severityReason'),
      priority: priority == null
          ? null
          : bugPriorityFromJson(_requiredString(json, 'priority')),
      priorityReason: _nullableString(json, 'priorityReason'),
      reproductionSteps: reproductionSteps,
      testCases: testCasesJson.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid AI test case item.');
        }
        return AiTestCaseResponse.fromJson(item);
      }).toList(),
      possibleRootCause: _nullableString(json, 'possibleRootCause'),
      rootCauseConfidence: _nullableDouble(json, 'rootCauseConfidence'),
      missingInformation: _optionalStringList(json, 'missingInformation'),
      qualityScore: _requiredInt(json, 'qualityScore'),
    );
  }

  final BugSeverity? severity;
  final String? severityReason;
  final BugPriority? priority;
  final String? priorityReason;
  final List<String> reproductionSteps;
  final List<AiTestCaseResponse> testCases;
  final String? possibleRootCause;
  final double? rootCauseConfidence;
  final List<String> missingInformation;
  final int qualityScore;

  AiBugAnalysis toDomain() {
    return AiBugAnalysis(
      severity: severity,
      severityReason: severityReason,
      priority: priority,
      priorityReason: priorityReason,
      reproductionSteps: reproductionSteps,
      testCases: testCases.map((testCase) => testCase.toDomain()).toList(),
      possibleRootCause: possibleRootCause,
      rootCauseConfidence: rootCauseConfidence,
      missingInformation: missingInformation,
      qualityScore: qualityScore,
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

class AiTestCaseResponse {
  const AiTestCaseResponse({
    required this.id,
    required this.type,
    required this.title,
    required this.given,
    required this.when,
    required this.then,
  });

  factory AiTestCaseResponse.fromJson(Map<String, dynamic> json) {
    return AiTestCaseResponse(
      id: _requiredString(json, 'id'),
      type: bugTestCaseTypeFromJson(_requiredString(json, 'type')),
      title: _requiredString(json, 'title'),
      given: _requiredString(json, 'given'),
      when: _requiredString(json, 'when'),
      then: _requiredString(json, 'then'),
    );
  }

  final String id;
  final BugTestCaseType type;
  final String title;
  final String given;
  final String when;
  final String then;

  BugTestCase toDomain() {
    return BugTestCase(
      id: id,
      type: type,
      title: title,
      given: given,
      when: when,
      then: then,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.jsonValue,
      'title': title,
      'given': given,
      'when': when,
      'then': then,
    };
  }
}

class AiAnalysisMetaResponse {
  const AiAnalysisMetaResponse({
    this.requestId,
    this.model,
    this.processingTimeMs,
  });

  factory AiAnalysisMetaResponse.fromJson(Map<String, dynamic> json) {
    return AiAnalysisMetaResponse(
      requestId: json['requestId'] as String?,
      model: json['model'] as String?,
      processingTimeMs: (json['processingTimeMs'] as num?)?.round(),
    );
  }

  final String? requestId;
  final String? model;
  final int? processingTimeMs;

  Map<String, dynamic> toJson() {
    return {
      if (requestId != null) 'requestId': requestId,
      if (model != null) 'model': model,
      if (processingTimeMs != null) 'processingTimeMs': processingTimeMs,
    };
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }

  return value;
}

String? _nullableString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be null or a non-empty string.');
  }

  return value;
}

double? _nullableDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! num) {
    throw FormatException('$key must be null or a number.');
  }

  return value.toDouble();
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) {
    throw FormatException('$key must be a number.');
  }

  return value.round();
}

List<String> _requiredStringList(Map<String, dynamic> json, String key) {
  final values = _optionalStringList(json, key);
  if (values.isEmpty) {
    throw FormatException('$key must include at least one item.');
  }

  return values;
}

List<String> _optionalStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return const [];
  }
  if (value is! List) {
    throw FormatException('$key must be a list.');
  }

  return value.map((item) {
    if (item is! String || item.trim().isEmpty) {
      throw FormatException('$key items must be non-empty strings.');
    }
    return item;
  }).toList();
}

void _validateNonEmpty(String key, String? value) {
  if (value == null || value.trim().isEmpty) {
    throw FormatException('$key must be non-empty.');
  }
}
