import 'package:bugpilot_ai/app/app.dart';
import 'package:bugpilot_ai/models/auth_user.dart';
import 'package:bugpilot_ai/services/auth_service.dart';
import 'package:bugpilot_ai/widgets/bugpilot_components.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await rootBundle.loadString('assets/translations/en.json');
    await rootBundle.loadString('assets/translations/tr.json');
    await EasyLocalization.ensureInitialized();
  });

  Future<void> openSignIn(WidgetTester tester, Object error) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      BugPilotApp(
        initialLocale: const Locale('en'),
        saveLocale: false,
        requireAuthentication: true,
        authService: _FailingAuthService(error),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  for (final code in ['keychain-error', 'unexpected-auth-code']) {
    testWidgets('explains $code instead of hiding it', (tester) async {
      await openSignIn(tester, FirebaseAuthException(code: code));
      expect(find.byType(BugPilotLogoMark), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'test-password');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          code == 'keychain-error'
              ? 'The app could not securely save your session on this device. Install the updated app and try again.'
              : 'Sign-in could not be completed. Error code: unexpected-auth-code.',
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets(
    'canceling Google sign-in leaves the form usable without an error',
    (tester) async {
      await openSignIn(
        tester,
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      );
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(
        find.text('Sign-in could not be completed. Please try again.'),
        findsNothing,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    },
  );
}

class _FailingAuthService extends Fake implements AuthService {
  _FailingAuthService(this.error);
  final Object error;

  @override
  AuthUser? get currentUser => null;

  @override
  Stream<AuthUser?> get userChanges => const Stream.empty();

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async => throw error;

  @override
  Future<void> signInWithGoogle() async => throw error;
}
