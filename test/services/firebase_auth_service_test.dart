import 'dart:async';
import 'dart:io';

import 'package:bugpilot_ai/app/app.dart';
import 'package:bugpilot_ai/widgets/bugpilot_components.dart';
import 'package:bugpilot_ai/models/auth_user.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bugpilot_ai/services/firebase_auth_service.dart';
import 'package:bugpilot_ai/services/profile_photo_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await rootBundle.loadString('assets/translations/en.json');
    await EasyLocalization.ensureInitialized();
  });

  testWidgets(
    'avatar refreshes after saving and returning to the same account',
    (tester) async {
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('avatar_session_'),
      ))!;
      Hive.init(directory.path);
      final photos = (await tester.runAsync(ProfilePhotoStorage.create))!;
      final auth = _Auth();
      final service = FirebaseAuthService(photoStorage: photos, auth: auth);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await auth.events.close();
        await tester.runAsync(() async {
          await Hive.close();
          await directory.delete(recursive: true);
        });
      });
      await tester.pumpWidget(
        BugPilotApp(
          authService: service,
          requireAuthentication: true,
          initialLocale: const Locale('en'),
          saveLocale: false,
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      final data = (await tester.runAsync(
        () => rootBundle.load(bugPilotLogoAsset),
      ))!;
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await tester.runAsync(
        () => service.updateProfile(
          firstName: 'Test',
          lastName: 'User',
          photoBytes: bytes,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CircleAvatar>(find.byType(CircleAvatar).first)
            .backgroundImage,
        isA<MemoryImage>(),
      );
      await service.signOut();
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
      await service.signInWithEmail(
        email: 'test@example.com',
        password: 'test-password',
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CircleAvatar>(find.byType(CircleAvatar).first)
            .backgroundImage,
        isA<MemoryImage>(),
      );
    },
  );

  test(
    'saved photo is emitted locally and restored after sign-out and sign-in',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'profile_session_',
      );
      Hive.init(directory.path);
      final photos = await ProfilePhotoStorage.create();
      final auth = _Auth();
      final service = FirebaseAuthService(photoStorage: photos, auth: auth);
      final events = StreamIterator<AuthUser?>(service.userChanges);
      try {
        expect(await events.moveNext(), isTrue);
        expect(events.current?.localPhotoBytes, isNull);

        final savedEvent = events.moveNext();
        await service.updateProfile(
          firstName: 'Test',
          lastName: 'User',
          photoBytes: Uint8List.fromList([1, 2, 3]),
        );
        expect(await savedEvent, isTrue);
        expect(events.current?.localPhotoBytes, [1, 2, 3]);

        final signedOutEvent = events.moveNext();
        await service.signOut();
        expect(await signedOutEvent, isTrue);
        expect(events.current, isNull);

        final signedInEvent = events.moveNext();
        await service.signInWithEmail(
          email: 'test@example.com',
          password: 'test-password',
        );
        expect(await signedInEvent, isTrue);
        expect(events.current?.localPhotoBytes, [1, 2, 3]);
        expect(service.currentUser?.localPhotoBytes, [1, 2, 3]);

        await events.cancel();
        await Hive.close();
        Hive.init(directory.path);
        final reopened = await ProfilePhotoStorage.create();
        final restartedService = FirebaseAuthService(
          photoStorage: reopened,
          auth: auth,
        );
        expect(restartedService.currentUser?.localPhotoBytes, [1, 2, 3]);
      } finally {
        await events.cancel();
        await auth.events.close();
        await Hive.close();
        await directory.delete(recursive: true);
      }
    },
  );
}

class _Auth extends Fake implements firebase.FirebaseAuth {
  final events = StreamController<firebase.User?>.broadcast();
  firebase.User? user = _User();

  @override
  firebase.User? get currentUser => user;

  @override
  Stream<firebase.User?> userChanges() async* {
    yield user;
    yield* events.stream;
  }

  @override
  Future<void> signOut() async {
    user = null;
    events.add(null);
  }

  @override
  Future<firebase.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    user = _User();
    events.add(user);
    return _Credential();
  }
}

class _User extends Fake implements firebase.User {
  @override
  String get uid => 'test-user';
  @override
  bool get emailVerified => true;
  @override
  List<firebase.UserInfo> get providerData => [];
  @override
  String get email => 'test@example.com';
  @override
  String get displayName => 'Test User';
  @override
  String? get photoURL => null;
}

class _Credential extends Fake implements firebase.UserCredential {}
