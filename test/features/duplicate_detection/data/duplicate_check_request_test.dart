import 'dart:convert';

import 'package:bugpilot_ai/models/bug_platform.dart';
import 'package:bugpilot_ai/models/bug_priority.dart';
import 'package:bugpilot_ai/models/bug_severity.dart';
import 'package:bugpilot_ai/models/bug_status.dart';
import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:bugpilot_ai/models/bug_screenshot.dart';
import 'package:bugpilot_ai/models/duplicate_check_request.dart';
import 'package:bugpilot_ai/models/similar_bug_candidate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps only duplicate-check fields and omits logs and screenshot', () {
    final request = DuplicateCheckRequest.fromBugReport(
      draft: _bug(
        id: 'draft',
        logs: 'Sensitive logs',
        screenshot: _screenshot(),
      ),
      candidates: [
        SimilarBugCandidate(
          bug: _bug(
            id: 'bug-001',
            logs: 'Candidate logs',
            screenshot: _screenshot(),
          ),
          localScore: 0.8,
        ),
      ],
    );

    final json = request.toJson();
    expect(json['language'], 'en');
    expect(json['bug'], {
      'title': 'Login button stuck loading',
      'description': 'The login screen remains loading.',
      'expectedBehavior': 'The dashboard should open.',
      'actualBehavior': 'The loading indicator remains visible.',
      'platform': 'android',
    });
    expect(jsonEncode(json), isNot(contains('Sensitive logs')));
    expect(jsonEncode(json), isNot(contains('/tmp/screenshot.png')));
    expect((json['candidates'] as List).single, containsPair('id', 'bug-001'));
    expect(
      (json['candidates'] as List).single,
      containsPair('severity', 'high'),
    );
    expect((json['candidates'] as List).single, containsPair('status', 'open'));
  });
}

BugScreenshot _screenshot() {
  return const BugScreenshot(
    id: 'shot-001',
    localPath: '/tmp/screenshot.png',
    fileName: 'screenshot.png',
    mimeType: 'image/png',
    sizeBytes: 100,
  );
}

BugReport _bug({required String id, String? logs, BugScreenshot? screenshot}) {
  return BugReport(
    id: id,
    title: 'Login button stuck loading',
    description: 'The login screen remains loading.',
    expectedBehavior: 'The dashboard should open.',
    actualBehavior: 'The loading indicator remains visible.',
    platform: BugPlatform.android,
    severity: BugSeverity.high,
    priority: BugPriority.p1,
    status: BugStatus.open,
    logs: logs,
    screenshot: screenshot,
    createdAt: DateTime.utc(2026, 8, 19),
    updatedAt: DateTime.utc(2026, 8, 19),
  );
}
