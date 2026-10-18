import 'package:flutter/material.dart';

import 'package:bugpilot_ai/utils/localization_extensions.dart';
import 'package:bugpilot_ai/theme/app_theme.dart';
import 'package:bugpilot_ai/constants/app_dimensions.dart';
import 'package:bugpilot_ai/models/bug_status.dart';

class BugStatusChip extends StatelessWidget {
  const BugStatusChip({required this.status, super.key});

  final BugStatus status;

  @override
  Widget build(BuildContext context) {
    final color = bugStatusColor(status);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSmall,
          vertical: AppDimensions.spacingXSmall,
        ),
        child: Text(
          context.l10n.statusLabel(status).toUpperCase(),
          style: TextStyle(
            color: color,
            fontFamily: AppTheme.uiFontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

Color bugStatusColor(BugStatus status) {
  return switch (status) {
    BugStatus.open => AppTheme.primary,
    BugStatus.inProgress => Colors.amber.shade800,
    BugStatus.resolved => Colors.green.shade700,
    BugStatus.closed => Colors.blueGrey.shade600,
  };
}
