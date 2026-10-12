import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../domain/models/bug_screenshot.dart';
import 'bug_screenshot_validator.dart';

abstract class ScreenshotImagePicker {
  Future<BugScreenshot?> pickScreenshot();
}

class ImagePickerScreenshotPicker implements ScreenshotImagePicker {
  ImagePickerScreenshotPicker({
    ImagePicker? imagePicker,
    this._validator = const BugScreenshotValidator(),
  }) : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;
  final BugScreenshotValidator _validator;

  @override
  Future<BugScreenshot?> pickScreenshot() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (image == null) {
      return null;
    }

    final sizeBytes = await image.length();
    final mimeType = _mimeTypeFor(image);
    _validator.validate(
      path: image.path,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
    );

    return BugScreenshot(
      id: 'screenshot-${DateTime.now().microsecondsSinceEpoch}',
      localPath: image.path,
      fileName: image.name,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
    );
  }

  String _mimeTypeFor(XFile image) {
    final mimeType = image.mimeType;
    if (mimeType != null && mimeType.trim().isNotEmpty) {
      return mimeType;
    }

    return switch (p.extension(image.path).toLowerCase()) {
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      _ => 'application/octet-stream',
    };
  }
}
