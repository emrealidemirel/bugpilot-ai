import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/bugpilot_components.dart';
import '../../domain/enums/bug_platform.dart';
import '../../domain/enums/bug_priority.dart';
import '../../domain/enums/bug_severity.dart';
import '../../domain/enums/bug_status.dart';
import '../../domain/models/bug_report.dart';
import '../../domain/repositories/bug_repository.dart';
import '../logic/bug_report_filters.dart';
import '../widgets/bug_report_list_item.dart';
import '../../../report_bug/presentation/pages/report_bug_page.dart';

class BugReportsPage extends StatefulWidget {
  const BugReportsPage({
    required this.bugRepository,
    required this.refreshSignal,
    super.key,
  });

  static const routePath = '/bugs';

  final BugRepository bugRepository;
  final ValueListenable<int> refreshSignal;

  @override
  State<BugReportsPage> createState() => _BugReportsPageState();
}

class _BugReportsPageState extends State<BugReportsPage> {
  final _searchController = TextEditingController();

  late Future<List<BugReport>> _bugsFuture;
  BugStatus? _statusFilter;
  BugSeverity? _severityFilter;
  BugPriority? _priorityFilter;
  BugPlatform? _platformFilter;
  BugReportSortOption _sortOption = BugReportSortOption.newest;

  @override
  void initState() {
    super.initState();
    _bugsFuture = widget.bugRepository.getBugs();
    _searchController.addListener(_handleSearchChanged);
    widget.refreshSignal.addListener(_reloadBugs);
  }

