import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../bug_reports/domain/enums/bug_priority.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({required this.priority, super.key});

  final BugPriority? priority;

  @override
  Widget build(BuildContext context) {
    final label = priority?.label ?? 'Unprioritized';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primary.withAlpha(60)
            : AppTheme.primaryContainer.withAlpha(51),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSmall,
          vertical: AppDimensions.spacingXSmall,
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isDark ? const Color(0xFFC0C1FF) : AppTheme.primary,
            fontFamily: AppTheme.uiFontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 16 / 12,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
