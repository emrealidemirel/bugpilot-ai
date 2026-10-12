import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/date_label_formatter.dart';
import '../../../../core/widgets/bugpilot_components.dart';
import '../../../dashboard/presentation/widgets/priority_badge.dart';
import '../../../dashboard/presentation/widgets/severity_badge.dart';
import '../../domain/enums/bug_platform.dart';
import '../../domain/enums/bug_status.dart';
import '../../domain/models/bug_report.dart';
import '../../domain/repositories/bug_repository.dart';
import '../widgets/bug_metadata_item.dart';
import '../widgets/bug_status_chip.dart';
import '../widgets/bug_test_case_card.dart';
import 'bug_reports_page.dart';

class BugDetailPage extends StatefulWidget {
  const BugDetailPage({
    required this.bugId,
    required this.bugRepository,
    required this.refreshSignal,
    required this.onBugChanged,
    super.key,
  });

  final String bugId;
  final BugRepository bugRepository;
  final ValueListenable<int> refreshSignal;
  final VoidCallback onBugChanged;

  @override
  State<BugDetailPage> createState() => _BugDetailPageState();
}

class _BugDetailPageState extends State<BugDetailPage> {
  late Future<BugReport?> _bugFuture;
  bool _isUpdatingStatus = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _bugFuture = widget.bugRepository.getBugById(widget.bugId);
    widget.refreshSignal.addListener(_reloadBug);
  }

  @override
  void didUpdateWidget(covariant BugDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bugId != widget.bugId ||
        oldWidget.bugRepository != widget.bugRepository) {
      _reloadBug();
    }
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      oldWidget.refreshSignal.removeListener(_reloadBug);
      widget.refreshSignal.addListener(_reloadBug);
    }
  }

  @override
  void dispose() {
    widget.refreshSignal.removeListener(_reloadBug);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<BugReport?>(
        future: _bugFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const _DetailErrorState(
              message: 'Unable to load bug report.',
            );
          }

          final bug = snapshot.data;
          if (bug == null) {
            return const _BugNotFoundState();
          }

          return _BugDetailContent(
            bug: bug,
            isBusy: _isUpdatingStatus || _isDeleting,
            onEdit: () => context.go('/bugs/${bug.id}/edit'),
            onChangeStatus: () => _changeStatus(bug),
            onDelete: () => _confirmDelete(bug),
          );
        },
      ),
    );
  }

  void _reloadBug() {
    if (!mounted) {
      return;
    }

    setState(() {
      _bugFuture = widget.bugRepository.getBugById(widget.bugId);
    });
  }

  Future<void> _changeStatus(BugReport bug) async {
    final status = await showModalBottomSheet<BugStatus>(
      context: context,
      showDragHandle: true,
      builder: (context) => _StatusSheet(currentStatus: bug.status),
    );

    if (status == null || status == bug.status || !mounted) {
      return;
    }

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await widget.bugRepository.updateBug(
        bug.copyWith(status: status, updatedAt: DateTime.now()),
      );
      if (!mounted) {
        return;
      }

      widget.onBugChanged();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bug status updated.')));
    } on Object {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not update the bug report.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  Future<void> _confirmDelete(BugReport bug) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete bug report?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await widget.bugRepository.deleteBug(bug.id);
      if (!mounted) {
        return;
      }

      widget.onBugChanged();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bug report deleted.')));
      context.go(BugReportsPage.routePath);
    } on Object {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not delete the bug report.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _BugDetailContent extends StatelessWidget {
  const _BugDetailContent({
    required this.bug,
    required this.isBusy,
    required this.onEdit,
    required this.onChangeStatus,
    required this.onDelete,
  });

  final BugReport bug;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onChangeStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePadding,
        AppDimensions.pagePadding,
        AppDimensions.pagePadding,
        AppDimensions.pagePadding + AppDimensions.bottomNavigationClearance,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BugPilotAppHeader(
                title: 'Bug Details',
                subtitle: bugDisplayId(bug.id),
                leading: IconButton(
                  tooltip: 'Back to Bugs',
                  onPressed: isBusy
                      ? null
                      : () => context.go(BugReportsPage.routePath),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                trailing: PopupMenuButton<_DetailAction>(
                  enabled: !isBusy,
                  onSelected: (action) {
                    switch (action) {
                      case _DetailAction.edit:
                        onEdit();
                      case _DetailAction.changeStatus:
                        onChangeStatus();
                      case _DetailAction.delete:
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _DetailAction.edit,
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: _DetailAction.changeStatus,
                      child: Text('Change Status'),
                    ),
                    PopupMenuItem(
                      value: _DetailAction.delete,
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: AppDimensions.spacingSmall,
                runSpacing: AppDimensions.spacingSmall,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SeverityBadge(severity: bug.severity),
                  PriorityBadge(priority: bug.priority),
                  BugStatusChip(status: bug.status),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingSmall),
              Text(bug.title, style: textTheme.headlineMedium),
              const SizedBox(height: AppDimensions.spacingSmall),
              Wrap(
                spacing: AppDimensions.spacingSmall,
                runSpacing: AppDimensions.spacingSmall,
                children: [
                  BugMetadataItem(
                    icon: bugPlatformIcon(bug.platform),
                    label: bug.platform.label,
                  ),
                  if (bug.appVersion?.trim().isNotEmpty ?? false)
                    BugMetadataItem(
                      icon: Icons.commit_rounded,
                      label: bug.appVersion!.trim(),
                    ),
                  BugMetadataItem(
                    icon: Icons.calendar_today_outlined,
                    label: formatDetailedDateLabel(bug.createdAt),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingLarge),
              _MetadataSection(bug: bug),
              if (bug.screenshot != null) ...[
                const SizedBox(height: AppDimensions.spacingMedium),
                _ScreenshotSection(screenshotPath: bug.screenshot!.localPath),
              ],
              const SizedBox(height: AppDimensions.spacingMedium),
              _DetailSection(
                title: 'Description',
                child: Text(bug.description),
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              _BehaviorSection(bug: bug),
              const SizedBox(height: AppDimensions.spacingMedium),
              _ReproductionStepsSection(steps: bug.reproductionSteps),
              const SizedBox(height: AppDimensions.spacingMedium),
              _TestCasesSection(bug: bug),
              const SizedBox(height: AppDimensions.spacingMedium),
              _RootCauseSection(bug: bug),
              if (bug.logs?.trim().isNotEmpty ?? false) ...[
                const SizedBox(height: AppDimensions.spacingMedium),
                _LogsSection(logs: bug.logs!.trim()),
              ],
              const SizedBox(height: AppDimensions.spacingLarge),
              FilledButton.icon(
                onPressed: isBusy ? null : onChangeStatus,
                icon: Icon(
                  bug.status == BugStatus.resolved
                      ? Icons.swap_horiz_rounded
                      : Icons.check_circle_outline_rounded,
                ),
                label: Text(
                  bug.status == BugStatus.resolved
                      ? 'CHANGE STATUS'
                      : 'MARK RESOLVED',
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSmall),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('EDIT'),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingSmall),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('DELETE'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _DetailAction { edit, changeStatus, delete }

class _ScreenshotSection extends StatelessWidget {
  const _ScreenshotSection({required this.screenshotPath});

  final String screenshotPath;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Screenshot',
      child: FutureBuilder<bool>(
        future: kIsWeb
            ? Future<bool>.value(true)
            : File(screenshotPath).exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.data != true) {
            return const _NeutralText('Screenshot is no longer available.');
          }

          return InkWell(
            onTap: () => _showScreenshotDialog(context, screenshotPath),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              child: SizedBox(
                height: 220,
                child: _DetailScreenshotImage(path: screenshotPath),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showScreenshotDialog(BuildContext context, String path) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog.fullscreen(
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: Center(
                      child: _DetailScreenshotImage(
                        path: path,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: AppDimensions.spacingSmall,
                  right: AppDimensions.spacingSmall,
                  child: IconButton.filledTonal(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailScreenshotImage extends StatelessWidget {
  const _DetailScreenshotImage({required this.path, this.fit = BoxFit.cover});

  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(path, fit: fit);
    }

    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(
            child: Text('Screenshot is no longer available.'),
          ),
        );
      },
    );
  }
}

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({required this.bug});

  final BugReport bug;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetadataRow('Platform', bug.platform.label),
      if (bug.device?.trim().isNotEmpty ?? false)
        _MetadataRow('Device', bug.device!.trim()),
      if (bug.osVersion?.trim().isNotEmpty ?? false)
        _MetadataRow('OS Version', bug.osVersion!.trim()),
      if (bug.appVersion?.trim().isNotEmpty ?? false)
        _MetadataRow('App Version', bug.appVersion!.trim()),
      _MetadataRow('Created', formatDetailedDateLabel(bug.createdAt)),
      _MetadataRow('Last Updated', formatDetailedDateLabel(bug.updatedAt)),
    ];

    return _DetailSection(
      title: 'Metadata',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            items[index],
            if (index != items.length - 1)
              const Divider(height: AppDimensions.spacingLarge),
          ],
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingSmall),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _BehaviorSection extends StatelessWidget {
  const _BehaviorSection({required this.bug});

  final BugReport bug;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Behavior',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SubsectionText(
            title: 'Expected Behavior',
            text: bug.expectedBehavior,
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          _SubsectionText(title: 'Actual Behavior', text: bug.actualBehavior),
        ],
      ),
    );
  }
}

class _ReproductionStepsSection extends StatelessWidget {
  const _ReproductionStepsSection({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'AI Reproduction Steps',
      child: steps.isEmpty
          ? const _NeutralText('No reproduction steps available.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < steps.length; index++) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimaryFor(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingSmall),
                      Expanded(child: Text(steps[index])),
                    ],
                  ),
                  if (index != steps.length - 1)
                    const SizedBox(height: AppDimensions.spacingSmall),
                ],
              ],
            ),
    );
  }
}

class _TestCasesSection extends StatelessWidget {
  const _TestCasesSection({required this.bug});

  final BugReport bug;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Test Cases',
      child: bug.testCases.isEmpty
          ? const _NeutralText('No test cases available.')
          : Column(
              children: [
                for (var index = 0; index < bug.testCases.length; index++) ...[
                  BugTestCaseCard(testCase: bug.testCases[index]),
                  if (index != bug.testCases.length - 1)
                    const SizedBox(height: AppDimensions.spacingSmall),
                ],
              ],
            ),
    );
  }
}

