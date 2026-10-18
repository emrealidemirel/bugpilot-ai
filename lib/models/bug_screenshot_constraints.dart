abstract final class BugScreenshotConstraints {
  static const int maxSizeBytes = 5 * 1024 * 1024;
  static const Set<String> supportedMimeTypes = {'image/jpeg', 'image/png'};
  static const Set<String> supportedExtensions = {'.jpg', '.jpeg', '.png'};

  static const String tooLargeMessage =
      'Screenshot is too large. Please choose an image smaller than 5 MB.';
  static const String unsupportedFormatMessage =
      'This screenshot format is not supported.';
}
