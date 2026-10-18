import 'dart:io';

import 'package:bugpilot_ai/repositories/hive_bug_repository.dart';
import 'package:bugpilot_ai/services/bug_attachment_storage.dart';
import 'package:bugpilot_ai/models/bug_platform.dart';
import 'package:bugpilot_ai/models/bug_priority.dart';
import 'package:bugpilot_ai/models/bug_severity.dart';
import 'package:bugpilot_ai/models/bug_status.dart';
import 'package:bugpilot_ai/models/bug_test_case_type.dart';
import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:bugpilot_ai/models/bug_screenshot.dart';
import 'package:bugpilot_ai/models/bug_test_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bugpilot_hive_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HiveBugRepository', () {
    test('persists a complete bug report after reopening storage', () async {
      var repository = await HiveBugRepository.create(seedBugs: []);
      final bug = _completeBugReport();

      await repository.createBug(bug);
      repository = await _reopen(repository, seedBugs: []);

      final restored = await repository.getBugById(bug.id);
      expect(restored, bug);
      expect(restored?.toJson()['createdAt'], '2026-08-19T09:15:30.456Z');
      expect(restored?.testCases.single.type, BugTestCaseType.edgeCase);
    });

    test('preserves nullable fields as null after reopening storage', () async {
      var repository = await HiveBugRepository.create(seedBugs: []);
      final bug = _minimalBugReport();

      await repository.createBug(bug);
      repository = await _reopen(repository, seedBugs: []);

      final restored = await repository.getBugById(bug.id);
      expect(restored?.device, isNull);
      expect(restored?.osVersion, isNull);
      expect(restored?.appVersion, isNull);
      expect(restored?.logs, isNull);
      expect(restored?.severity, isNull);
      expect(restored?.priority, isNull);
      expect(restored?.possibleRootCause, isNull);
      expect(restored?.rootCauseConfidence, isNull);
    });

    test('persists updates after reopening storage', () async {
      var repository = await HiveBugRepository.create(seedBugs: []);
      final bug = _completeBugReport();

      await repository.createBug(bug);
      await repository.updateBug(
        bug.copyWith(
          title: 'Updated persistent title',
          status: BugStatus.resolved,
          severity: BugSeverity.critical,
          priority: BugPriority.p0,
          logs: 'Updated logs',
          possibleRootCause: 'Updated hypothesis.',
          rootCauseConfidence: 0.91,
        ),
      );
      repository = await _reopen(repository, seedBugs: []);

      final restored = await repository.getBugById(bug.id);
      expect(restored?.title, 'Updated persistent title');
      expect(restored?.status, BugStatus.resolved);
      expect(restored?.severity, BugSeverity.critical);
      expect(restored?.priority, BugPriority.p0);
      expect(restored?.logs, 'Updated logs');
      expect(restored?.possibleRootCause, 'Updated hypothesis.');
      expect(restored?.rootCauseConfidence, 0.91);
    });

    test('persists deletes after reopening storage', () async {
      var repository = await HiveBugRepository.create(seedBugs: []);
      final bug = _completeBugReport();

      await repository.createBug(bug);
      await repository.deleteBug(bug.id);
      repository = await _reopen(repository, seedBugs: []);

      expect(await repository.getBugById(bug.id), isNull);
      expect(await repository.getBugs(), isEmpty);
    });

    test('persists screenshot metadata and cleans up on delete', () async {
      final attachmentStorage = BugAttachmentStorage(
        baseDirectoryProvider: () async => tempDir,
      );
      final repository = await HiveBugRepository.create(
        seedBugs: [],
        attachmentStorage: attachmentStorage,
      );
      final source = await File(
        '${tempDir.path}/source.png',
      ).writeAsBytes(List<int>.filled(32, 1));
      final bug = _minimalBugReport().copyWith(
        screenshot: BugScreenshot(
          id: 'shot-001',
          localPath: source.path,
          fileName: 'source.png',
          mimeType: 'image/png',
          sizeBytes: 32,
        ),
      );

      await repository.createBug(bug);

      final restored = await repository.getBugById(bug.id);
      expect(restored?.screenshot, isNotNull);
      expect(restored?.screenshot?.localPath, isNot(source.path));
      expect(await File(restored!.screenshot!.localPath).exists(), isTrue);

      await repository.deleteBug(bug.id);

      expect(await File(restored.screenshot!.localPath).exists(), isFalse);
    });

    test('seeds demo bugs on first run only', () async {
      var repository = await HiveBugRepository.create(
        seedBugs: [_minimalBugReport(id: 'seed-001', title: 'First seed')],
      );

      expect(await repository.getBugs(), hasLength(1));

      repository = await _reopen(
        repository,
        seedBugs: [_minimalBugReport(id: 'seed-002', title: 'Second seed')],
      );

      final bugs = await repository.getBugs();
      expect(bugs, hasLength(1));
      expect(bugs.single.id, 'seed-001');
    });

    test('does not reseed after the user deletes all reports', () async {
      var repository = await HiveBugRepository.create(
        seedBugs: [_minimalBugReport(id: 'seed-001')],
      );

      await repository.deleteBug('seed-001');
      repository = await _reopen(
        repository,
        seedBugs: [_minimalBugReport(id: 'seed-001')],
      );

      expect(await repository.getBugs(), isEmpty);
    });

    test('throws StateError when creating a duplicate id', () async {
      final repository = await HiveBugRepository.create(seedBugs: []);
      final bug = _completeBugReport();

      await repository.createBug(bug);

      expect(() => repository.createBug(bug), throwsA(isA<StateError>()));
    });

    test('throws StateError when updating a missing id', () async {
      final repository = await HiveBugRepository.create(seedBugs: []);

      expect(
        () => repository.updateBug(_completeBugReport()),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'skips corrupt records while keeping valid records available',
      () async {
        final repository = await HiveBugRepository.create(seedBugs: []);
        final validBug = _completeBugReport();
        final box = Hive.box<Map<dynamic, dynamic>>(
          HiveBugRepository.bugReportsBoxName,
        );

        await repository.createBug(validBug);
        await box.put('broken', {
          'id': 42,
          'title': 'Broken report',
          'createdAt': 'not a date',
        });

        final bugs = await repository.getBugs();
        expect(bugs, [validBug]);
        expect(await repository.getBugById('broken'), isNull);
      },
    );
  });
}

