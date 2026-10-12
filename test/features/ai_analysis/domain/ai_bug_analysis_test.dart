import 'package:bugpilot_ai/features/ai_analysis/domain/models/ai_bug_analysis.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_priority.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_severity.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_test_case_type.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/models/bug_test_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiBugAnalysis', () {
    test('serializes to stable JSON values', () {
      final analysis = _analysis();

      expect(analysis.toJson(), {
        'severity': 'high',
        'severityReason': 'Blocks a core workflow.',
        'priority': 'p1',
        'priorityReason': 'Needs attention soon.',
        'reproductionSteps': ['Open app', 'Tap Save'],
        'testCases': [
          {
            'id': 'TC-01',
            'title': 'Expected flow completes successfully',
            'given': 'A valid user',
            'when': 'The action runs',
            'then': 'The flow completes',
            'type': 'positive',
          },
        ],
        'possibleRootCause': 'State may not update after async completion.',
        'rootCauseConfidence': 0.72,
        'missingInformation': ['Device model was not provided.'],
        'qualityScore': 82,
      });
    });

    test(
      'deserializes enums, confidence, test cases, missing info, and score',
      () {
        final restored = AiBugAnalysis.fromJson({
          'severity': 'critical',
          'severityReason': 'Checkout is blocked.',
          'priority': 'p0',
          'priorityReason': 'Production users cannot complete orders.',
          'reproductionSteps': ['Open checkout'],
          'testCases': [
            {
              'id': 'TC-03',
              'title': 'Repeated action does not break state',
              'given': 'The user is on checkout',
              'when': 'They tap Pay twice',
              'then': 'Only one order is created',
              'type': 'edgeCase',
            },
          ],
          'possibleRootCause': 'Duplicate submit handling may be missing.',
          'rootCauseConfidence': 0.67,
          'missingInformation': ['Error logs were not provided.'],
          'qualityScore': 74.4,
        });

        expect(restored.severity, BugSeverity.critical);
        expect(restored.priority, BugPriority.p0);
        expect(restored.rootCauseConfidence, 0.67);
        expect(restored.testCases.single.type, BugTestCaseType.edgeCase);
        expect(restored.missingInformation, ['Error logs were not provided.']);
        expect(restored.qualityScore, 74);
      },
    );

    test('copyWith replaces selected fields without mutating the original', () {
      final analysis = _analysis();

      final updated = analysis.copyWith(
        severity: BugSeverity.critical,
        reproductionSteps: const ['Open app', 'Tap Checkout'],
      );

      expect(updated.severity, BugSeverity.critical);
      expect(updated.reproductionSteps, ['Open app', 'Tap Checkout']);
      expect(updated.priority, analysis.priority);
      expect(updated.testCases, analysis.testCases);
      expect(analysis.severity, BugSeverity.high);
      expect(analysis.reproductionSteps, ['Open app', 'Tap Save']);
    });

    test('supports nullable disabled AI suggestion fields', () {
      final analysis = _analysis().copyWith(
        severity: null,
        severityReason: null,
        priority: null,
        priorityReason: null,
        testCases: const [],
        possibleRootCause: null,
        rootCauseConfidence: null,
      );

      expect(analysis.toJson()['severity'], isNull);
      expect(analysis.toJson()['priority'], isNull);
      expect(analysis.toJson()['testCases'], isEmpty);
      expect(analysis.toJson()['possibleRootCause'], isNull);

      final restored = AiBugAnalysis.fromJson(analysis.toJson());

      expect(restored.severity, isNull);
      expect(restored.priority, isNull);
      expect(restored.testCases, isEmpty);
      expect(restored.possibleRootCause, isNull);
      expect(restored.rootCauseConfidence, isNull);
    });
  });
}

AiBugAnalysis _analysis() {
  return AiBugAnalysis(
    severity: BugSeverity.high,
    severityReason: 'Blocks a core workflow.',
    priority: BugPriority.p1,
    priorityReason: 'Needs attention soon.',
    reproductionSteps: const ['Open app', 'Tap Save'],
    testCases: const [
      BugTestCase(
        id: 'TC-01',
        type: BugTestCaseType.positive,
        title: 'Expected flow completes successfully',
        given: 'A valid user',
        when: 'The action runs',
        then: 'The flow completes',
      ),
    ],
    possibleRootCause: 'State may not update after async completion.',
    rootCauseConfidence: 0.72,
    missingInformation: const ['Device model was not provided.'],
    qualityScore: 82,
  );
}
