import 'package:bugpilot_ai/models/bug_platform.dart';
import 'package:bugpilot_ai/models/bug_priority.dart';
import 'package:bugpilot_ai/models/bug_severity.dart';
import 'package:bugpilot_ai/models/bug_status.dart';
import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:bugpilot_ai/utils/bug_report_filters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('filterAndSortBugReports', () {
    test('filters by status, severity, priority, and platform', () {
      final bugs = _bugs();

      expect(
        filterAndSortBugReports(
          bugs: bugs,
          status: BugStatus.open,
          severity: BugSeverity.critical,
          priority: BugPriority.p0,
          platform: BugPlatform.web,
        ).map((bug) => bug.id),
        ['bug-003'],
      );
    });

    test('searches by title and description case-insensitively', () {
      final bugs = _bugs();

      expect(
        filterAndSortBugReports(
          bugs: bugs,
          searchQuery: 'login',
        ).map((bug) => bug.id),
        ['bug-001'],
      );
      expect(
        filterAndSortBugReports(
          bugs: bugs,
          searchQuery: 'TOTAL',
        ).map((bug) => bug.id),
        ['bug-002'],
      );
    });

    test('applies combined filters', () {
      final result = filterAndSortBugReports(
        bugs: _bugs(),
        searchQuery: 'checkout',
        status: BugStatus.open,
        severity: BugSeverity.critical,
      );

      expect(result.single.id, 'bug-003');
    });

    test('sorts newest and oldest first', () {
      expect(
        filterAndSortBugReports(
          bugs: _bugs(),
          sortOption: BugReportSortOption.newest,
        ).map((bug) => bug.id),
        ['bug-004', 'bug-003', 'bug-002', 'bug-001'],
      );
      expect(
        filterAndSortBugReports(
          bugs: _bugs(),
          sortOption: BugReportSortOption.oldest,
        ).map((bug) => bug.id),
        ['bug-001', 'bug-002', 'bug-003', 'bug-004'],
      );
    });

    test('sorts severity and priority with nulls last', () {
      expect(
        filterAndSortBugReports(
          bugs: _bugs(),
          sortOption: BugReportSortOption.severity,
        ).map((bug) => bug.id),
        ['bug-003', 'bug-001', 'bug-002', 'bug-004'],
      );
      expect(
        filterAndSortBugReports(
          bugs: _bugs(),
          sortOption: BugReportSortOption.priority,
        ).map((bug) => bug.id),
        ['bug-003', 'bug-001', 'bug-002', 'bug-004'],
      );
    });
  });
}

List<BugReport> _bugs() {
  return [
    _bug(
      id: 'bug-001',
      title: 'Login loading',
      description: 'Button stays busy.',
      createdAt: DateTime.utc(2026, 8, 16),
      severity: BugSeverity.high,
      priority: BugPriority.p1,
      platform: BugPlatform.android,
      status: BugStatus.open,
    ),
    _bug(
      id: 'bug-002',
      title: 'Cart issue',
      description: 'Cart total is stale.',
      createdAt: DateTime.utc(2026, 8, 17),
      severity: BugSeverity.low,
      priority: BugPriority.p3,
      platform: BugPlatform.ios,
      status: BugStatus.resolved,
    ),
    _bug(
      id: 'bug-003',
      title: 'Checkout failure',
      description: 'Checkout blocks payment.',
      createdAt: DateTime.utc(2026, 8, 18),
      severity: BugSeverity.critical,
      priority: BugPriority.p0,
      platform: BugPlatform.web,
      status: BugStatus.open,
    ),
    _bug(
      id: 'bug-004',
      title: 'Untriaged profile bug',
      description: 'Avatar disappears.',
      createdAt: DateTime.utc(2026, 8, 19),
      severity: null,
      priority: null,
      platform: BugPlatform.android,
      status: BugStatus.closed,
    ),
  ];
}

BugReport _bug({
  required String id,
  required String title,
  required String description,
  required DateTime createdAt,
  required BugSeverity? severity,
  required BugPriority? priority,
  required BugPlatform platform,
  required BugStatus status,
}) {
  return BugReport(
    id: id,
    title: title,
    description: description,
    expectedBehavior: 'The expected behavior is shown.',
    actualBehavior: 'The actual behavior is shown.',
    platform: platform,
    severity: severity,
    priority: priority,
    status: status,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}
