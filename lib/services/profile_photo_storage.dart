import 'dart:typed_data';

import 'package:hive_ce/hive_ce.dart';

class ProfilePhotoStorage {
  ProfilePhotoStorage._(this._box);

  final Box<Uint8List> _box;

  static Future<ProfilePhotoStorage> create({List<int>? encryptionKey}) async {
    if (encryptionKey == null) {
      return ProfilePhotoStorage._(
        await Hive.openBox<Uint8List>('profile_photos'),
      );
    }
    final encrypted = await Hive.openBox<Uint8List>(
      'profile_photos_encrypted',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    if (await Hive.boxExists('profile_photos')) {
      final legacy = await Hive.openBox<Uint8List>('profile_photos');
      for (final uid in legacy.keys) {
        if (!encrypted.containsKey(uid)) {
          await encrypted.put(uid, legacy.get(uid)!);
        }
      }
      await encrypted.flush();
      await legacy.deleteFromDisk();
    }
    return ProfilePhotoStorage._(encrypted);
  }

  Future<void> delete(String userId) async {
    await _box.delete(userId);
    await _box.flush();
  }

  Uint8List? read(String userId) => _box.get(userId);

  Stream<String> get changes =>
      _box.watch().map((event) => event.key as String);

  Future<void> save(String userId, Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length >= 5 * 1024 * 1024) {
      throw ArgumentError('Profile photos must be nonempty and below 5 MB.');
    }
    await _box.put(userId, Uint8List.fromList(bytes));
    await _box.flush();
  }
}
