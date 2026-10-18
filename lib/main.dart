import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'package:bugpilot_ai/repositories/hive_bug_repository.dart';
import 'package:bugpilot_ai/services/firebase_auth_service.dart';
import 'package:bugpilot_ai/services/profile_photo_storage.dart';
import 'package:bugpilot_ai/constants/firebase_runtime_config.dart';
import 'package:bugpilot_ai/repositories/persistent_settings_repository.dart';
import 'package:bugpilot_ai/controllers/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Hive.initFlutter('bugpilot_ai');
  final photoStorage = await ProfilePhotoStorage.create();
  FirebaseAuthService? authService;
  final firebaseOptions = FirebaseRuntimeConfig.options;
  if (firebaseOptions != null) {
    await Firebase.initializeApp(options: firebaseOptions);
    authService = FirebaseAuthService(photoStorage: photoStorage);
  }
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
      authService: authService,
      requireAuthentication: true,
    ),
  );
}