Future<HiveBugRepository> _reopen(
  HiveBugRepository repository, {
  required List<BugReport> seedBugs,
}) async {
  await repository.close();
  return HiveBugRepository.create(seedBugs: seedBugs);
}

BugReport _completeBugReport() {
  return BugReport(
    id: 'bug-001',
    title: 'Checkout fails for gift cards',
    description: 'Checkout rejects valid gift-card-only orders.',
    expectedBehavior: 'The gift card order should complete.',
    actualBehavior: 'The payment step returns a validation error.',
    platform: BugPlatform.web,
    device: 'MacBook Pro',
    osVersion: 'macOS 16',
    appVersion: '1.2.3',
    logs: 'ValidationError: paymentMethod required',
    severity: BugSeverity.high,
    priority: BugPriority.p1,
    status: BugStatus.inProgress,
    reproductionSteps: const [
      'Add a gift card to cart.',
      'Proceed to checkout.',
      'Submit payment.',
    ],
    testCases: const [
      BugTestCase(
        id: 'tc-edge-001',
        type: BugTestCaseType.edgeCase,
        title: 'Gift-card-only checkout completes',
        given: 'The cart contains only a gift card',
        when: 'The customer submits checkout',
        then: 'The order is created without a payment method',
      ),
    ],
    possibleRootCause: 'Payment validation may not special-case gift cards.',
    rootCauseConfidence: 0.84,
    createdAt: DateTime.utc(2026, 8, 19, 9, 15, 30, 456),
    updatedAt: DateTime.utc(2026, 8, 19, 10, 45, 12, 789),
  );
}

BugReport _minimalBugReport({
  String id = 'bug-minimal',
  String title = 'Manual report',
  BugSeverity? severity,
  BugPriority? priority,
  BugStatus status = BugStatus.open,
  DateTime? createdAt,
}) {
  final timestamp = createdAt ?? DateTime.utc(2026, 8, 19, 9);

  return BugReport(
    id: id,
    title: title,
    description: '$title description',
    expectedBehavior: 'The feature should work.',
    actualBehavior: 'The feature fails.',
    platform: BugPlatform.android,
    severity: severity,
    priority: priority,
    status: status,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}
