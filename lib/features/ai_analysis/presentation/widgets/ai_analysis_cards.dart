import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/bugpilot_components.dart';
import '../../../ai_analysis/domain/models/ai_analysis_preferences.dart';
import '../../../ai_analysis/domain/models/ai_bug_analysis.dart';
import '../../../bug_reports/domain/enums/bug_test_case_type.dart';
import '../../../bug_reports/domain/models/bug_report.dart';
import '../../../bug_reports/domain/models/bug_test_case.dart';
import '../../../dashboard/presentation/widgets/priority_badge.dart';
import '../../../dashboard/presentation/widgets/severity_badge.dart';

class AnalysisSummaryCard extends StatelessWidget {
  const AnalysisSummaryCard({
    required this.analysis,
    required this.preferences,
    required this.severityEdited,
    required this.priorityEdited,
    required this.isRegeneratingSeverity,
    required this.isRegeneratingPriority,
    required this.onEditSeverity,
    required this.onEditPriority,
    required this.onRegenerateSeverity,
    required this.onRegeneratePriority,
    super.key,
  });

  final AiBugAnalysis analysis;
  final AiAnalysisPreferences preferences;
  final bool severityEdited;
  final bool priorityEdited;
  final bool isRegeneratingSeverity;
  final bool isRegeneratingPriority;
  final VoidCallback? onEditSeverity;
  final VoidCallback? onEditPriority;
  final VoidCallback? onRegenerateSeverity;
  final VoidCallback? onRegeneratePriority;

  @override
  Widget build(BuildContext context) {
    return BugPilotCard(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(
              icon: Icons.auto_awesome_rounded,
              title: 'Severity & Priority',
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            analysis.severity == null || !preferences.severity
                ? const _SkippedSuggestionRow(title: 'Severity')
                : _BadgeReasonRow(
                    title: 'Severity',
                    badge: SeverityBadge(severity: analysis.severity),
                    reason: analysis.severityReason ?? '',
                    edited: severityEdited,
                    isRegenerating: isRegeneratingSeverity,
                    onEdit: onEditSeverity,
                    onRegenerate: onRegenerateSeverity,
                    editKey: const ValueKey('ai-analysis-edit-severity'),
                    regenerateKey: const ValueKey(
                      'ai-analysis-regenerate-severity',
                    ),
                  ),
            const Divider(height: AppDimensions.spacingXLarge),
            analysis.priority == null || !preferences.priority
                ? const _SkippedSuggestionRow(title: 'Priority')
                : _BadgeReasonRow(
                    title: 'Priority',
                    badge: PriorityBadge(priority: analysis.priority),
                    reason: analysis.priorityReason ?? '',
                    edited: priorityEdited,
                    isRegenerating: isRegeneratingPriority,
                    onEdit: onEditPriority,
                    onRegenerate: onRegeneratePriority,
                    editKey: const ValueKey('ai-analysis-edit-priority'),
                    regenerateKey: const ValueKey(
                      'ai-analysis-regenerate-priority',
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _SkippedSuggestionRow extends StatelessWidget {
  const _SkippedSuggestionRow({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textPrimaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const _SourceLabel(label: 'Not generated'),
      ],
    );
  }
}

class ReproductionStepsCard extends StatelessWidget {
  const ReproductionStepsCard({
    required this.steps,
    required this.isEdited,
    required this.isRegenerating,
    required this.onEdit,
    required this.onRegenerate,
    super.key,
  });

  final List<String> steps;
  final bool isEdited;
  final bool isRegenerating;
  final VoidCallback? onEdit;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    return _AnalysisCard(
      title: 'Reproduction Steps',
      icon: Icons.format_list_numbered_rounded,
      trailing: _SectionActions(
        isEdited: isEdited,
        isRegenerating: isRegenerating,
        onEdit: onEdit,
        onRegenerate: onRegenerate,
        editKey: const ValueKey('ai-analysis-edit-reproduction-steps'),
        regenerateKey: const ValueKey(
          'ai-analysis-regenerate-reproduction-steps',
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            _NumberedStep(number: index + 1, text: steps[index]),
            if (index != steps.length - 1)
              const SizedBox(height: AppDimensions.spacingSmall),
          ],
        ],
      ),
    );
  }
}

class TestCasesCard extends StatelessWidget {
  const TestCasesCard({
    required this.testCases,
    required this.isEdited,
    required this.isRegenerating,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRegenerate,
    super.key,
  });

  final List<BugTestCase> testCases;
  final bool isEdited;
  final bool isRegenerating;
  final VoidCallback? onAdd;
  final ValueChanged<BugTestCase>? onEdit;
  final ValueChanged<BugTestCase>? onDelete;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    return _AnalysisCard(
      title: 'Test Cases',
      icon: Icons.fact_check_outlined,
      trailing: _SectionActions(
        isEdited: isEdited,
        isRegenerating: isRegenerating,
        onRegenerate: onRegenerate,
        regenerateKey: const ValueKey('ai-analysis-regenerate-test-cases'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < testCases.length; index++) ...[
            _EditableTestCaseCard(
              testCase: testCases[index],
              onEdit: onEdit == null ? null : () => onEdit!(testCases[index]),
              onDelete: onDelete == null
                  ? null
                  : () => onDelete!(testCases[index]),
            ),
            if (index != testCases.length - 1)
              const SizedBox(height: AppDimensions.spacingSmall),
          ],
          const SizedBox(height: AppDimensions.spacingMedium),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Test Case'),
            ),
          ),
        ],
      ),
    );
  }
}

