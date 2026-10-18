import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

import 'package:bugpilot_ai/services/bug_attachment_storage.dart';
import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:bugpilot_ai/repositories/bug_repository.dart';

class HiveBugRepository implements BugRepository {
  HiveBugRepository._({
    required this._bugBox,
    required this._metadataBox,
    required this._attachmentStorage,
  });

  static const bugReportsBoxName = 'bug_reports';
  static const metadataBoxName = 'bug_reports_metadata';
  static const currentSchemaVersion = 1;

  static const _schemaVersionKey = 'schemaVersion';
  static const _legacyDemoCleanupKey = 'legacyDemoReportsRemoved';
  static const _seedDataInitializedKey = 'seedDataInitialized';
  static const _legacyDemoReportIds = {
    'bug-001',
    'bug-002',
    'bug-003',
    'bug-004',
    'bug-005',
  };

  final Box<Map<dynamic, dynamic>> _bugBox;
  final Box<dynamic> _metadataBox;
  final BugAttachmentStorage _attachmentStorage;

  static Future<HiveBugRepository> create({
    List<BugReport>? seedBugs,
    BugAttachmentStorage? attachmentStorage,
  }) async {
    final bugBox = await Hive.openBox<Map<dynamic, dynamic>>(bugReportsBoxName);
    final metadataBox = await Hive.openBox<dynamic>(metadataBoxName);
    await LocalStorageMigrator(metadataBox).migrate();

    final repository = HiveBugRepository._(
      bugBox: bugBox,
      metadataBox: metadataBox,
      attachmentStorage: attachmentStorage ?? BugAttachmentStorage(),
    );
    await repository._removeLegacyDemoReports();
    final seedsInitialized =
        metadataBox.get(_seedDataInitializedKey, defaultValue: false) == true;
    if (repository._bugBox.isNotEmpty && !seedsInitialized) {
      await metadataBox.put(_seedDataInitializedKey, true);
    } else if (!seedsInitialized &&
        seedBugs != null &&
        seedBugs.isNotEmpty &&
        repository._bugBox.isEmpty) {
      await repository._bugBox.putAll({
        for (final bug in seedBugs) bug.id: repository._encodeBug(bug),
      });
      await metadataBox.put(_seedDataInitializedKey, true);
    }
    return repository;
  }

  @override
  Future<List<BugReport>> getBugs() async {
    final bugs = <BugReport>[];

    for (final entry in _bugBox.toMap().entries) {
      final bug = _decodeBug(entry.key, entry.value);
      if (bug != null) {
        bugs.add(bug);
      }
    }

    bugs.sort((a, b) {
      final createdComparison = b.createdAt.compareTo(a.createdAt);
      if (createdComparison != 0) {
        return createdComparison;
      }

      return a.id.compareTo(b.id);
    });

    return List.unmodifiable(bugs);
  }

  @override
  Future<BugReport?> getBugById(String id) async {
    return _decodeBug(id, _bugBox.get(id));
  }

  @override
  Future<void> createBug(BugReport bug) async {
    if (_bugBox.containsKey(bug.id)) {
      throw StateError('A bug with id "${bug.id}" already exists.');
    }

    final storedBug = await _withPersistedScreenshot(bug);
    try {
      await _bugBox.put(storedBug.id, _encodeBug(storedBug));
    } on Object {
      if (_screenshotPath(storedBug) != _screenshotPath(bug)) {
        await _attachmentStorage.deleteScreenshot(storedBug.screenshot);
      }
      rethrow;
    }
  }

  @override
  Future<void> updateBug(BugReport bug) async {
    if (!_bugBox.containsKey(bug.id)) {
      throw StateError('Cannot update missing bug with id "${bug.id}".');
    }

    final previousBug = _decodeBug(bug.id, _bugBox.get(bug.id));
    final storedBug = await _withPersistedScreenshot(bug);
    try {
      await _bugBox.put(storedBug.id, _encodeBug(storedBug));
    } on Object {
      if (_screenshotPath(storedBug) != _screenshotPath(bug)) {
        await _attachmentStorage.deleteScreenshot(storedBug.screenshot);
      }
      rethrow;
    }

    final oldScreenshot = previousBug?.screenshot;
    final newScreenshot = storedBug.screenshot;
    if (oldScreenshot != null &&
        (newScreenshot == null ||
            oldScreenshot.localPath != newScreenshot.localPath)) {
      await _attachmentStorage.deleteScreenshot(oldScreenshot);
    }
  }

