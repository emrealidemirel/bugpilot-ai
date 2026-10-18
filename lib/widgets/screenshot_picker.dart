import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:bugpilot_ai/theme/app_theme.dart';
import 'package:bugpilot_ai/constants/app_dimensions.dart';
import 'package:bugpilot_ai/services/bug_screenshot_validator.dart';
import 'package:bugpilot_ai/services/screenshot_image_picker.dart';
import 'package:bugpilot_ai/models/bug_screenshot_constraints.dart';
import 'package:bugpilot_ai/models/bug_screenshot.dart';

class ScreenshotPicker extends StatelessWidget {
  ScreenshotPicker({
    required this.screenshot,
    required this.onChanged,
    this.enabled = true,
    ScreenshotImagePicker? picker,
    super.key,
  }) : picker = picker ?? ImagePickerScreenshotPicker();

  final BugScreenshot? screenshot;
  final ValueChanged<BugScreenshot?> onChanged;
  final bool enabled;
  final ScreenshotImagePicker picker;

  @override
  Widget build(BuildContext context) {
    final selected = screenshot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'screenshotAttachDescription'.tr(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        if (selected == null)
          _EmptyScreenshotState(enabled: enabled, onTap: () => _pick(context))
        else
          _ScreenshotPreview(
            screenshot: selected,
            enabled: enabled,
            onReplace: () => _pick(context),
            onRemove: () => onChanged(null),
          ),
        const SizedBox(height: AppDimensions.spacingSmall),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppDimensions.spacingSmall),
            Expanded(
              child: Text(
                'screenshotPrivacyNote'.tr(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    try {
      final picked = await picker.pickScreenshot();
      if (picked != null) {
        onChanged(picked);
      }
    } on BugScreenshotValidationException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message == BugScreenshotConstraints.tooLargeMessage
                ? 'screenshotTooLarge'.tr()
                : 'screenshotUnsupportedFormat'.tr(),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } on Object {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('screenshotSelectError'.tr()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _EmptyScreenshotState extends StatelessWidget {
  const _EmptyScreenshotState({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: colorScheme.outlineVariant,
          radius: AppDimensions.radiusMedium,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingLarge),
            child: Row(
              children: [
                Icon(
                  Icons.image_outlined,
                  color: enabled
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppDimensions.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'addScreenshotAction'.tr(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppTheme.textPrimaryFor(context)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PNG or JPEG',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.add_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScreenshotPreview extends StatelessWidget {
  const _ScreenshotPreview({
    required this.screenshot,
    required this.enabled,
    required this.onReplace,
    required this.onRemove,
  });

  final BugScreenshot screenshot;
  final bool enabled;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingSmall),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.spacingSmall),
              child: SizedBox(
                width: 96,
                height: 72,
                child: _ScreenshotImage(path: screenshot.localPath),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    screenshot.fileName ?? 'selectedScreenshot'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (screenshot.sizeBytes != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatSize(screenshot.sizeBytes!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: AppDimensions.spacingSmall),
                  Wrap(
                    spacing: AppDimensions.spacingSmall,
                    children: [
                      TextButton.icon(
                        onPressed: enabled ? onReplace : null,
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: Text('replaceAction'.tr()),
                      ),
                      TextButton.icon(
                        onPressed: enabled ? onRemove : null,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text('removeAction'.tr()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb >= 1) {
      return '${mb.toStringAsFixed(1)} MB';
    }

    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(0)} KB';
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 8), paint);
        distance += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color || radius != oldDelegate.radius;
  }
}

class _ScreenshotImage extends StatelessWidget {
  const _ScreenshotImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(path, fit: BoxFit.cover);
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(child: Icon(Icons.broken_image_outlined)),
        );
      },
    );
  }
}
