import 'package:bugpilot_ai/models/auth_user.dart';
import 'package:bugpilot_ai/services/ai_consent.dart';
import 'package:bugpilot_ai/services/auth_service.dart';
import 'package:bugpilot_ai/widgets/auth_service_scope.dart';
import 'package:bugpilot_ai/widgets/privacy_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final verified in [false, true]) {
    testWidgets('AI sharing requires verified=$verified and explicit consent', (
      tester,
    ) async {
      final consent = AiConsent();
      bool? result;
      await tester.pumpWidget(
        AuthServiceScope(
          service: _Auth(),
          user: AuthUser(
            id: 'user',
            email: 'user@example.com',
            emailVerified: verified,
          ),
          aiConsent: consent,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await requestAiConsent(context);
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Run'));
      await tester.pumpAndSettle();
      if (!verified) {
        expect(find.byType(AlertDialog), findsNothing);
        expect(result, isFalse);
        expect(consent.accepted, isFalse);
        return;
      }
      expect(result, isNull);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(consent.accepted, isFalse);
      await tester.tap(find.text('Run'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(consent.accepted, isTrue);
      await tester.tap(find.text('Run'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  }
}

class _Auth extends Fake implements AuthService {}
