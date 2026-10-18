import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:bugpilot_ai/utils/localization_extensions.dart';
import 'package:bugpilot_ai/theme/app_theme.dart';
import 'package:bugpilot_ai/constants/app_dimensions.dart';
import 'package:bugpilot_ai/utils/date_label_formatter.dart';
import 'package:bugpilot_ai/widgets/bugpilot_components.dart';
import 'package:bugpilot_ai/widgets/priority_badge.dart';
import 'package:bugpilot_ai/widgets/severity_badge.dart';
import 'package:bugpilot_ai/models/bug_severity.dart';
import 'package:bugpilot_ai/models/bug_report.dart';
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
        : bug.severity == BugSeverity.critical
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return BugPilotCard(
      onTap: onTap,
      semanticAccent: accent,
      padding: const EdgeInsets.all(20),
      radius: AppDimensions.radiusDashboardCard,
      shadow: false,
      borderColor: Theme.of(context).colorScheme.outlineVariant.withAlpha(100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: BugStatusChip(status: bug.status),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondaryFor(context),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Text(
            bug.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            bug.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: AppDimensions.spacingLarge),
          Wrap(
            spacing: AppDimensions.spacingSmall,
            runSpacing: AppDimensions.spacingSmall,
            children: [
              SeverityBadge(severity: bug.severity),
              PriorityBadge(priority: bug.priority),
            ],
          ),
          const Divider(height: 32),
          Wrap(
            spacing: AppDimensions.spacingLarge,
            runSpacing: AppDimensions.spacingSmall,
            children: [
              BugMetadataItem(
                icon: bugPlatformIcon(bug.platform),
                label: context.l10n.localizedPlatformLabel(bug.platform),
              ),
              BugMetadataItem(
                icon: Icons.calendar_today_outlined,
                label: formatRecentDateLabel(
                  bug.createdAt,
                  localeCode: Localizations.localeOf(context).languageCode,
                  todayLabel: 'todayLabel'.tr(),
                  yesterdayLabel: 'yesterdayLabel'.tr(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
