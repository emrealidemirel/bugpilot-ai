import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive_ce.dart';

/// Database keys live in the platform keystore, never in the database or Git.
class LocalDataSecurity {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'bugpilot.database-key.v1';

  static Future<List<int>> encryptionKey() async {
    final encoded = await _storage.read(key: _keyName);
    if (encoded != null) {
      final key = base64Decode(encoded);
      if (key.length != 32) throw StateError('Invalid local encryption key');
      return key;
    }
    final key = Hive.generateSecureKey();
    await _storage.write(key: _keyName, value: base64Encode(key));
    return key;
  }

  static Future<void> bindLegacyOwner(String? uid) async {
    const ownerKey = 'bugpilot.legacy-owner.v1';
    if (await _storage.read(key: ownerKey) == null) {
      await _storage.write(key: ownerKey, value: uid ?? '__unassigned__');
    }
  }

  static Future<bool> ownsLegacyData(String uid) async =>
      await _storage.read(key: 'bugpilot.legacy-owner.v1') == uid;

  static Future<void> markPendingDeletion(String uid) =>
      _storage.write(key: 'bugpilot.pending-deletion.v1', value: uid);

  static Future<String?> pendingDeletion() =>
      _storage.read(key: 'bugpilot.pending-deletion.v1');

  static Future<void> clearPendingDeletion() =>
      _storage.delete(key: 'bugpilot.pending-deletion.v1');

  static String accountNamespace(String uid) =>
      sha256.convert(utf8.encode(uid)).toString();
}