class PossibleRootCauseCard extends StatelessWidget {
  const PossibleRootCauseCard({
    required this.possibleRootCause,
    required this.confidence,
    required this.isEdited,
    required this.isRegenerating,
    required this.onEdit,
    required this.onRegenerate,
    super.key,
  });

  final String possibleRootCause;
  final double? confidence;
  final bool isEdited;
  final bool isRegenerating;
  final VoidCallback? onEdit;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    final clampedConfidence = confidence?.clamp(0.0, 1.0);
    final percentage = clampedConfidence == null
        ? null
        : (clampedConfidence * 100).round();

    return BugPilotCard(
      color: Theme.of(context).colorScheme.primary.withAlpha(
        Theme.of(context).brightness == Brightness.light ? 22 : 46,
      ),
      borderColor: Theme.of(context).colorScheme.primary.withAlpha(60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionTitle(
                  icon: Icons.psychology_alt_outlined,
                  title: 'Possible Root Cause',
                ),
              ),
              _SectionActions(
                isEdited: isEdited,
                isRegenerating: isRegenerating,
                onEdit: onEdit,
                onRegenerate: onRegenerate,
                editKey: const ValueKey('ai-analysis-edit-root-cause'),
                regenerateKey: const ValueKey(
                  'ai-analysis-regenerate-root-cause',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Text(possibleRootCause, style: Theme.of(context).textTheme.bodyLarge),
          if (clampedConfidence != null && percentage != null) ...[
            const SizedBox(height: AppDimensions.spacingMedium),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(value: clampedConfidence),
                ),
                const SizedBox(width: AppDimensions.spacingMedium),
                Text(
                  isEdited
                      ? 'Original AI confidence $percentage%'
                      : 'Confidence $percentage%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimaryFor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class MissingInformationCard extends StatelessWidget {
  const MissingInformationCard({required this.items, super.key});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return _AnalysisCard(
      title: 'Missing Information',
      icon: Icons.info_outline_rounded,
      child: items.isEmpty
          ? const _ObservationItem(
              icon: Icons.check_circle_outline_rounded,
              text: 'No important information appears to be missing.',
              isPositive: true,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  _ObservationItem(
                    icon: Icons.error_outline_rounded,
                    text: items[index],
                    isPositive: false,
                  ),
                  if (index != items.length - 1)
                    const SizedBox(height: AppDimensions.spacingSmall),
                ],
              ],
            ),
    );
  }
}

class QualityScoreCard extends StatelessWidget {
  const QualityScoreCard({
    required this.analysis,
    required this.draft,
    super.key,
  });

  final AiBugAnalysis analysis;
  final BugReport draft;

  @override
  Widget build(BuildContext context) {
    final score = analysis.qualityScore.clamp(0, 100);

    return _AnalysisCard(
      title: 'Report Quality',
      icon: Icons.insights_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textPrimaryFor(context),
                  fontSize: 34,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingXSmall),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '/100',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          LinearProgressIndicator(value: score / 100),
          const SizedBox(height: AppDimensions.spacingMedium),
          ..._qualityObservations(draft),
        ],
      ),
    );
  }

  List<Widget> _qualityObservations(BugReport draft) {
    return [
      const _ObservationItem(
        icon: Icons.check_circle_outline_rounded,
        text: 'Clear bug title provided.',
        isPositive: true,
      ),
      _ObservationItem(
        icon: draft.expectedBehavior.trim().isEmpty
            ? Icons.cancel_outlined
            : Icons.check_circle_outline_rounded,
        text: draft.expectedBehavior.trim().isEmpty
            ? 'Expected behavior missing.'
            : 'Expected behavior provided.',
        isPositive: draft.expectedBehavior.trim().isNotEmpty,
      ),
      _ObservationItem(
        icon: draft.actualBehavior.trim().isEmpty
            ? Icons.cancel_outlined
            : Icons.check_circle_outline_rounded,
        text: draft.actualBehavior.trim().isEmpty
            ? 'Actual behavior missing.'
            : 'Actual behavior provided.',
        isPositive: draft.actualBehavior.trim().isNotEmpty,
      ),
      _ObservationItem(
        icon: (draft.logs?.trim().isNotEmpty ?? false)
            ? Icons.check_circle_outline_rounded
            : Icons.cancel_outlined,
        text: (draft.logs?.trim().isNotEmpty ?? false)
            ? 'Error logs provided.'
            : 'Error logs missing.',
        isPositive: draft.logs?.trim().isNotEmpty ?? false,
      ),
    ];
  }
}

