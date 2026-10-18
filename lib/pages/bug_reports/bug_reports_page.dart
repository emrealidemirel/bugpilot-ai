import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bugpilot_ai/utils/localization_extensions.dart';
import 'package:bugpilot_ai/constants/app_dimensions.dart';
import 'package:bugpilot_ai/widgets/bugpilot_components.dart';
import 'package:bugpilot_ai/models/bug_platform.dart';
import 'package:bugpilot_ai/models/bug_priority.dart';
import 'package:bugpilot_ai/models/bug_severity.dart';
import 'package:bugpilot_ai/models/bug_status.dart';
import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:bugpilot_ai/repositories/bug_repository.dart';
import 'package:bugpilot_ai/utils/bug_report_filters.dart';
import 'package:bugpilot_ai/widgets/bug_report_list_item.dart';
import 'package:bugpilot_ai/pages/report_bug/report_bug_page.dart';

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

String _sortLabel(BuildContext context, BugReportSortOption option) {
  final l10n = context.l10n;
  return switch (option) {
    BugReportSortOption.newest => l10n.newestSort,
    BugReportSortOption.oldest => l10n.oldestSort,
    BugReportSortOption.severity => l10n.severityLabel,
    BugReportSortOption.priority => l10n.priorityLabel,
  };
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
    return _sortOption != BugReportSortOption.newest ||
        _statusFilter != null ||
        _secondaryFilterCount > 0 ||
        _searchController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
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
                const BugPilotAppHeader(),
                BugPilotCard(
                  padding: const EdgeInsets.all(20),
                  radius: AppDimensions.radiusDashboardCard,
                  shadow: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: context.l10n.searchBugsHint,
                                prefixIcon: const Icon(Icons.search_rounded),
                                suffixIcon:
                                    _searchController.text.trim().isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: context.l10n.clearSearch,
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
                                tooltip: context.l10n.filtersLabel,
                                onPressed: _openFilters,
                                icon: const Icon(Icons.tune_rounded),
                              ),
                              if (_secondaryFilterCount > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
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
                      const SizedBox(height: AppDimensions.spacingXLarge),
                      _StatusFilterChips(
                        selectedStatus: _statusFilter,
                        onSelected: (status) {
                          setState(() {
                            _statusFilter = status;
                          });
                        },
                      ),
                      if (_secondaryFilterCount > 0) ...[
                        const SizedBox(height: AppDimensions.spacingSmall),
                        Wrap(
                          spacing: AppDimensions.spacingSmall,
                          runSpacing: AppDimensions.spacingXSmall,
                          children: [
                            if (_severityFilter != null)
                              InputChip(
                                label: Text(
                                  '${context.l10n.severityLabel}: ${context.l10n.bugSeverityLabel(_severityFilter!)}',
                                ),
                                onDeleted: () =>
                                    setState(() => _severityFilter = null),
                              ),
                            if (_priorityFilter != null)
                              InputChip(
                                label: Text(
                                  '${context.l10n.priorityLabel}: ${context.l10n.priorityDescription(_priorityFilter!)}',
                                ),
                                onDeleted: () =>
                                    setState(() => _priorityFilter = null),
                              ),
                            if (_platformFilter != null)
                              InputChip(
                                label: Text(
                                  '${context.l10n.platformLabel}: ${context.l10n.localizedPlatformLabel(_platformFilter!)}',
                                ),
                                onDeleted: () =>
                                    setState(() => _platformFilter = null),
                              ),
                          ],
                        ),
                      ],
                      if (_hasActiveFilters)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: _clearFilters,
                            child: Text(context.l10n.clearFilters),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXLarge),
                FutureBuilder<List<BugReport>>(
                  future: _bugsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const _BugReportsLoadingState();
                    }

                    if (snapshot.hasError) {
                      return _BugReportsErrorState(
                        message: context.l10n.unableToLoadBugs,
                      );
                    }

                    final allBugs = snapshot.data ?? const <BugReport>[];
                    if (allBugs.isEmpty) {
                      return _EmptyBugReportsState(
                        title: context.l10n.noBugReports,
                        message: context.l10n.emptyBugHelp,
                        actionLabel: context.l10n.reportBugsAction,
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
                        title: context.l10n.noMatchingBugs,
                        message: context.l10n.adjustSearchFilters,
                        actionLabel: context.l10n.clearFilters,
                        onPressed: _clearFilters,
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final bug in visibleBugs) ...[
                          BugReportListItem(
                            bug: bug,
                            onTap: () => context.go('/bugs/${bug.id}'),
                          ),
                          const SizedBox(height: AppDimensions.spacingLarge),
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
      _sortOption = BugReportSortOption.newest;
    });
  }

  Future<void> _openFilters() async {
    FocusScope.of(context).unfocus();
    final filters = await showModalBottomSheet<_SecondaryFilters>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return _SecondaryFilterSheet(
          severity: _severityFilter,
          priority: _priorityFilter,
          platform: _platformFilter,
          sortOption: _sortOption,
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
      _sortOption = filters.sortOption;
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
          _StatusTab(
            label: context.l10n.filterAll,
            selected: selectedStatus == null,
            onTap: () => onSelected(null),
          ),
          for (final status in BugStatus.values)
            _StatusTab(
              label: context.l10n.statusLabel(status),
              selected: selectedStatus == status,
              onTap: () => onSelected(status),
            ),
        ],
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  const _StatusTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? colors.primary
                    : colors.outlineVariant.withAlpha(80),
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: selected ? colors.primary : colors.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
    required this.sortOption,
  });

  final BugSeverity? severity;
  final BugPriority? priority;
  final BugPlatform? platform;
  final BugReportSortOption sortOption;

  @override
  State<_SecondaryFilterSheet> createState() => _SecondaryFilterSheetState();
}

