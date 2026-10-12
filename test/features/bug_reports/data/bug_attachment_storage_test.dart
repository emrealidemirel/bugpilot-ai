import 'dart:io';

import 'package:bugpilot_ai/features/bug_reports/data/storage/bug_attachment_storage.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/models/bug_screenshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late BugAttachmentStorage storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'bugpilot_attachment_test_',
    );
    storage = BugAttachmentStorage(baseDirectoryProvider: () async => tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('persists screenshot copies into app-owned storage', () async {
    final source = await writePng(tempDir, 'source.png');

    final persisted = await storage.persistScreenshot(
      screenshot: _screenshot(source.path),
      bugId: 'bug-001',
    );

    expect(persisted.localPath, isNot(source.path));
    expect(await File(persisted.localPath).exists(), isTrue);
    expect(p.dirname(persisted.localPath), contains('screenshots'));
  });

  test(
    'delete screenshot handles existing and nonexistent files safely',
    () async {
      final source = await writePng(tempDir, 'delete.png');
      final persisted = await storage.persistScreenshot(
        screenshot: _screenshot(source.path),
        bugId: 'bug-001',
      );

      await storage.deleteScreenshot(persisted);
      await storage.deleteScreenshot(persisted);

      expect(await File(persisted.localPath).exists(), isFalse);
    },
  );

  test('unique names do not collide', () async {
    final firstSource = await writePng(tempDir, 'first.png');
    final secondSource = await writePng(tempDir, 'second.png');

    final first = await storage.persistScreenshot(
      screenshot: _screenshot(firstSource.path),
      bugId: 'bug-001',
    );
    final second = await storage.persistScreenshot(
      screenshot: _screenshot(secondSource.path),
      bugId: 'bug-001',
    );

    expect(first.localPath, isNot(second.localPath));
    expect(await File(first.localPath).exists(), isTrue);
    expect(await File(second.localPath).exists(), isTrue);
  });
}

Future<File> writePng(Directory directory, String name) async {
  final file = File(p.join(directory.path, name));
  return file.writeAsBytes(List<int>.filled(32, 1));
}

BugScreenshot _screenshot(String path) {
  return BugScreenshot(
    id: 'shot-001',
    localPath: path,
    fileName: p.basename(path),
    mimeType: 'image/png',
    sizeBytes: 32,
  );
}