class _RootCauseSection extends StatelessWidget {
  const _RootCauseSection({required this.bug});

  final BugReport bug;

  @override
  Widget build(BuildContext context) {
    final rootCause = bug.possibleRootCause?.trim();
    final confidence = bug.rootCauseConfidence;

    return _DetailSection(
      title: 'AI Root Cause Analysis',
      child: rootCause == null || rootCause.isEmpty
          ? const _NeutralText('No root-cause hypothesis available.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(rootCause),
                if (confidence != null) ...[
                  const SizedBox(height: AppDimensions.spacingMedium),
                  Text(
                    'Confidence ${(confidence.clamp(0.0, 1.0) * 100).round()}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimaryFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _LogsSection extends StatelessWidget {
  const _LogsSection({required this.logs});

  final String logs;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Error Logs / Stack Trace',
      child: BugPilotTechnicalBox(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMedium),
          child: SelectableText(
            logs,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: AppTheme.monoFontFamily,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BugPilotCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              color: AppTheme.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          child,
        ],
      ),
    );
  }
}

class _SubsectionText extends StatelessWidget {
  const _SubsectionText({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textPrimaryFor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        Text(text),
      ],
    );
  }
}

class _NeutralText extends StatelessWidget {
  const _NeutralText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodyMedium);
  }
}

class _StatusSheet extends StatelessWidget {
  const _StatusSheet({required this.currentStatus});

  final BugStatus currentStatus;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.pagePadding,
            AppDimensions.spacingMedium,
            AppDimensions.pagePadding,
            AppDimensions.pagePadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Change Status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              for (final status in BugStatus.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(status.label),
                  trailing: status == currentStatus
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.of(context).pop(status),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BugNotFoundState extends StatelessWidget {
  const _BugNotFoundState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 44,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            Text(
              'Bug report not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            FilledButton(
              onPressed: () => context.go(BugReportsPage.routePath),
              child: const Text('Back to Bugs'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}
