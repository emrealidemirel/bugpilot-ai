import 'dart:io';

import 'package:bugpilot_ai/features/bug_reports/data/repositories/hive_bug_repository.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_platform.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_status.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/models/bug_report.dart';
import 'package:bugpilot_ai/features/settings/data/repositories/persistent_settings_repository.dart';
import 'package:bugpilot_ai/features/settings/domain/models/app_settings.dart';
import 'package:bugpilot_ai/features/settings/domain/models/app_theme_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bugpilot_settings_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PersistentSettingsRepository', () {
    test('loads defaults when settings have not been saved', () async {
      final repository = await PersistentSettingsRepository.create();

      expect(await repository.load(), AppSettings.defaults);
    });

    test('round-trips theme, preferences, and default environment', () async {
      var repository = await PersistentSettingsRepository.create();
      const settings = AppSettings(
        themeMode: AppThemeMode.dark,
        aiSeverityEnabled: false,
        aiPriorityEnabled: false,
        aiTestCasesEnabled: false,
        aiRootCauseEnabled: false,
        duplicateDetectionEnabled: false,
        screenshotAnalysisEnabled: false,
        defaultPlatform: BugPlatform.ios,
        defaultDevice: 'iPhone 18',
        defaultOsVersion: 'iOS 20',
        defaultAppVersion: '2.3.0',
      );

      await repository.save(settings);
      await Hive.close();
      Hive.init(tempDir.path);
      repository = await PersistentSettingsRepository.create();

      expect(await repository.load(), settings);
    });

    test('loads defaults for partial older settings JSON', () async {
      final box = await Hive.openBox<dynamic>(
        HiveBugRepository.metadataBoxName,
      );
      await box.put(PersistentSettingsRepository.settingsKey, {
        'themeMode': 'light',
        'aiSeverityEnabled': false,
      });

      final repository = await PersistentSettingsRepository.create();
      final settings = await repository.load();

      expect(settings.themeMode, AppThemeMode.light);
      expect(settings.aiSeverityEnabled, isFalse);
      expect(settings.aiPriorityEnabled, isTrue);
      expect(settings.defaultPlatform, BugPlatform.android);
    });

    test('reset restores defaults without affecting bug reports', () async {
      final bugRepository = await HiveBugRepository.create(seedBugs: []);
      await bugRepository.createBug(_bugReport());
      final settingsRepository = await PersistentSettingsRepository.create();
      await settingsRepository.save(
        const AppSettings(themeMode: AppThemeMode.dark),
      );

      await settingsRepository.reset();

      expect(await settingsRepository.load(), AppSettings.defaults);
      expect(await bugRepository.getBugs(), hasLength(1));
    });
  });
}

BugReport _bugReport() {
  return BugReport(
    id: 'bug-001',
    title: 'Saved bug',
    description: 'A saved local bug report.',
    expectedBehavior: 'It should stay saved.',
    actualBehavior: 'Settings reset should not delete it.',
    platform: BugPlatform.android,
    status: BugStatus.open,
    createdAt: DateTime.utc(2026, 8, 19),
    updatedAt: DateTime.utc(2026, 8, 19),
  );
}
