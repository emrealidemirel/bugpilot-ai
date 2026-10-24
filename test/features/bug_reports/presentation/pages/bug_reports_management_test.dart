import 'package:bugpilot_ai/app/app.dart';
import '../../../../support/mock_ai_bug_analysis_service.dart';
import 'package:bugpilot_ai/repositories/in_memory_bug_repository.dart';
import 'package:bugpilot_ai/models/bug_platform.dart';
import 'package:bugpilot_ai/models/bug_priority.dart';
import 'package:bugpilot_ai/models/bug_severity.dart';
import 'package:bugpilot_ai/models/bug_status.dart';
import 'package:bugpilot_ai/models/bug_test_case_type.dart';
import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:bugpilot_ai/models/bug_test_case.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    binding.platformDispatcher.localeTestValue = const Locale('en');
    await rootBundle.loadString('assets/translations/en.json');
    await rootBundle.loadString('assets/translations/tr.json');
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('renders bug reports list and opens detail', (tester) async {
    final repository = InMemoryBugRepository(seedBugs: [_analyzedBug()]);

    await tester.pumpWidget(_app(repository));
    await _settleTranslations(tester);

    await tester.tap(find.text('BUGS'));
    await _settleTranslations(tester);

    expect(find.text('Search bugs...'), findsWidgets);
    expect(find.text('Search bugs...'), findsOneWidget);
    expect(find.text('OPEN'), findsWidgets);
    expect(find.text('Login button stuck loading'), findsOneWidget);

    await tester.tap(find.text('Login button stuck loading'));
    await _settleTranslations(tester);

    expect(find.text('Expected Behavior'), findsOneWidget);
    expect(find.text('Actual Behavior'), findsOneWidget);
    expect(find.text('AI Reproduction Steps'), findsOneWidget);
    expect(find.text('Test Cases'), findsOneWidget);
    expect(find.text('AI Root Cause Analysis'), findsOneWidget);
    expect(find.text('Valid login redirects'), findsOneWidget);
  });

  testWidgets('detail renders safely with missing AI fields', (tester) async {
    final repository = InMemoryBugRepository(seedBugs: [_manualBug()]);

    await tester.pumpWidget(_app(repository));
    await _settleTranslations(tester);
    await tester.tap(find.text('BUGS'));
    await _settleTranslations(tester);
    await tester.tap(find.text('Manual profile issue'));
    await _settleTranslations(tester);

    expect(find.text('UNTRIAGED'), findsOneWidget);
    expect(find.text('UNPRIORITIZED'), findsOneWidget);
    expect(find.text('No reproduction steps available.'), findsOneWidget);
    expect(find.text('No test cases available.'), findsOneWidget);
    expect(find.text('No root-cause hypothesis available.'), findsOneWidget);
  });

  testWidgets('changes status from detail', (tester) async {
    final repository = InMemoryBugRepository(seedBugs: [_analyzedBug()]);

    await tester.pumpWidget(_app(repository));
    await _settleTranslations(tester);
    await _openDetail(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await _settleTranslations(tester);
    await tester.tap(find.text('Change Status'));
    await _settleTranslations(tester);
    await tester.tap(find.text('Resolved').last);
    await _settleTranslations(tester);

    final bug = await repository.getBugById('bug-001');
    expect(bug?.status, BugStatus.resolved);
    expect(find.text('Bug status updated.'), findsOneWidget);
  });

  testWidgets('edits manual fields and preserves AI fields', (tester) async {
    final repository = InMemoryBugRepository(seedBugs: [_analyzedBug()]);

    await tester.pumpWidget(_app(repository));
    await _settleTranslations(tester);
    await _openDetail(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await _settleTranslations(tester);
    await tester.tap(find.text('Edit'));
    await _settleTranslations(tester);

    expect(find.text('Edit Bug'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Login button stuck loading'),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Login button stuck loading'),
      'Login button never finishes',
    );
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await _settleTranslations(tester);

    final bug = await repository.getBugById('bug-001');
    expect(bug?.title, 'Login button never finishes');
    expect(bug?.reproductionSteps, ['Open login', 'Submit credentials']);
    expect(bug?.testCases.single.title, 'Valid login redirects');
    expect(bug?.possibleRootCause, 'Navigation callback may not run.');
  });

  testWidgets('validates edit form before updating', (tester) async {
    final repository = InMemoryBugRepository(seedBugs: [_analyzedBug()]);

    await tester.pumpWidget(_app(repository));
    await _settleTranslations(tester);
    await _openDetail(tester);
    await tester.tap(find.byIcon(Icons.more_vert));
    await _settleTranslations(tester);
    await tester.tap(find.text('Edit'));
    await _settleTranslations(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Login button stuck loading'),
      '',
    );
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await _settleTranslations(tester);

    final bug = await repository.getBugById('bug-001');
    expect(bug?.title, 'Login button stuck loading');
    expect(find.text('This field is required.'), findsOneWidget);
  });

  for (final dx in [-600.0, 600.0]) {
    testWidgets('swipe $dx confirms, cancels and deletes from list', (
      tester,
    ) async {
      final repository = InMemoryBugRepository(seedBugs: [_analyzedBug()]);
      await tester.pumpWidget(_app(repository));
      await _settleTranslations(tester);
      await tester.tap(find.text('BUGS'));
      await _settleTranslations(tester);
      final card = find.byKey(const ValueKey('swipe-delete-bug-001'));
      await tester.drag(card, Offset(dx, 0));
      await tester.pumpAndSettle();
      expect(find.text('Delete bug report?'), findsOneWidget);
      expect(await repository.getBugById('bug-001'), isNotNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(card, findsOneWidget);
      expect(await repository.getBugById('bug-001'), isNotNull);
      await tester.drag(card, Offset(dx, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(await repository.getBugById('bug-001'), isNull);
      expect(card, findsNothing);
      expect(find.text('Bug report deleted.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('failed swipe deletion keeps the report available', (
    tester,
  ) async {
    final repository = _FailingDeleteRepository(seedBugs: [_analyzedBug()]);
    await tester.pumpWidget(_app(repository));
    await _settleTranslations(tester);
    await tester.tap(find.text('BUGS'));
    await _settleTranslations(tester);
    final card = find.byKey(const ValueKey('swipe-delete-bug-001'));
    await tester.drag(card, const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(await repository.getBugById('bug-001'), isNotNull);
    expect(card, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirms before deleting a bug', (tester) async {
    final repository = InMemoryBugRepository(seedBugs: [_analyzedBug()]);

    await tester.pumpWidget(_app(repository));
    await _settleTranslations(tester);
    await _openDetail(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await _settleTranslations(tester);
    await tester.tap(find.text('Delete'));
    await _settleTranslations(tester);

    expect(find.text('Delete bug report?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await _settleTranslations(tester);
    expect(await repository.getBugById('bug-001'), isNotNull);

    await tester.tap(find.byIcon(Icons.more_vert));
    await _settleTranslations(tester);
    await tester.tap(find.text('Delete'));
    await _settleTranslations(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await _settleTranslations(tester);

    expect(await repository.getBugById('bug-001'), isNull);
    expect(find.text('Search bugs...'), findsWidgets);
    expect(find.text('Bug report deleted.'), findsOneWidget);
  });
}

Widget _app(InMemoryBugRepository repository) {
  return BugPilotApp(
    initialLocale: const Locale('en'),
    saveLocale: false,
    bugRepository: repository,
    aiAnalysisService: const MockAiBugAnalysisService(delay: Duration.zero),
  );
}

Future<void> _openDetail(WidgetTester tester) async {
  await tester.tap(find.text('BUGS'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Login button stuck loading'));
  await tester.pumpAndSettle();
}

BugReport _analyzedBug() {
  return BugReport(
    id: 'bug-001',
    title: 'Login button stuck loading',
    description: 'The login screen remains loading after valid credentials.',
    expectedBehavior: 'The user should be redirected to the dashboard.',
    actualBehavior: 'The loading indicator remains visible indefinitely.',
    platform: BugPlatform.android,
    device: 'Pixel 9',
    osVersion: 'Android 16',
    appVersion: '1.0.0',
    logs: 'Navigation callback did not run.',
    severity: BugSeverity.high,
    priority: BugPriority.p1,
    status: BugStatus.open,
    reproductionSteps: const ['Open login', 'Submit credentials'],
    testCases: const [
      BugTestCase(
        id: 'TC-01',
        title: 'Valid login redirects',
        given: 'A user has valid credentials',
        when: 'The login form is submitted',
        then: 'The dashboard is shown',
        type: BugTestCaseType.positive,
      ),
    ],
    possibleRootCause: 'Navigation callback may not run.',
    rootCauseConfidence: 0.72,
    createdAt: DateTime.utc(2026, 8, 19, 9),
    updatedAt: DateTime.utc(2026, 8, 19, 10),
  );
}

BugReport _manualBug() {
  return BugReport(
    id: 'bug-002',
    title: 'Manual profile issue',
    description: 'The avatar disappears after restarting the app.',
    expectedBehavior: 'The avatar should remain visible.',
    actualBehavior: 'The avatar resets to initials.',
    platform: BugPlatform.ios,
    status: BugStatus.open,
    createdAt: DateTime.utc(2026, 8, 18, 9),
    updatedAt: DateTime.utc(2026, 8, 18, 9),
  );
}

Future<void> _settleTranslations(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

class _FailingDeleteRepository extends InMemoryBugRepository {
  _FailingDeleteRepository({super.seedBugs});
  @override
  Future<void> deleteBug(String id) async =>
      throw StateError('Storage unavailable');
}
