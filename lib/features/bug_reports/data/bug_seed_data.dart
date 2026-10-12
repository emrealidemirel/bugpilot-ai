import '../domain/enums/bug_platform.dart';
import '../domain/enums/bug_priority.dart';
import '../domain/enums/bug_severity.dart';
import '../domain/enums/bug_status.dart';
import '../domain/enums/bug_test_case_type.dart';
import '../domain/models/bug_report.dart';
import '../domain/models/bug_test_case.dart';

final defaultBugSeedReports = [
  BugReport(
    id: 'bug-001',
    title: 'Login button stuck loading',
    description:
        'The login screen remains in a loading state after valid credentials '
        'are submitted.',
    expectedBehavior: 'The user should be redirected to the dashboard.',
    actualBehavior: 'The loading indicator remains visible indefinitely.',
    platform: BugPlatform.android,
    device: 'Pixel 9',
    osVersion: 'Android 16',
    appVersion: '1.0.0',
    logs: 'POST /auth/login returned 200, navigation callback not invoked.',
    severity: BugSeverity.high,
    priority: BugPriority.p1,
    status: BugStatus.open,
    reproductionSteps: const [
      'Open the login screen.',
      'Enter valid credentials.',
      'Tap Login.',
    ],
    testCases: const [
      BugTestCase(
        id: 'tc-001',
        title: 'Valid login redirects to dashboard',
        given: 'A user has valid credentials',
        when: 'The user submits the login form',
        then: 'The dashboard is displayed',
        type: BugTestCaseType.positive,
      ),
    ],
    possibleRootCause: 'Navigation state may not reset after auth success.',
    rootCauseConfidence: 0.71,
    createdAt: DateTime.utc(2026, 8, 19, 9, 10),
    updatedAt: DateTime.utc(2026, 8, 19, 9, 35),
  ),
  BugReport(
    id: 'bug-002',
    title: 'Cart total is incorrect after removing an item',
    description:
        'Removing an item from the cart updates the item list but leaves the '
        'previous subtotal visible.',
    expectedBehavior:
        'The subtotal and total should update immediately after an item is '
        'removed.',
    actualBehavior:
        'The removed item price remains included in the cart total.',
    platform: BugPlatform.ios,
    device: 'iPhone 15',
    osVersion: 'iOS 18',
    appVersion: '1.0.0',
    severity: BugSeverity.medium,
    priority: BugPriority.p2,
    status: BugStatus.open,
    reproductionSteps: const [
      'Add two products to the cart.',
      'Remove one product.',
      'Compare the displayed total with the remaining item.',
    ],
    createdAt: DateTime.utc(2026, 8, 18, 13, 45),
    updatedAt: DateTime.utc(2026, 8, 18, 14, 5),
  ),
  BugReport(
    id: 'bug-003',
    title: 'Profile image disappears after app restart',
    description:
        'A newly selected profile image appears during the current session but '
        'is missing after the app restarts.',
    expectedBehavior:
        'The selected profile image should persist across restarts.',
    actualBehavior: 'The profile header falls back to initials after restart.',
    platform: BugPlatform.android,
    device: 'Galaxy S25',
    osVersion: 'Android 16',
    appVersion: '1.0.0',
    severity: BugSeverity.low,
    priority: BugPriority.p3,
    status: BugStatus.resolved,
    reproductionSteps: const [
      'Change the profile image.',
      'Close and restart the app.',
      'Open the profile screen.',
    ],
    createdAt: DateTime.utc(2026, 8, 17, 16, 20),
    updatedAt: DateTime.utc(2026, 8, 18, 8, 15),
  ),
  BugReport(
    id: 'bug-004',
    title: 'Checkout confirmation email is not sent',
    description:
        'Orders complete successfully, but customers do not receive the '
        'confirmation email.',
    expectedBehavior:
        'A confirmation email should be sent when checkout completes.',
    actualBehavior: 'No email is delivered after the order is created.',
    platform: BugPlatform.web,
    osVersion: 'Chrome 139',
    appVersion: '1.0.0',
    logs: 'Email queue job skipped because customerEmail was empty.',
    severity: BugSeverity.critical,
    priority: BugPriority.p0,
    status: BugStatus.inProgress,
    reproductionSteps: const [
      'Complete checkout as a registered user.',
      'Open the order confirmation page.',
      'Check the customer inbox.',
    ],
    testCases: const [
      BugTestCase(
        id: 'tc-004',
        title: 'Registered checkout sends confirmation email',
        given: 'A registered customer completes checkout',
        when: 'The order is saved',
        then: 'A confirmation email is queued',
        type: BugTestCaseType.positive,
      ),
    ],
    possibleRootCause: 'Checkout payload may omit customerEmail on web.',
    rootCauseConfidence: 0.82,
    createdAt: DateTime.utc(2026, 8, 16, 10),
    updatedAt: DateTime.utc(2026, 8, 17, 11, 30),
  ),
  BugReport(
    id: 'bug-005',
    title: 'Search results flicker while typing quickly',
    description:
        'Rapid search input causes older result sets to flash after newer '
        'results have already appeared.',
    expectedBehavior: 'Only the latest query results should be displayed.',
    actualBehavior:
        'Out-of-order responses briefly replace the latest search results.',
    platform: BugPlatform.web,
    osVersion: 'Safari 18',
    appVersion: '1.0.0',
    severity: BugSeverity.medium,
    priority: BugPriority.p2,
    status: BugStatus.closed,
    reproductionSteps: const [
      'Open product search.',
      'Type a three-word query quickly.',
      'Watch the result list while requests complete.',
    ],
    createdAt: DateTime.utc(2026, 8, 14, 15, 25),
    updatedAt: DateTime.utc(2026, 8, 15, 9, 40),
  ),
];
