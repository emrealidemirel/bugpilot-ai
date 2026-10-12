import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_platform.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_priority.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_severity.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_status.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_test_case_type.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/models/bug_report.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/models/bug_screenshot.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/models/bug_test_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BugReport', () {
    test('copyWith updates selected values and can clear nullable fields', () {
      final original = _bugReport();

      final updated = original.copyWith(
        title: 'Updated title',
        severity: null,
        priority: BugPriority.p0,
        rootCauseConfidence: null,
      );

      expect(updated.id, original.id);
      expect(updated.title, 'Updated title');
      expect(updated.severity, isNull);
      expect(updated.priority, BugPriority.p0);
      expect(updated.rootCauseConfidence, isNull);
      expect(original.severity, BugSeverity.high);
      expect(original.rootCauseConfidence, 0.6);
    });

    test('serializes and deserializes a JSON round trip', () {
      final original = _bugReport();

      final restored = BugReport.fromJson(original.toJson());

      expect(restored, original);
      expect(restored.toJson()['createdAt'], '2026-08-19T09:00:00.000Z');
      expect(restored.toJson()['severity'], 'high');
      expect(restored.toJson()['priority'], 'p1');
      expect(restored.toJson()['status'], 'open');
      expect(restored.toJson()['platform'], 'android');
      expect(restored.toJson()['screenshot'], isA<Map<String, dynamic>>());
    });

    test('deserializes old JSON without screenshot as null', () {
      final json = _bugReport(screenshot: null).toJson()..remove('screenshot');

      final restored = BugReport.fromJson(json);

      expect(restored.screenshot, isNull);
    });

    test(
      'keeps nullable AI fields nullable and list fields empty by default',
      () {
        final report = _bugReport(
          severity: null,
          priority: null,
          possibleRootCause: null,
          rootCauseConfidence: null,
          reproductionSteps: const [],
          testCases: const [],
        );

        final restored = BugReport.fromJson(report.toJson());

        expect(restored.severity, isNull);
        expect(restored.priority, isNull);
        expect(restored.possibleRootCause, isNull);
        expect(restored.rootCauseConfidence, isNull);
        expect(restored.reproductionSteps, isEmpty);
        expect(restored.testCases, isEmpty);
      },
    );

    test('deserializes enum JSON values', () {
      expect(bugSeverityFromJson('critical'), BugSeverity.critical);
      expect(bugPriorityFromJson('p2'), BugPriority.p2);
      expect(bugStatusFromJson('inProgress'), BugStatus.inProgress);
      expect(bugPlatformFromJson('ios'), BugPlatform.ios);
      expect(bugTestCaseTypeFromJson('edgeCase'), BugTestCaseType.edgeCase);
    });
  });

  group('BugTestCase', () {
    test('serializes and deserializes JSON', () {
      const testCase = BugTestCase(
        id: 'tc-001',
        title: 'Valid login succeeds',
        given: 'The user has valid credentials',
        when: 'The login form is submitted',
        then: 'The dashboard is shown',
        type: BugTestCaseType.positive,
      );

      final restored = BugTestCase.fromJson(testCase.toJson());

      expect(restored, testCase);
      expect(restored.toJson()['type'], 'positive');
    });
  });

  group('BugScreenshot', () {
    test('serializes and deserializes JSON', () {
      const screenshot = BugScreenshot(
        id: 'shot-001',
        localPath: '/tmp/shot.png',
        fileName: 'shot.png',
        mimeType: 'image/png',
        sizeBytes: 2048,
      );

      final restored = BugScreenshot.fromJson(screenshot.toJson());

      expect(restored, screenshot);
      expect(restored.localPath, '/tmp/shot.png');
      expect(restored.mimeType, 'image/png');
    });
  });
}

BugReport _bugReport({
  BugSeverity? severity = BugSeverity.high,
  BugPriority? priority = BugPriority.p1,
  String? possibleRootCause = 'Navigation callback did not run.',
  double? rootCauseConfidence = 0.6,
  BugScreenshot? screenshot = const BugScreenshot(
    id: 'shot-001',
    localPath: '/tmp/shot.png',
    fileName: 'shot.png',
    mimeType: 'image/png',
    sizeBytes: 2048,
  ),
  List<String> reproductionSteps = const ['Submit valid credentials'],
  List<BugTestCase> testCases = const [
    BugTestCase(
      id: 'tc-001',
      title: 'Valid login succeeds',
      given: 'The user has valid credentials',
      when: 'The login form is submitted',
      then: 'The dashboard is shown',
      type: BugTestCaseType.positive,
    ),
  ],
}) {
  return BugReport(
    id: 'bug-001',
    title: 'Login button stuck loading',
    description: 'The login screen remains in a loading state.',
    expectedBehavior: 'The user should be redirected to the dashboard.',
    actualBehavior: 'The loading indicator remains visible indefinitely.',
    platform: BugPlatform.android,
    device: 'Pixel 9',
    osVersion: 'Android 16',
    appVersion: '1.0.0',
    logs: 'Navigation callback did not run.',
    severity: severity,
    priority: priority,
    status: BugStatus.open,
    reproductionSteps: reproductionSteps,
    testCases: testCases,
    possibleRootCause: possibleRootCause,
    rootCauseConfidence: rootCauseConfidence,
    screenshot: screenshot,
    createdAt: DateTime.utc(2026, 8, 19, 9),
    updatedAt: DateTime.utc(2026, 8, 19, 10),
  );
}
