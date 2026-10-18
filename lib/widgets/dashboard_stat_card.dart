import 'package:flutter/material.dart';

import 'package:bugpilot_ai/theme/app_theme.dart';
import 'package:bugpilot_ai/constants/app_dimensions.dart';
import 'package:bugpilot_ai/widgets/bugpilot_components.dart';

enum DashboardStatVariant { neutral, open, critical, resolved }

class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.variant = DashboardStatVariant.neutral,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;
  final DashboardStatVariant variant;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = _colorsFor(context);

    return BugPilotCard(
      color: colors.background,
      borderColor: colors.border,
      radius: AppDimensions.radiusDashboardCard,
      padding: const EdgeInsets.all(AppDimensions.spacingLarge),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: colors.label,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSmall),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.displayLarge?.copyWith(
                      color: colors.value,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSmall),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Icon(icon, color: colors.icon, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _DashboardStatColors _colorsFor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return switch (variant) {
      DashboardStatVariant.open => _DashboardStatColors(
        background: isDark
            ? const Color(0xFF3F40C6)
            : AppTheme.primaryContainer,
        border: Colors.transparent,
        label: colorScheme.onPrimaryContainer,
        value: colorScheme.onPrimaryContainer,
        icon: colorScheme.onPrimaryContainer.withAlpha(205),
      ),
      DashboardStatVariant.critical => _DashboardStatColors(
        background: isDark ? const Color(0xFF3B2426) : AppTheme.errorContainer,
        border: Colors.transparent,
        label: isDark ? const Color(0xFFFFB4AB) : AppTheme.onErrorContainer,
        value: isDark ? const Color(0xFFFFB4AB) : AppTheme.onErrorContainer,
        icon: isDark ? const Color(0xFFFFB4AB) : AppTheme.error,
      ),
      DashboardStatVariant.resolved => _DashboardStatColors(
        background: isDark
            ? const Color(0xFF202A38)
            : AppTheme.secondaryContainer,
        border: Colors.transparent,
        label: isDark ? const Color(0xFFAEC6E4) : AppTheme.onSecondaryContainer,
        value: isDark ? const Color(0xFFAEC6E4) : AppTheme.onSecondaryContainer,
        icon: isDark
            ? const Color(0xFFAEC6E4)
            : AppTheme.onSecondaryContainer.withAlpha(205),
      ),
      DashboardStatVariant.neutral => _DashboardStatColors(
        background: colorScheme.surfaceContainerLow,
        border: Colors.transparent,
        label: AppTheme.textSecondaryFor(context),
        value: AppTheme.textPrimaryFor(context),
        icon: AppTheme.outline,
      ),
    };
  }
}

class _DashboardStatColors {
  const _DashboardStatColors({
    required this.background,
    required this.border,
    required this.label,
    required this.value,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color label;
  final Color value;
  final Color icon;
}
