import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bugpilot_ai/services/screenshot_image_picker.dart';
import 'package:bugpilot_ai/models/bug_screenshot.dart';
import 'package:bugpilot_ai/widgets/screenshot_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    binding.platformDispatcher.localeTestValue = const Locale('en');
    await EasyLocalization.ensureInitialized();
  });

  testWidgets(
    'selecting valid screenshot displays preview and remove clears it',
    (tester) async {
      final picker = _FakeScreenshotPicker(
        const BugScreenshot(
          id: 'shot-001',
          localPath: '/tmp/login.png',
          fileName: 'login.png',
          mimeType: 'image/png',
          sizeBytes: 2048,
        ),
      );

      await tester.pumpWidget(_Harness(picker: picker));
      await tester.pumpAndSettle();

      expect(find.text('Add Screenshot'), findsOneWidget);
      expect(find.text('PNG or JPEG'), findsOneWidget);

      await tester.tap(find.text('Add Screenshot'));
      await tester.pump();

      expect(find.text('login.png'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);

      await tester.tap(find.text('Remove'));
      await tester.pump();

      expect(find.text('Add Screenshot'), findsOneWidget);
      expect(find.text('login.png'), findsNothing);
    },
  );
}

class _Harness extends StatefulWidget {
  const _Harness({required this.picker});

  final ScreenshotImagePicker picker;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  BugScreenshot? _screenshot;

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('tr')],
      startLocale: const Locale('en'),
      saveLocale: false,
      path: 'assets/translations',
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body: ScreenshotPicker(
              picker: widget.picker,
              screenshot: _screenshot,
              onChanged: (screenshot) {
                setState(() {
                  _screenshot = screenshot;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FakeScreenshotPicker implements ScreenshotImagePicker {
  const _FakeScreenshotPicker(this.screenshot);

  final BugScreenshot? screenshot;

  @override
  Future<BugScreenshot?> pickScreenshot() async => screenshot;
}
