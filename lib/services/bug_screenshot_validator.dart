import 'package:path/path.dart' as p;

import 'package:bugpilot_ai/models/bug_screenshot_constraints.dart';

class BugScreenshotValidationException implements Exception {
  const BugScreenshotValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BugScreenshotValidator {
  const BugScreenshotValidator();

  void validate({
    required String path,
    required String mimeType,
    int? sizeBytes,
  }) {
    if (!BugScreenshotConstraints.supportedMimeTypes.contains(mimeType)) {
      throw const BugScreenshotValidationException(
        BugScreenshotConstraints.unsupportedFormatMessage,
      );
    }

    final extension = p.extension(path).toLowerCase();
    if (!BugScreenshotConstraints.supportedExtensions.contains(extension)) {
      throw const BugScreenshotValidationException(
        BugScreenshotConstraints.unsupportedFormatMessage,
      );
    }

    if (sizeBytes != null &&
        sizeBytes > BugScreenshotConstraints.maxSizeBytes) {
      throw const BugScreenshotValidationException(
        BugScreenshotConstraints.tooLargeMessage,
      );
    }
  }
}
