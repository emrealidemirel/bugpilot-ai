import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:bugpilot_ai/models/bug_screenshot.dart';
import 'bug_screenshot_validator.dart';

typedef AttachmentDirectoryProvider = Future<Directory> Function();

class BugAttachmentStorage {
  BugAttachmentStorage({
    AttachmentDirectoryProvider? baseDirectoryProvider,
    this._validator = const BugScreenshotValidator(),
  }) : _baseDirectoryProvider =
           baseDirectoryProvider ?? getApplicationDocumentsDirectory;

  final AttachmentDirectoryProvider _baseDirectoryProvider;
  final BugScreenshotValidator _validator;

  Future<BugScreenshot> persistScreenshot({
    required BugScreenshot screenshot,
    required String bugId,
  }) async {
    final source = File(screenshot.localPath);
    if (!await source.exists()) {
      throw FileSystemException(
        'Selected screenshot no longer exists.',
        screenshot.localPath,
      );
    }

    final sizeBytes = await source.length();
    _validator.validate(
      path: screenshot.localPath,
      mimeType: screenshot.mimeType,
      sizeBytes: sizeBytes,
    );

    final directory = await _screenshotDirectory();
    if (_isInsideDirectory(source.path, directory.path)) {
      return BugScreenshot(
        id: screenshot.id,
        localPath: source.path,
        fileName: screenshot.fileName,
        mimeType: screenshot.mimeType,
        sizeBytes: sizeBytes,
      );
    }

    await directory.create(recursive: true);
    final target = File(
      p.join(
        directory.path,
        '${_sanitizeFilePart(bugId)}-${_sanitizeFilePart(screenshot.id)}'
        '${_extensionFor(screenshot.mimeType)}',
      ),
    );
    final copied = await source.copy(await _uniquePathFor(target));

    return BugScreenshot(
      id: screenshot.id,
      localPath: copied.path,
      fileName: screenshot.fileName ?? p.basename(copied.path),
      mimeType: screenshot.mimeType,
      sizeBytes: await copied.length(),
    );
  }

  Future<void> deleteScreenshot(BugScreenshot? screenshot) async {
    if (screenshot == null) {
      return;
    }

    try {
      final file = File(screenshot.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      // Attachment cleanup should never block the bug report operation.
    }
  }

  Future<bool> screenshotExists(BugScreenshot screenshot) {
    return File(screenshot.localPath).exists();
  }

  Future<Directory> _screenshotDirectory() async {
    final base = await _baseDirectoryProvider();
    return Directory(p.join(base.path, 'bugpilot', 'screenshots'));
  }

  bool _isInsideDirectory(String filePath, String directoryPath) {
    final normalizedFile = p.normalize(p.absolute(filePath));
    final normalizedDirectory = p.normalize(p.absolute(directoryPath));
    return p.isWithin(normalizedDirectory, normalizedFile);
  }

  Future<String> _uniquePathFor(File target) async {
    if (!await target.exists()) {
      return target.path;
    }

    final extension = p.extension(target.path);
    final baseName = p.basenameWithoutExtension(target.path);
    final directory = p.dirname(target.path);
    var index = 2;
    while (true) {
      final candidate = p.join(directory, '$baseName-$index$extension');
      if (!await File(candidate).exists()) {
        return candidate;
      }
      index += 1;
    }
  }

  String _extensionFor(String mimeType) {
    return switch (mimeType) {
      'image/jpeg' => '.jpg',
      'image/png' => '.png',
      _ => '.img',
    };
  }

  String _sanitizeFilePart(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');
  }
}
