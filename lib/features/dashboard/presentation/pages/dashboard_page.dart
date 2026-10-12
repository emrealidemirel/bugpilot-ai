import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/date_label_formatter.dart';
import '../../../../core/widgets/bugpilot_components.dart';
import '../../../bug_reports/domain/enums/bug_severity.dart';
import '../../../bug_reports/domain/enums/bug_status.dart';
import '../../../bug_reports/domain/models/bug_report.dart';
import '../../../bug_reports/domain/repositories/bug_repository.dart';
import '../../../bug_reports/presentation/pages/bug_reports_page.dart';
import '../widgets/bug_list_item.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_stat_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    required this.bugRepository,
    required this.refreshSignal,
    super.key,
  });

  static const routePath = '/dashboard';

  final BugRepository bugRepository;
  final ValueListenable<int> refreshSignal;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<List<BugReport>> _bugsFuture;

  @override
  void initState() {
    super.initState();
    _bugsFuture = widget.bugRepository.getBugs();
    widget.refreshSignal.addListener(_reloadBugs);
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bugRepository != widget.bugRepository) {
      _reloadBugs();
    }
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      oldWidget.refreshSignal.removeListener(_reloadBugs);
      widget.refreshSignal.addListener(_reloadBugs);
    }
  }

  @override
  void dispose() {
    widget.refreshSignal.removeListener(_reloadBugs);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? AppTheme.darkBackground : AppTheme.background,
      child: Column(
        children: [
          const BugPilotRootHeader(title: 'Dashboard'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePadding,
                AppDimensions.spacingLarge,
                AppDimensions.pagePadding,
                AppDimensions.bottomNavigationClearance,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const DashboardHeader(),
                      const SizedBox(height: AppDimensions.spacingXLarge),
                      FutureBuilder<List<BugReport>>(
                        future: _bugsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const _DashboardLoadingState();
                          }

                          if (snapshot.hasError) {
                            return _DashboardErrorState(error: snapshot.error);
                          }

                          final bugs = snapshot.data ?? const [];
                          final recentBugs = [
                            ...bugs,
                          ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _StatsGrid(
                                children: [
                                  DashboardStatCard(
                                    title: 'Total Bugs',
                                    value: bugs.length.toString(),
                                    icon: Icons.bug_report_outlined,
                                  ),
                                  DashboardStatCard(
                                    title: 'Open',
                                    value: bugs
                                        .where(
                                          (bug) => bug.status == BugStatus.open,
                                        )
                                        .length
                                        .toString(),
                                    icon: Icons.pest_control_outlined,
                                    variant: DashboardStatVariant.open,
                                  ),
                                  DashboardStatCard(
                                    title: 'Critical',
                                    value: bugs
                                        .where(
                                          (bug) =>
                                              bug.severity ==
                                              BugSeverity.critical,
                                        )
                                        .length
                                        .toString(),
                                    icon: Icons.warning_amber_rounded,
                                    variant: DashboardStatVariant.critical,
                                  ),
                                  DashboardStatCard(
                                    title: 'Resolved',
                                    value: bugs
                                        .where(
                                          (bug) =>
                                              bug.status == BugStatus.resolved,
                                        )
                                        .length
                                        .toString(),
                                    icon: Icons.check_circle_outline_rounded,
                                    variant: DashboardStatVariant.resolved,
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: AppDimensions.spacingXLarge,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recent Bugs',
                                    style: textTheme.headlineMedium?.copyWith(
                                      color: AppTheme.textPrimaryFor(context),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        context.go(BugReportsPage.routePath),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppDimensions.spacingXSmall,
                                      ),
                                      minimumSize: const Size(44, 32),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('VIEW ALL'),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: AppDimensions.spacingLarge,
                              ),
                              for (final bug in recentBugs.take(3)) ...[
                                BugListItem(
                                  onTap: () => context.go('/bugs/${bug.id}'),
                                  displayId: bugDisplayId(bug.id),
                                  title: bug.title,
                                  severity: bug.severity,
                                  priority: bug.priority,
                                  platform: bug.platform,
                                  status: bug.status,
                                  date: formatRecentDateLabel(bug.createdAt),
                                ),
                                const SizedBox(
                                  height: AppDimensions.spacingSmall,
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _reloadBugs() {
    if (!mounted) {
      return;
    }

    setState(() {
      _bugsFuture = widget.bugRepository.getBugs();
    });
  }
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacingXLarge),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Unable to load bug reports.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columnCount = 2;
        final itemWidth =
            (constraints.maxWidth -
                (AppDimensions.spacingLarge * (columnCount - 1))) /
            columnCount;

        return Wrap(
          spacing: AppDimensions.spacingLarge,
          runSpacing: AppDimensions.spacingLarge,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
