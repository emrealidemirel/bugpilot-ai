import 'dart:io';
import 'dart:typed_data';

import 'package:bugpilot_ai/services/firebase_auth_service.dart';
import 'package:bugpilot_ai/services/local_data_security.dart';
import 'package:bugpilot_ai/services/profile_photo_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ProfilePhotoStorage photos;
  late _User user;
  late FirebaseAuthService service;
  late List<String> operations;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('account_security_');
    Hive.init(directory.path);
    photos = await ProfilePhotoStorage.create();
    await photos.save('user', Uint8List.fromList([1, 2, 3]));
    operations = [];
    user = _User(operations);
    service = FirebaseAuthService(photoStorage: photos, auth: _Auth(user));
    service.deleteLocalData = (_) async => operations.add('cleanup');
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'storage key survives restart and legacy ownership cannot change',
    () async {
      expect(
        await LocalDataSecurity.encryptionKey(),
        await LocalDataSecurity.encryptionKey(),
      );
      await LocalDataSecurity.bindLegacyOwner('alice');
      await LocalDataSecurity.bindLegacyOwner('bob');
      expect(await LocalDataSecurity.ownsLegacyData('alice'), isTrue);
      expect(await LocalDataSecurity.ownsLegacyData('bob'), isFalse);
    },
  );
  test('signed-out legacy data is not claimed by a later login', () async {
    await LocalDataSecurity.bindLegacyOwner(null);
    await LocalDataSecurity.bindLegacyOwner('alice');
    expect(await LocalDataSecurity.ownsLegacyData('alice'), isFalse);
  });
  test('failed reauthentication preserves all local data', () async {
    user.failAuthentication = true;
    await expectLater(
      service.deleteAccount(password: 'password'),
      throwsStateError,
    );
    expect(operations, ['reauthenticate']);
    expect(photos.read('user'), [1, 2, 3]);
    expect(await LocalDataSecurity.pendingDeletion(), isNull);
  });
  test(
    'failed remote deletion preserves local data and clears the journal',
    () async {
      user.failDeletion = true;
      await expectLater(
        service.deleteAccount(password: 'password'),
        throwsStateError,
      );
      expect(operations, ['reauthenticate', 'delete']);
      expect(photos.read('user'), [1, 2, 3]);
      expect(await LocalDataSecurity.pendingDeletion(), isNull);
    },
  );
  test(
    'successful deletion reauthenticates then removes remote and local data',
    () async {
      await service.deleteAccount(password: 'password');
      expect(operations, ['reauthenticate', 'delete', 'cleanup']);
      expect(photos.read('user'), isNull);
      expect(await LocalDataSecurity.pendingDeletion(), isNull);
    },
  );
  test('failed local cleanup remains journaled for startup retry', () async {
    service.deleteLocalData = (_) async =>
        throw StateError('storage unavailable');
    await expectLater(
      service.deleteAccount(password: 'password'),
      throwsStateError,
    );
    expect(await LocalDataSecurity.pendingDeletion(), 'user');
  });
}

class _Auth extends Fake implements firebase.FirebaseAuth {
  _Auth(this.user);
  final _User user;
  @override
  firebase.User get currentUser => user;
}

class _User extends Fake implements firebase.User {
  _User(this.operations);
  final List<String> operations;
  bool failAuthentication = false;
  bool failDeletion = false;
  @override
  String get uid => 'user';
  @override
  String get email => 'user@example.com';
  @override
  List<firebase.UserInfo> get providerData => [_PasswordProvider()];
  @override
  Future<firebase.UserCredential> reauthenticateWithCredential(
    firebase.AuthCredential credential,
  ) async {
    operations.add('reauthenticate');
    if (failAuthentication) throw StateError('authentication failed');
    return _Credential();
  }

  @override
  Future<void> delete() async {
    operations.add('delete');
    if (failDeletion) throw StateError('network unavailable');
  }
}

class _Credential extends Fake implements firebase.UserCredential {}

class _PasswordProvider extends Fake implements firebase.UserInfo {
  @override
  String get providerId => "password";
}
