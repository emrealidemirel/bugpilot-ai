import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

import 'package:bugpilot_ai/repositories/hive_bug_repository.dart';
import 'package:bugpilot_ai/models/app_settings.dart';
import 'package:bugpilot_ai/repositories/settings_repository.dart';

class PersistentSettingsRepository implements SettingsRepository {
  factory PersistentSettingsRepository({required Box<dynamic> metadataBox}) {
    return PersistentSettingsRepository._(metadataBox);
  }

  const PersistentSettingsRepository._(this._metadataBox);

  static const settingsKey = 'appSettings';

  final Box<dynamic> _metadataBox;

  static Future<PersistentSettingsRepository> create({
    String? accountNamespace,
    List<int>? encryptionKey,
  }) async {
    final metadataBox = await Hive.openBox<dynamic>(
      '${HiveBugRepository.metadataBoxName}${accountNamespace == null ? '' : '_$accountNamespace'}',
      encryptionCipher: encryptionKey == null
          ? null
          : HiveAesCipher(encryptionKey),
    );
    return PersistentSettingsRepository(metadataBox: metadataBox);
  }

  @override
  Future<AppSettings> load() async {
    final value = _metadataBox.get(settingsKey);
    if (value == null) {
      return AppSettings.defaults;
    }

    try {
      if (value is Map<String, dynamic>) {
        return AppSettings.fromJson(value);
      }
      if (value is Map) {
        return AppSettings.fromJson(_fromStorageMap(value));
      }
    } on Object catch (error) {
      debugPrint('Could not load app settings, using defaults: $error');
    }

    return AppSettings.defaults;
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _metadataBox.put(settingsKey, settings.toJson());
  }

  @override
  Future<void> reset() async {
    await save(AppSettings.defaults);
  }
}

Map<String, dynamic> _fromStorageMap(Map<dynamic, dynamic> source) {
  final result = <String, dynamic>{};
  for (final entry in source.entries) {
    final key = entry.key;
    if (key is String) {
      result[key] = entry.value;
    }
  }
  return result;
}
