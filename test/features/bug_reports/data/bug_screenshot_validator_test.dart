import 'package:bugpilot_ai/services/bug_screenshot_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BugScreenshotValidator', () {
    const validator = BugScreenshotValidator();

    test('accepts valid JPEG and PNG screenshots', () {
      expect(
        () => validator.validate(
          path: '/tmp/screenshot.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 1024,
        ),
        returnsNormally,
      );
      expect(
        () => validator.validate(
          path: '/tmp/screenshot.png',
          mimeType: 'image/png',
          sizeBytes: 1024,
        ),
        returnsNormally,
      );
    });

    test('rejects oversized screenshots', () {
      expect(
        () => validator.validate(
          path: '/tmp/screenshot.png',
          mimeType: 'image/png',
          sizeBytes: 5 * 1024 * 1024 + 1,
        ),
        throwsA(isA<BugScreenshotValidationException>()),
      );
    });

    test('rejects unsupported MIME types and extensions', () {
      expect(
        () => validator.validate(
          path: '/tmp/screenshot.gif',
          mimeType: 'image/gif',
          sizeBytes: 1024,
        ),
        throwsA(isA<BugScreenshotValidationException>()),
      );
      expect(
        () => validator.validate(
          path: '/tmp/screenshot.svg',
          mimeType: 'image/png',
          sizeBytes: 1024,
        ),
        throwsA(isA<BugScreenshotValidationException>()),
      );
    });
  });
}