class AiDisclaimerCard extends StatelessWidget {
  const AiDisclaimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BugPilotCard(
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      color: AppTheme.primary.withAlpha(18),
      borderColor: AppTheme.primary.withAlpha(42),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppTheme.primary,
          ),
          const SizedBox(width: AppDimensions.spacingSmall),
          Expanded(
            child: Text(
              'AI suggestions may be inaccurate. Review the analysis before saving.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return BugPilotCard(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _SectionTitle(icon: icon, title: title),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            child,
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: AppDimensions.spacingSmall),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              color: AppTheme.textPrimaryFor(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgeReasonRow extends StatelessWidget {
  const _BadgeReasonRow({
    required this.title,
    required this.badge,
    required this.reason,
    required this.edited,
    required this.isRegenerating,
    required this.onEdit,
    required this.onRegenerate,
    this.editKey,
    this.regenerateKey,
  });

  final String title;
  final Widget badge;
  final String reason;
  final bool edited;
  final bool isRegenerating;
  final VoidCallback? onEdit;
  final VoidCallback? onRegenerate;
  final Key? editKey;
  final Key? regenerateKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: AppDimensions.spacingSmall,
                runSpacing: AppDimensions.spacingSmall,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textPrimaryFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  badge,
                  _SourceLabel(
                    label: edited ? 'Edited by you' : 'AI suggested',
                    edited: edited,
                  ),
                ],
              ),
            ),
            _SectionActions(
              isRegenerating: isRegenerating,
              onEdit: onEdit,
              onRegenerate: onRegenerate,
              editKey: editKey,
              regenerateKey: regenerateKey,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        if (edited) ...[
          Text(
            'Original AI reasoning',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXSmall),
        ],
        Text(reason, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _SectionActions extends StatelessWidget {
  const _SectionActions({
    this.isEdited = false,
    this.isRegenerating = false,
    this.onEdit,
    this.onRegenerate,
    this.editKey,
    this.regenerateKey,
  });

  final bool isEdited;
  final bool isRegenerating;
  final VoidCallback? onEdit;
  final VoidCallback? onRegenerate;
  final Key? editKey;
  final Key? regenerateKey;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.spacingXSmall,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (isEdited) const _SourceLabel(label: 'Edited by you', edited: true),
        if (onEdit != null)
          TextButton.icon(
            key: editKey,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
          ),
        if (onRegenerate != null || isRegenerating)
          TextButton.icon(
            key: regenerateKey,
            onPressed: isRegenerating ? null : onRegenerate,
            icon: isRegenerating
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Regenerate'),
          ),
      ],
    );
  }
}

class _SourceLabel extends StatelessWidget {
  const _SourceLabel({required this.label, this.edited = false});

  final String label;
  final bool edited;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: edited
            ? Colors.green.shade700.withAlpha(20)
            : AppTheme.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSmall,
          vertical: AppDimensions.spacingXSmall,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: edited ? Colors.green.shade700 : AppTheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EditableTestCaseCard extends StatelessWidget {
  const _EditableTestCaseCard({
    required this.testCase,
    required this.onEdit,
    required this.onDelete,
  });

  final BugTestCase testCase;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final type = testCase.type;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.mutedSurfaceFor(context),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppDimensions.spacingSmall,
                    runSpacing: AppDimensions.spacingSmall,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _MiniBadge(label: testCase.id),
                      if (type != null) _MiniBadge(label: type.label),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit test case',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete test case',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingSmall),
            Text(
              testCase.title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textPrimaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            _GivenWhenThen(label: 'Given', text: testCase.given),
            _GivenWhenThen(label: 'When', text: testCase.when),
            _GivenWhenThen(label: 'Then', text: testCase.then),
          ],
        ),
      ),
    );
  }
}

class _GivenWhenThen extends StatelessWidget {
  const _GivenWhenThen({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXSmall),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSmall,
          vertical: AppDimensions.spacingXSmall,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimaryFor(context),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(22),
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(
            dimension: 28,
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingSmall),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}

class _ObservationItem extends StatelessWidget {
  const _ObservationItem({
    required this.icon,
    required this.text,
    required this.isPositive,
  });

  final IconData icon;
  final String text;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: AppDimensions.spacingSmall),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