  @override
  void didUpdateWidget(covariant BugReportsPage oldWidget) {
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
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  int get _secondaryFilterCount {
    return [
      _severityFilter,
      _priorityFilter,
      _platformFilter,
    ].where((filter) => filter != null).length;
  }

  bool get _hasActiveFilters {
    return _statusFilter != null ||
        _secondaryFilterCount > 0 ||
        _searchController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding,
          AppDimensions.pagePadding,
          AppDimensions.pagePadding,
          AppDimensions.pagePadding + AppDimensions.bottomNavigationClearance,
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BugPilotAppHeader(
                  title: 'Bugs',
                  subtitle: 'Track, review and manage reported issues.',
                  trailing: IconButton.filled(
                    tooltip: 'Report a Bug',
                    onPressed: () => context.go(ReportBugPage.routePath),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search bugs...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.trim().isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: _searchController.clear,
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingSmall),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton.outlined(
                          tooltip: 'Filters',
                          onPressed: _openFilters,
                          icon: const Icon(Icons.tune_rounded),
                        ),
                        if (_secondaryFilterCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox.square(
                                dimension: 18,
                                child: Center(
                                  child: Text(
                                    '$_secondaryFilterCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMedium),
                _StatusFilterChips(
                  selectedStatus: _statusFilter,
                  onSelected: (status) {
                    setState(() {
                      _statusFilter = status;
                    });
                  },
                ),
                const SizedBox(height: AppDimensions.spacingSmall),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<BugReportSortOption>(
                        initialValue: _sortOption,
                        decoration: const InputDecoration(
                          labelText: 'Sort',
                          prefixIcon: Icon(Icons.sort_rounded),
                        ),
                        items: [
                          for (final option in BugReportSortOption.values)
                            DropdownMenuItem(
                              value: option,
                              child: Text(option.label),
                            ),
                        ],
                        onChanged: (option) {
                          if (option == null) {
                            return;
                          }
                          setState(() {
                            _sortOption = option;
                          });
                        },
                      ),
                    ),
                    if (_hasActiveFilters) ...[
                      const SizedBox(width: AppDimensions.spacingSmall),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear filters'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingLarge),
                FutureBuilder<List<BugReport>>(
                  future: _bugsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const _BugReportsLoadingState();
                    }

                    if (snapshot.hasError) {
                      return const _BugReportsErrorState(
                        message: 'Unable to load bug reports.',
                      );
                    }

                    final allBugs = snapshot.data ?? const <BugReport>[];
                    if (allBugs.isEmpty) {
                      return _EmptyBugReportsState(
                        title: 'No bug reports yet',
                        message:
                            'Create your first bug report and let AI help with the analysis.',
                        actionLabel: 'Report a Bug',
                        onPressed: () => context.go(ReportBugPage.routePath),
                      );
                    }

                    final visibleBugs = filterAndSortBugReports(
                      bugs: allBugs,
                      searchQuery: _searchController.text,
                      status: _statusFilter,
                      severity: _severityFilter,
                      priority: _priorityFilter,
                      platform: _platformFilter,
                      sortOption: _sortOption,
                    );

                    if (visibleBugs.isEmpty) {
                      return _EmptyBugReportsState(
                        title: 'No matching bugs',
                        message: 'Try adjusting your search or filters.',
                        actionLabel: 'Clear filters',
                        onPressed: _clearFilters,
                      );
                    }

                    final countLabel = _hasActiveFilters
                        ? '${visibleBugs.length} of ${allBugs.length} bugs'
                        : '${allBugs.length} bugs';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          countLabel,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingSmall),
                        for (final bug in visibleBugs) ...[
                          BugReportListItem(
                            bug: bug,
                            onTap: () => context.go('/bugs/${bug.id}'),
                          ),
                          const SizedBox(height: AppDimensions.spacingSmall),
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
    );
  }

  void _handleSearchChanged() {
    setState(() {});
  }

  void _reloadBugs() {
    if (!mounted) {
      return;
    }

    setState(() {
      _bugsFuture = widget.bugRepository.getBugs();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _statusFilter = null;
      _severityFilter = null;
      _priorityFilter = null;
      _platformFilter = null;
    });
  }

  Future<void> _openFilters() async {
    final filters = await showModalBottomSheet<_SecondaryFilters>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _SecondaryFilterSheet(
          severity: _severityFilter,
          priority: _priorityFilter,
          platform: _platformFilter,
        );
      },
    );

    if (filters == null || !mounted) {
      return;
    }

    setState(() {
      _severityFilter = filters.severity;
      _priorityFilter = filters.priority;
      _platformFilter = filters.platform;
    });
  }
}

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({
    required this.selectedStatus,
    required this.onSelected,
  });

  final BugStatus? selectedStatus;
  final ValueChanged<BugStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: selectedStatus == null,
            onSelected: () => onSelected(null),
          ),
          for (final status in BugStatus.values)
            _FilterChip(
              label: status.label,
              selected: selectedStatus == status,
              onSelected: () => onSelected(status),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.spacingSmall),
      child: Material(
        color: selected ? colorScheme.primary : colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          side: BorderSide(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMedium,
              vertical: AppDimensions.spacingSmall,
            ),
            child: Text(
              label.toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryFilterSheet extends StatefulWidget {
  const _SecondaryFilterSheet({
    required this.severity,
    required this.priority,
    required this.platform,
  });

  final BugSeverity? severity;
  final BugPriority? priority;
  final BugPlatform? platform;

  @override
  State<_SecondaryFilterSheet> createState() => _SecondaryFilterSheetState();
}

class _SecondaryFilterSheetState extends State<_SecondaryFilterSheet> {
  late BugSeverity? _severity = widget.severity;
  late BugPriority? _priority = widget.priority;
  late BugPlatform? _platform = widget.platform;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            Text('Filters', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppDimensions.spacingMedium),
            _DropdownFilter<BugSeverity>(
              label: 'Severity',
              value: _severity,
              values: BugSeverity.values,
              labelFor: (severity) => severity.label,
              onChanged: (severity) {
                setState(() {
                  _severity = severity;
                });
              },
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            _DropdownFilter<BugPriority>(
              label: 'Priority',
              value: _priority,
              values: BugPriority.values,
              labelFor: (priority) => priority.label,
              onChanged: (priority) {
                setState(() {
                  _priority = priority;
                });
              },
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            _DropdownFilter<BugPlatform>(
              label: 'Platform',
              value: _platform,
              values: BugPlatform.values,
              labelFor: (platform) => platform.label,
              onChanged: (platform) {
                setState(() {
                  _platform = platform;
                });
              },
            ),
            const SizedBox(height: AppDimensions.spacingLarge),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _severity = null;
                      _priority = null;
                      _platform = null;
                    });
                  },
                  child: const Text('Clear filters'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    _SecondaryFilters(
                      severity: _severity,
                      priority: _priority,
                      platform: _platform,
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownFilter<T> extends StatelessWidget {
  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T?>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem<T?>(value: null, child: const Text('All')),
        for (final item in values)
          DropdownMenuItem<T?>(value: item, child: Text(labelFor(item))),
      ],
      onChanged: onChanged,
    );
  }
}

class _SecondaryFilters {
  const _SecondaryFilters({
    required this.severity,
    required this.priority,
    required this.platform,
  });

  final BugSeverity? severity;
  final BugPriority? priority;
  final BugPlatform? platform;
}

class _BugReportsLoadingState extends StatelessWidget {
  const _BugReportsLoadingState();

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

class _BugReportsErrorState extends StatelessWidget {
  const _BugReportsErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _EmptyBugReportsState extends StatelessWidget {
  const _EmptyBugReportsState({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BugPilotCard(
      padding: const EdgeInsets.all(AppDimensions.spacingXLarge),
      child: Column(
        children: [
          Icon(
            Icons.bug_report_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
