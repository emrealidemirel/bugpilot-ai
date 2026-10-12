import 'package:bugpilot_ai/features/bug_reports/data/storage/screenshot_image_picker.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/models/bug_screenshot.dart';
import 'package:bugpilot_ai/features/report_bug/presentation/widgets/screenshot_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    return MaterialApp(
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
    );
  }
}

class _FakeScreenshotPicker implements ScreenshotImagePicker {
  const _FakeScreenshotPicker(this.screenshot);

  final BugScreenshot? screenshot;

  @override
  Future<BugScreenshot?> pickScreenshot() async => screenshot;
}