class _SecondaryFilterSheetState extends State<_SecondaryFilterSheet> {
  late BugSeverity? _severity = widget.severity;
  late BugPriority? _priority = widget.priority;
  late BugPlatform? _platform = widget.platform;
  late BugReportSortOption _sortOption = widget.sortOption;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
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
              context.l10n.filtersLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimensions.spacingXLarge),
            DropdownButtonFormField<BugReportSortOption>(
              key: ValueKey(_sortOption),
              initialValue: _sortOption,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.l10n.sortLabel,
                prefixIcon: const Icon(Icons.sort_rounded),
              ),
              items: [
                for (final option in BugReportSortOption.values)
                  DropdownMenuItem(
                    value: option,
                    child: Text(_sortLabel(context, option)),
                  ),
              ],
              onChanged: (option) {
                if (option != null) setState(() => _sortOption = option);
              },
            ),
            const Divider(height: AppDimensions.spacingXXLarge),
            _DropdownFilter<BugSeverity>(
              label: context.l10n.severityLabel,
              value: _severity,
              values: BugSeverity.values,
              labelFor: context.l10n.bugSeverityLabel,
              onChanged: (severity) {
                setState(() {
                  _severity = severity;
                });
              },
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            _DropdownFilter<BugPriority>(
              label: context.l10n.priorityLabel,
              value: _priority,
              values: BugPriority.values,
              labelFor: context.l10n.priorityDescription,
              onChanged: (priority) {
                setState(() {
                  _priority = priority;
                });
              },
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            _DropdownFilter<BugPlatform>(
              label: context.l10n.platformLabel,
              value: _platform,
              values: BugPlatform.values,
              labelFor: context.l10n.localizedPlatformLabel,
              onChanged: (platform) {
                setState(() {
                  _platform = platform;
                });
              },
            ),
            const SizedBox(height: AppDimensions.spacingLarge),
            OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              spacing: AppDimensions.spacingSmall,
              overflowSpacing: AppDimensions.spacingSmall,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _severity = null;
                      _priority = null;
                      _platform = null;
                      _sortOption = BugReportSortOption.newest;
                    });
                  },
                  child: Text(context.l10n.clearFilters),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    _SecondaryFilters(
                      severity: _severity,
                      priority: _priority,
                      platform: _platform,
                      sortOption: _sortOption,
                    ),
                  ),
                  child: Text(context.l10n.applyAction),
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
      key: ValueKey('$label:$value'),
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem<T?>(value: null, child: Text(context.l10n.filterAll)),
        for (final item in values)
          DropdownMenuItem<T?>(
            value: item,
            child: Text(labelFor(item), overflow: TextOverflow.ellipsis),
          ),
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
    required this.sortOption,
  });

  final BugSeverity? severity;
  final BugPriority? priority;
  final BugPlatform? platform;
  final BugReportSortOption sortOption;
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
