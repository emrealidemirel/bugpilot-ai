import 'package:bugpilot_ai/features/ai_analysis/data/services/mock_ai_bug_analysis_service.dart';
import 'package:bugpilot_ai/features/ai_analysis/domain/models/ai_analysis_preferences.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_platform.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_priority.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_severity.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_status.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/models/bug_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockAiBugAnalysisService', () {
    test('returns deterministic analysis fields', () async {
      const service = MockAiBugAnalysisService(delay: Duration.zero);

      final analysis = await service.analyze(_bugReport());

      expect(analysis.severity, BugSeverity.high);
      expect(analysis.priority, BugPriority.p1);
      expect(analysis.reproductionSteps, isNotEmpty);
      expect(analysis.testCases, hasLength(3));
      expect(analysis.rootCauseConfidence, inInclusiveRange(0, 1));
      expect(analysis.qualityScore, inInclusiveRange(0, 100));
    });

    test('reports missing optional information from the draft', () async {
      const service = MockAiBugAnalysisService(delay: Duration.zero);

      final analysis = await service.analyze(
        _bugReport(device: null, appVersion: null, logs: null),
      );

      expect(
        analysis.missingInformation,
        contains('Device model was not provided.'),
      );
      expect(
        analysis.missingInformation,
        contains('App version was not provided.'),
      );
      expect(
        analysis.missingInformation,
        contains('Error logs were not provided.'),
      );
    });

    test('returns null or empty disabled AI preference sections', () async {
      const service = MockAiBugAnalysisService(delay: Duration.zero);

      final analysis = await service.analyze(
        _bugReport(),
        preferences: const AiAnalysisPreferences(
          severity: false,
          priority: false,
          testCases: false,
          rootCause: false,
          screenshotAnalysis: false,
        ),
      );

      expect(analysis.severity, isNull);
      expect(analysis.severityReason, isNull);
      expect(analysis.priority, isNull);
      expect(analysis.priorityReason, isNull);
      expect(analysis.testCases, isEmpty);
      expect(analysis.possibleRootCause, isNull);
      expect(analysis.rootCauseConfidence, isNull);
    });
  });
}

BugReport _bugReport({
  String? device = 'Pixel 9',
  String? appVersion = '1.0.0',
  String? logs = 'Stack trace',
}) {
  return BugReport(
    id: 'bug-001',
    title: 'Crash on launch',
    description: 'The app crashes immediately after launch.',
    expectedBehavior: 'The dashboard should open.',
    actualBehavior: 'The app closes before the dashboard appears.',
    platform: BugPlatform.android,
    device: device,
    appVersion: appVersion,
    logs: logs,
    status: BugStatus.open,
    createdAt: DateTime.utc(2026, 8, 19),
    updatedAt: DateTime.utc(2026, 8, 19),
  );
}
