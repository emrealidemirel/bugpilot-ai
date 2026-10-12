import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository({
    AppSettings initialSettings = AppSettings.defaults,
  }) : _settings = initialSettings;

  AppSettings _settings;

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
  }

  @override
  Future<void> reset() async {
    _settings = AppSettings.defaults;
  }
}
