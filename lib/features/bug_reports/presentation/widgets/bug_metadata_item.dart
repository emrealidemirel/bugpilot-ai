import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/enums/bug_platform.dart';

class BugMetadataItem extends StatelessWidget {
  const BugMetadataItem({
    required this.icon,
    required this.label,
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: compact ? 12 : 14,
          color: AppTheme.textSecondaryFor(context),
        ),
        const SizedBox(width: AppDimensions.spacingXSmall),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

IconData bugPlatformIcon(BugPlatform platform) {
  return switch (platform) {
    BugPlatform.android => Icons.android_rounded,
    BugPlatform.ios => Icons.phone_iphone_rounded,
    BugPlatform.web => Icons.language_rounded,
    BugPlatform.other => Icons.devices_other_rounded,
  };
}
