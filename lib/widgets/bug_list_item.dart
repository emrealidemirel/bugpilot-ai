import 'package:flutter/material.dart';

import 'package:bugpilot_ai/utils/localization_extensions.dart';
import 'package:bugpilot_ai/theme/app_theme.dart';
import 'package:bugpilot_ai/constants/app_dimensions.dart';
import 'package:bugpilot_ai/widgets/bugpilot_components.dart';
import 'package:bugpilot_ai/models/bug_platform.dart';
import 'package:bugpilot_ai/models/bug_priority.dart';
import 'package:bugpilot_ai/models/bug_severity.dart';
import 'package:bugpilot_ai/models/bug_status.dart';
import 'package:bugpilot_ai/widgets/bug_metadata_item.dart';
import 'priority_badge.dart';
import 'severity_badge.dart';

class BugListItem extends StatelessWidget {
  const BugListItem({
    required this.onTap,
    required this.title,
    required this.severity,
    required this.priority,
    required this.platform,
    required this.status,
    required this.date,
    super.key,
  });

  final VoidCallback onTap;
  final String title;
  final BugSeverity? severity;
  final BugPriority? priority;
  final BugPlatform platform;
  final BugStatus status;
  final String date;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isResolved = status == BugStatus.resolved;

    return BugPilotCard(
      onTap: onTap,
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderColor: Theme.of(context).colorScheme.outlineVariant.withAlpha(77),
      radius: AppDimensions.radiusDashboardCard,
      padding: const EdgeInsets.all(14),
      child: Opacity(
        opacity: isResolved ? 0.75 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall?.copyWith(
                color: isResolved
                    ? AppTheme.outline
                    : AppTheme.textPrimaryFor(context),
                decoration: isResolved
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: AppTheme.outline,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 24 / 16,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            Wrap(
              spacing: AppDimensions.spacingSmall,
              runSpacing: AppDimensions.spacingXSmall,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SeverityBadge(severity: severity),
                PriorityBadge(priority: priority),
                _PlatformBadge(platform: platform),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withAlpha(51),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppDimensions.spacingMedium,
                ),
                child: Row(
                  children: [
                    _StatusIndicator(status: status),
                    const SizedBox(width: AppDimensions.spacingSmall),
                    Text(
                      context.l10n.statusLabel(status),
                      style: textTheme.bodyMedium?.copyWith(
                        color: _statusTextColor(context, status),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      date,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppTheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  const _PlatformBadge({required this.platform});

  final BugPlatform platform;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSmall,
          vertical: AppDimensions.spacingXSmall,
        ),
        child: BugMetadataItem(
          icon: bugPlatformIcon(platform),
          label: context.l10n.localizedPlatformLabel(platform),
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.status});

  final BugStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == BugStatus.resolved) {
      return Icon(
        Icons.check_circle_outline,
        color: _statusColor(status),
        size: 16,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _statusColor(status),
        shape: BoxShape.circle,
      ),
      child: const SizedBox.square(dimension: 8),
    );
  }
}

Color _statusColor(BugStatus status) {
  return switch (status) {
    BugStatus.open => AppTheme.primary,
    BugStatus.inProgress => AppTheme.border,
    BugStatus.resolved => AppTheme.onSecondaryContainer,
    BugStatus.closed => AppTheme.outline,
  };
}

Color _statusTextColor(BuildContext context, BugStatus status) {
  return switch (status) {
    BugStatus.resolved => Theme.of(context).colorScheme.secondary,
    _ => AppTheme.textSecondaryFor(context),
  };
}
