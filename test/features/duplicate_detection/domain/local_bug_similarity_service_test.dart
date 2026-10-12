import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_platform.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_priority.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_severity.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_status.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/models/bug_report.dart';
import 'package:bugpilot_ai/features/duplicate_detection/domain/services/local_bug_similarity_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalBugSimilarityService', () {
    test('selects a strong symptom match', () {
      const service = LocalBugSimilarityService();
      final draft = _bug(
        id: 'draft',
        title: 'Login button stuck loading',
        description: 'Submitting valid credentials leaves login loading.',
        expectedBehavior: 'The dashboard should open.',
        actualBehavior: 'The login spinner remains visible forever.',
      );
      final existing = _bug(
        id: 'bug-001',
        title: 'Login remains in infinite loading state',
        description: 'Valid credentials submit but login never finishes.',
        expectedBehavior: 'User should reach the dashboard.',
        actualBehavior: 'Spinner stays on the login form indefinitely.',
      );

      final candidates = service.findCandidates(
        draft: draft,
        existingBugs: [existing],
      );

      expect(candidates, hasLength(1));
      expect(candidates.single.bug.id, 'bug-001');
      expect(candidates.single.localScore, greaterThan(0.30));
    });

    test('ignores weak unrelated matches', () {
      const service = LocalBugSimilarityService();
      final draft = _bug(
        id: 'draft',
        title: 'Cart total incorrect',
        description: 'Discounted products produce the wrong checkout total.',
        expectedBehavior: 'The total should include the discount.',
        actualBehavior: 'The total ignores the discount.',
      );
      final existing = _bug(
        id: 'bug-001',
        title: 'Profile image disappears',
        description: 'The avatar disappears after the profile is refreshed.',
        expectedBehavior: 'The image should remain visible.',
        actualBehavior: 'The profile avatar is blank.',
      );

      final candidates = service.findCandidates(
        draft: draft,
        existingBugs: [existing],
      );

      expect(candidates, isEmpty);
    });

    test('can select same symptom on a different platform', () {
      const service = LocalBugSimilarityService();
      final draft = _bug(
        id: 'draft',
        title: 'Login button stuck loading',
        description: 'The login action never completes.',
        expectedBehavior: 'The dashboard should open.',
        actualBehavior: 'The login spinner remains visible forever.',
        platform: BugPlatform.android,
      );
      final existing = _bug(
        id: 'bug-001',
        title: 'Login stuck loading',
        description: 'Submitting login does not complete.',
        expectedBehavior: 'The dashboard should open.',
        actualBehavior: 'The loading spinner never clears.',
        platform: BugPlatform.ios,
      );

      final candidates = service.findCandidates(
        draft: draft,
        existingBugs: [existing],
      );

      expect(candidates, hasLength(1));
    });

    test('generic words do not strongly match unrelated bugs', () {
      const service = LocalBugSimilarityService();
      final score = service.score(
        draft: _bug(
          id: 'draft',
          title: 'App crashes',
          description: 'The app shows an error.',
          expectedBehavior: 'The app should work.',
          actualBehavior: 'The app crashes with an error.',
        ),
        existing: _bug(
          id: 'bug-001',
          title: 'App error on profile screen',
          description: 'The profile image fails to upload.',
          expectedBehavior: 'The profile image should upload.',
          actualBehavior: 'The app shows an upload error.',
        ),
      );

      expect(score, lessThan(0.30));
    });

    test('caps candidates to the configured maximum', () {
      const service = LocalBugSimilarityService(maxCandidates: 3);
      final draft = _bug(
        id: 'draft',
        title: 'Login button stuck loading',
        description: 'Login remains loading after submit.',
        expectedBehavior: 'The dashboard should open.',
        actualBehavior: 'The login spinner remains visible.',
      );
      final existing = [
        for (var index = 0; index < 10; index++)
          _bug(
            id: 'bug-$index',
            title: 'Login stuck loading $index',
            description: 'Login submit remains loading.',
            expectedBehavior: 'The dashboard should open.',
            actualBehavior: 'The login spinner remains visible.',
            createdAt: DateTime.utc(2026, 8, 19, index),
          ),
      ];

      final candidates = service.findCandidates(
        draft: draft,
        existingBugs: existing,
      );

      expect(candidates, hasLength(3));
      expect(candidates.first.bug.id, 'bug-9');
    });
  });
}

BugReport _bug({
  required String id,
  required String title,
  required String description,
  required String expectedBehavior,
  required String actualBehavior,
  BugPlatform platform = BugPlatform.android,
  DateTime? createdAt,
}) {
  final timestamp = createdAt ?? DateTime.utc(2026, 8, 19);
  return BugReport(
    id: id,
    title: title,
    description: description,
    expectedBehavior: expectedBehavior,
    actualBehavior: actualBehavior,
    platform: platform,
    severity: BugSeverity.high,
    priority: BugPriority.p1,
    status: BugStatus.open,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}
