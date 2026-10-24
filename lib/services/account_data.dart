import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:bugpilot_ai/controllers/settings_controller.dart';
import 'package:bugpilot_ai/repositories/hive_bug_repository.dart';
import 'package:bugpilot_ai/repositories/persistent_settings_repository.dart';
import 'bug_attachment_storage.dart';
import 'local_data_security.dart';

class AccountData {
  AccountData._(
    this.reports,
    this.settings,
    this._settingsRepository,
    this.directory,
    this.uid,
  );
  final HiveBugRepository reports;
  final SettingsController settings;
  final PersistentSettingsRepository _settingsRepository;
  final Directory directory;
  final String uid;

  static Future<AccountData> open(String uid, List<int> key) async {
    final namespace = LocalDataSecurity.accountNamespace(uid);
    final base = await getApplicationSupportDirectory();
    final directory = Directory(p.join(base.path, 'accounts', namespace));
    await directory.create(recursive: true);
    final reports = await HiveBugRepository.create(
      accountNamespace: namespace,
      encryptionKey: key,
      attachmentStorage: BugAttachmentStorage(
        baseDirectoryProvider: () async => directory,
      ),
    );
    final repository = await PersistentSettingsRepository.create(
      accountNamespace: namespace,
      encryptionKey: key,
    );
    return AccountData._(
      reports,
      SettingsController(
        repository: repository,
        initialSettings: await repository.load(),
      ),
      repository,
      directory,
      uid,
    );
  }

  Future<void> deleteAll() async {
    if (await LocalDataSecurity.ownsLegacyData(uid) &&
        await Hive.boxExists(HiveBugRepository.bugReportsBoxName)) {
      final legacy = await HiveBugRepository.create();
      await legacy.deleteAll();
    }
    await reports.deleteAll();
    await _settingsRepository.reset();
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  /// Older installations had one shared database. Never silently claim it for
  /// whichever account signs in next. Import is an explicit user decision.
  Future<bool> hasLegacyReports() async {
    if (!await LocalDataSecurity.ownsLegacyData(uid)) return false;
    if (!await Hive.boxExists(HiveBugRepository.bugReportsBoxName)) {
      return false;
    }
    final legacy = await HiveBugRepository.create();
    return (await legacy.getBugs()).isNotEmpty;
  }

  Future<void> importLegacyReports() async {
    if (!await LocalDataSecurity.ownsLegacyData(uid)) {
      throw StateError('Legacy data belongs to another session');
    }
    final legacy = await HiveBugRepository.create();
    final old = await legacy.getBugs();
    for (final bug in old) {
      if (await reports.getBugById(bug.id) == null) {
        await reports.createBug(bug);
      }
    }
    // Only remove each legacy original after all copies have succeeded.
    for (final bug in old) {
      await legacy.deleteBug(bug.id);
    }
  }
}
