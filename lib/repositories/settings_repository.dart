import 'package:bugpilot_ai/models/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);

  Future<void> reset();
}
