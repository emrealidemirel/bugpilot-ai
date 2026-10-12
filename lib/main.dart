import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'features/bug_reports/data/repositories/hive_bug_repository.dart';
import 'features/settings/data/repositories/persistent_settings_repository.dart';
import 'features/settings/presentation/controllers/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter('bugpilot_ai');
  final bugRepository = await HiveBugRepository.create();
  final settingsRepository = await PersistentSettingsRepository.create();
  final settingsController = SettingsController(
    repository: settingsRepository,
    initialSettings: await settingsRepository.load(),
  );

  runApp(
    BugPilotApp(
      bugRepository: bugRepository,
      settingsController: settingsController,
    ),
  );
}