  @override
  Future<void> deleteBug(String id) async {
    final bug = await getBugById(id);
    await _bugBox.delete(id);
    await _attachmentStorage.deleteScreenshot(bug?.screenshot);
  }

  Future<void> close() async {
    await _bugBox.close();
    await _metadataBox.close();
  }

  Future<void> _removeLegacyDemoReports() async {
    final cleanupApplied =
        _metadataBox.get(_legacyDemoCleanupKey, defaultValue: false) == true;
    if (cleanupApplied) {
      return;
    }

    for (final id in _legacyDemoReportIds) {
      await deleteBug(id);
    }

    await _metadataBox.delete('demoSeedApplied');
    await _metadataBox.put(_legacyDemoCleanupKey, true);
  }

  Map<dynamic, dynamic> _encodeBug(BugReport bug) {
    return _toStorageMap(bug.toJson());
  }

  BugReport? _decodeBug(dynamic key, Map<dynamic, dynamic>? value) {
    if (value == null) {
      return null;
    }

    try {
      return BugReport.fromJson(_fromStorageMap(value));
    } on Object catch (error) {
      debugPrint('Skipping corrupt bug report "$key": $error');
      return null;
    }
  }

  Future<BugReport> _withPersistedScreenshot(BugReport bug) async {
    final screenshot = bug.screenshot;
    if (screenshot == null) {
      return bug;
    }

    final persistedScreenshot = await _attachmentStorage.persistScreenshot(
      screenshot: screenshot,
      bugId: bug.id,
    );
    if (persistedScreenshot == screenshot) {
      return bug;
    }

    return bug.copyWith(screenshot: persistedScreenshot);
  }

  String? _screenshotPath(BugReport bug) => bug.screenshot?.localPath;
}

class LocalStorageMigrator {
  const LocalStorageMigrator(this._metadataBox);

  final Box<dynamic> _metadataBox;

  Future<void> migrate() async {
    final version = _metadataBox.get(HiveBugRepository._schemaVersionKey);
    if (version == null) {
      await _metadataBox.put(
        HiveBugRepository._schemaVersionKey,
        HiveBugRepository.currentSchemaVersion,
      );
      return;
    }

    if (version is! int) {
      throw StateError('Local storage schema version is invalid.');
    }

    if (version > HiveBugRepository.currentSchemaVersion) {
      throw StateError(
        'Local storage schema version $version is newer than supported '
        'version ${HiveBugRepository.currentSchemaVersion}.',
      );
    }

    if (version < HiveBugRepository.currentSchemaVersion) {
      await _metadataBox.put(
        HiveBugRepository._schemaVersionKey,
        HiveBugRepository.currentSchemaVersion,
      );
    }
  }
}

Map<dynamic, dynamic> _toStorageMap(Map<String, dynamic> source) {
  return {
    for (final entry in source.entries) entry.key: _toStorageValue(entry.value),
  };
}

dynamic _toStorageValue(dynamic value) {
  if (value is Map<String, dynamic>) {
    return _toStorageMap(value);
  }

  if (value is List) {
    return value.map(_toStorageValue).toList(growable: false);
  }

  return value;
}

Map<String, dynamic> _fromStorageMap(Map<dynamic, dynamic> source) {
  final result = <String, dynamic>{};

  for (final entry in source.entries) {
    final key = entry.key;
    if (key is! String) {
      throw const FormatException('Storage map contains a non-string key.');
    }

    result[key] = _fromStorageValue(entry.value);
  }

  return result;
}

dynamic _fromStorageValue(dynamic value) {
  if (value is Map) {
    return _fromStorageMap(value.cast<dynamic, dynamic>());
  }

  if (value is List) {
    return value.map(_fromStorageValue).toList(growable: false);
  }

  return value;
}
