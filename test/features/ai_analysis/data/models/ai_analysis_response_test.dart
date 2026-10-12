import 'dart:convert';
import 'dart:io';

import 'package:bugpilot_ai/features/ai_analysis/data/models/ai_analysis_response.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_priority.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_severity.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_test_case_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiAnalysisResponse', () {
    test('parses success fixture and maps to domain', () {
      final response = AiAnalysisResponse.fromJson(_successFixture());
      final domain = response.toDomain();

      expect(response.meta?.requestId, 'req_123');
      expect(response.meta?.processingTimeMs, 1240);
      expect(domain.severity, BugSeverity.high);
      expect(domain.priority, BugPriority.p1);
      expect(domain.severityReason, 'The issue blocks an important user flow.');
      expect(domain.priorityReason, 'The issue should be addressed quickly.');
      expect(domain.reproductionSteps, hasLength(5));
      expect(domain.testCases, hasLength(3));
      expect(domain.testCases.first.type, BugTestCaseType.positive);
      expect(
        domain.possibleRootCause,
        contains('loading state may not be reset'),
      );
      expect(domain.rootCauseConfidence, 0.72);
      expect(domain.missingInformation, ['Device model was not provided.']);
      expect(domain.qualityScore, 82);
    });

    test('works when optional metadata is absent', () {
      final json = _successFixture()..remove('meta');

      final response = AiAnalysisResponse.fromJson(json);

      expect(response.meta, isNull);
      expect(response.toDomain().qualityScore, 82);
    });

    test('rejects invalid severity and priority values', () {
      expect(
        () => AiAnalysisResponse.fromJson(
          _withAnalysisValue('severity', 'catastrophic'),
        ),
        throwsArgumentError,
      );
      expect(
        () => AiAnalysisResponse.fromJson(_withAnalysisValue('priority', 'p9')),
        throwsArgumentError,
      );
    });

    test('rejects invalid confidence values', () {
      expect(
        () => AiAnalysisResponse.fromJson(
          _withAnalysisValue('rootCauseConfidence', -0.01),
        ),
        throwsFormatException,
      );
      expect(
        () => AiAnalysisResponse.fromJson(
          _withAnalysisValue('rootCauseConfidence', 1.01),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid quality score values', () {
      expect(
        () =>
            AiAnalysisResponse.fromJson(_withAnalysisValue('qualityScore', -1)),
        throwsFormatException,
      );
      expect(
        () => AiAnalysisResponse.fromJson(
          _withAnalysisValue('qualityScore', 101),
        ),
        throwsFormatException,
      );
    });

    test('rejects empty generated content', () {
      expect(
        () => AiAnalysisResponse.fromJson(
          _withAnalysisValue('reproductionSteps', <String>[]),
        ),
        throwsFormatException,
      );
      expect(
        () => AiAnalysisResponse.fromJson(
          _withAnalysisValue('severityReason', ''),
        ),
        throwsFormatException,
      );
      expect(
        () => AiAnalysisResponse.fromJson(
          _withAnalysisValue('possibleRootCause', ''),
        ),
        throwsFormatException,
      );
    });
  });
}

Map<String, dynamic> _successFixture() {
  return jsonDecode(
        File('test/fixtures/ai_analysis_success.json').readAsStringSync(),
      )
      as Map<String, dynamic>;
}

Map<String, dynamic> _withAnalysisValue(String key, Object? value) {
  final json = _successFixture();
  final analysis = json['analysis'] as Map<String, dynamic>;
  analysis[key] = value;
  return json;
}
