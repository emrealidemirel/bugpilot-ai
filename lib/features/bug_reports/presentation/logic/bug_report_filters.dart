import '../../domain/enums/bug_platform.dart';
import '../../domain/enums/bug_priority.dart';
import '../../domain/enums/bug_severity.dart';
import '../../domain/enums/bug_status.dart';
import '../../domain/models/bug_report.dart';

enum BugReportSortOption { newest, oldest, severity, priority }

extension BugReportSortOptionPresentation on BugReportSortOption {
  String get label {
    return switch (this) {
      BugReportSortOption.newest => 'Newest',
      BugReportSortOption.oldest => 'Oldest',
      BugReportSortOption.severity => 'Severity',
      BugReportSortOption.priority => 'Priority',
    };
  }
}

List<BugReport> filterAndSortBugReports({
  required List<BugReport> bugs,
  String searchQuery = '',
  BugStatus? status,
  BugSeverity? severity,
  BugPriority? priority,
  BugPlatform? platform,
  BugReportSortOption sortOption = BugReportSortOption.newest,
}) {
  final query = searchQuery.trim().toLowerCase();
  final filtered = bugs.where((bug) {
    final matchesQuery =
        query.isEmpty ||
        bug.title.toLowerCase().contains(query) ||
        bug.description.toLowerCase().contains(query);
    final matchesStatus = status == null || bug.status == status;
    final matchesSeverity = severity == null || bug.severity == severity;
    final matchesPriority = priority == null || bug.priority == priority;
    final matchesPlatform = platform == null || bug.platform == platform;

    return matchesQuery &&
        matchesStatus &&
        matchesSeverity &&
        matchesPriority &&
        matchesPlatform;
  }).toList();

  filtered.sort((a, b) {
    final primary = switch (sortOption) {
      BugReportSortOption.newest => b.createdAt.compareTo(a.createdAt),
      BugReportSortOption.oldest => a.createdAt.compareTo(b.createdAt),
      BugReportSortOption.severity => _severityRank(
        b.severity,
      ).compareTo(_severityRank(a.severity)),
      BugReportSortOption.priority => _priorityRank(
        b.priority,
      ).compareTo(_priorityRank(a.priority)),
    };

    if (primary != 0) {
      return primary;
    }

    final createdComparison = b.createdAt.compareTo(a.createdAt);
    if (createdComparison != 0) {
      return createdComparison;
    }

    return a.id.compareTo(b.id);
  });

  return filtered;
}

int _severityRank(BugSeverity? severity) {
  return switch (severity) {
    BugSeverity.critical => 4,
    BugSeverity.high => 3,
    BugSeverity.medium => 2,
    BugSeverity.low => 1,
    null => 0,
  };
}

int _priorityRank(BugPriority? priority) {
  return switch (priority) {
    BugPriority.p0 => 4,
    BugPriority.p1 => 3,
    BugPriority.p2 => 2,
    BugPriority.p3 => 1,
    null => 0,
  };
}
