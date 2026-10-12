import 'package:bugpilot_ai/features/ai_analysis/data/models/ai_analysis_request.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_platform.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_status.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/models/bug_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiAnalysisRequest', () {
    test('serializes required fields and environment object', () {
      const request = AiAnalysisRequest(
        title: 'Login button stuck loading',
        description: 'The login screen remains loading.',
        expectedBehavior: 'The dashboard should open.',
        actualBehavior: 'The loading indicator remains visible.',
        environment: AiEnvironmentRequest(
          platform: 'android',
          device: 'Pixel 9',
          osVersion: 'Android 16',
          appVersion: '1.0.0',
        ),
        logs: 'Stack trace',
      );

      expect(request.toJson(), {
        'title': 'Login button stuck loading',
        'description': 'The login screen remains loading.',
        'expectedBehavior': 'The dashboard should open.',
        'actualBehavior': 'The loading indicator remains visible.',
        'environment': {
          'platform': 'android',
          'device': 'Pixel 9',
          'osVersion': 'Android 16',
          'appVersion': '1.0.0',
        },
        'preferences': _defaultPreferences,
        'logs': 'Stack trace',
      });
    });

    test('omits null optional values predictably', () {
      const request = AiAnalysisRequest(
        title: 'Title',
        description: 'Description',
        expectedBehavior: 'Expected',
        actualBehavior: 'Actual',
        environment: AiEnvironmentRequest(platform: 'web'),
      );

      expect(request.toJson(), {
        'title': 'Title',
        'description': 'Description',
        'expectedBehavior': 'Expected',
        'actualBehavior': 'Actual',
        'environment': {'platform': 'web'},
        'preferences': _defaultPreferences,
      });
    });

    test('maps explicitly from BugReport without local metadata', () {
      final request = AiAnalysisRequest.fromBugReport(_bugReport());

      expect(request.toJson(), {
        'title': 'Crash on launch',
        'description': 'The app crashes immediately after launch.',
        'expectedBehavior': 'The dashboard should open.',
        'actualBehavior': 'The app closes before the dashboard appears.',
        'environment': {
          'platform': 'ios',
          'device': 'iPhone 16',
          'osVersion': 'iOS 19',
          'appVersion': '1.2.3',
        },
        'preferences': _defaultPreferences,
        'logs': 'Crash log',
      });
      expect(request.toJson().containsKey('id'), isFalse);
      expect(request.toJson().containsKey('createdAt'), isFalse);
      expect(request.toJson().containsKey('updatedAt'), isFalse);
      expect(request.toJson().containsKey('status'), isFalse);
    });
  });
}

const _defaultPreferences = {
  'severity': true,
  'priority': true,
  'testCases': true,
  'rootCause': true,
  'screenshotAnalysis': true,
};

BugReport _bugReport() {
  return BugReport(
    id: 'bug-001',
    title: 'Crash on launch',
    description: 'The app crashes immediately after launch.',
    expectedBehavior: 'The dashboard should open.',
    actualBehavior: 'The app closes before the dashboard appears.',
    platform: BugPlatform.ios,
    device: 'iPhone 16',
    osVersion: 'iOS 19',
    appVersion: '1.2.3',
    logs: 'Crash log',
    status: BugStatus.open,
    createdAt: DateTime.utc(2026, 8, 19),
    updatedAt: DateTime.utc(2026, 8, 19),
  );
}
