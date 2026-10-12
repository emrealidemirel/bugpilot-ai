import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/date_label_formatter.dart';
import '../../../../core/widgets/bugpilot_components.dart';
import '../../../dashboard/presentation/widgets/priority_badge.dart';
import '../../../dashboard/presentation/widgets/severity_badge.dart';
import '../../domain/enums/bug_platform.dart';
import '../../domain/enums/bug_severity.dart';
import '../../domain/models/bug_report.dart';
import 'bug_metadata_item.dart';
import 'bug_status_chip.dart';

class BugReportListItem extends StatelessWidget {
  const BugReportListItem({required this.bug, required this.onTap, super.key});

  final BugReport bug;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final accent = bug.severity == null
        ? Theme.of(context).colorScheme.outline
        : bug.severity!.label == 'Critical'
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return BugPilotCard(
      onTap: onTap,
      semanticAccent: accent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      bugDisplayId(bug.id),
                      style: textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingSmall),
                    BugStatusChip(status: bug.status),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingSmall),
                Text(
                  bug.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textPrimaryFor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSmall),
                Text(
                  bug.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: AppDimensions.spacingMedium),
                Wrap(
                  spacing: AppDimensions.spacingSmall,
                  runSpacing: AppDimensions.spacingSmall,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SeverityBadge(severity: bug.severity),
                    PriorityBadge(priority: bug.priority),
                    BugMetadataItem(
                      icon: bugPlatformIcon(bug.platform),
                      label: bug.platform.label,
                    ),
                    BugMetadataItem(
                      icon: Icons.calendar_today_outlined,
                      label: formatRecentDateLabel(bug.createdAt),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSmall),
          Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textSecondaryFor(context),
          ),
        ],
      ),
    );
  }
}
