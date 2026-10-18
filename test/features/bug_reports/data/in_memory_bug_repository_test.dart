import 'package:bugpilot_ai/repositories/in_memory_bug_repository.dart';
import 'package:bugpilot_ai/models/bug_platform.dart';
import 'package:bugpilot_ai/models/bug_priority.dart';
import 'package:bugpilot_ai/models/bug_severity.dart';
import 'package:bugpilot_ai/models/bug_status.dart';
import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryBugRepository', () {
    test('starts empty unless reports are explicitly provided', () async {
      final repository = InMemoryBugRepository();

      final bugs = await repository.getBugs();

      expect(bugs, isEmpty);
    });

    test('gets all bugs as an unmodifiable list', () async {
      final repository = InMemoryBugRepository(seedBugs: [_bugReport()]);

      final bugs = await repository.getBugs();

      expect(bugs, hasLength(1));
      expect(() => bugs.add(_bugReport(id: 'bug-002')), throwsUnsupportedError);
    });

    test('gets a bug by id', () async {
      final repository = InMemoryBugRepository(seedBugs: [_bugReport()]);

      final bug = await repository.getBugById('bug-001');

      expect(bug?.title, 'Login button stuck loading');
      expect(await repository.getBugById('missing'), isNull);
    });

    test('creates a bug', () async {
      final repository = InMemoryBugRepository(seedBugs: []);

      await repository.createBug(_bugReport());

      expect(await repository.getBugs(), hasLength(1));
    });

    test('throws when creating a duplicate id', () async {
      final repository = InMemoryBugRepository(seedBugs: [_bugReport()]);

      expect(
        () => repository.createBug(_bugReport()),
        throwsA(isA<StateError>()),
      );
    });

    test('updates an existing bug', () async {
      final repository = InMemoryBugRepository(seedBugs: [_bugReport()]);
      final updated = _bugReport().copyWith(
        title: 'Updated title',
        status: BugStatus.resolved,
      );

      await repository.updateBug(updated);

      final bug = await repository.getBugById('bug-001');
      expect(bug?.title, 'Updated title');
      expect(bug?.status, BugStatus.resolved);
    });

    test('throws when updating a missing bug', () async {
      final repository = InMemoryBugRepository(seedBugs: []);

      expect(
        () => repository.updateBug(_bugReport()),
        throwsA(isA<StateError>()),
      );
    });

    test('deletes a matching bug', () async {
      final repository = InMemoryBugRepository(seedBugs: [_bugReport()]);

      await repository.deleteBug('bug-001');

      expect(await repository.getBugs(), isEmpty);
    });
  });
}

BugReport _bugReport({String id = 'bug-001'}) {
  return BugReport(
    id: id,
    title: 'Login button stuck loading',
    description: 'The login screen remains in a loading state.',
    expectedBehavior: 'The user should be redirected to the dashboard.',
    actualBehavior: 'The loading indicator remains visible indefinitely.',
    platform: BugPlatform.android,
    device: 'Pixel 9',
    osVersion: 'Android 16',
    appVersion: '1.0.0',
    severity: BugSeverity.high,
    priority: BugPriority.p1,
    status: BugStatus.open,
    createdAt: DateTime.utc(2026, 8, 19, 9),
    updatedAt: DateTime.utc(2026, 8, 19, 10),
  );
}
