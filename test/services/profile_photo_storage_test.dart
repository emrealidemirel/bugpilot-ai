import 'dart:io';
import 'dart:typed_data';

import 'package:bugpilot_ai/services/profile_photo_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('profile_photos_');
    Hive.init(directory.path);
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('photos survive reopening and stay separate for each account', () async {
    var storage = await ProfilePhotoStorage.create();
    await storage.save('alice', Uint8List.fromList([1, 2, 3]));
    await storage.save('bob', Uint8List.fromList([4, 5, 6]));
    await storage.save('alice', Uint8List.fromList([7, 8, 9]));
    await Hive.close();
    Hive.init(directory.path);
    storage = await ProfilePhotoStorage.create();

    expect(storage.read('alice'), [7, 8, 9]);
    expect(storage.read('bob'), [4, 5, 6]);
    expect(storage.read('new-user'), isNull);
  });

  test(
    'migrates photos to encrypted storage without losing other accounts',
    () async {
      final old = await ProfilePhotoStorage.create();
      await old.save('alice', Uint8List.fromList([1, 2, 3]));
      await old.save('bob', Uint8List.fromList([4, 5, 6]));
      final key = Hive.generateSecureKey();
      var encrypted = await ProfilePhotoStorage.create(encryptionKey: key);
      expect(await Hive.boxExists('profile_photos'), isFalse);
      await encrypted.delete('alice');
      await Hive.close();
      encrypted = await ProfilePhotoStorage.create(encryptionKey: key);
      expect(encrypted.read('alice'), isNull);
      expect(encrypted.read('bob'), [4, 5, 6]);
    },
  );

  test('invalid replacement preserves the saved photo', () async {
    final storage = await ProfilePhotoStorage.create();
    await storage.save('alice', Uint8List.fromList([1, 2, 3]));

    await expectLater(storage.save('alice', Uint8List(0)), throwsArgumentError);
    await expectLater(
      storage.save('alice', Uint8List(5 * 1024 * 1024)),
      throwsArgumentError,
    );
    expect(storage.read('alice'), [1, 2, 3]);
  });
}
