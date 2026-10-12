import 'package:bugpilot_ai/app/app.dart';
import 'package:bugpilot_ai/features/ai_analysis/data/services/mock_ai_bug_analysis_service.dart';
import 'package:bugpilot_ai/features/ai_analysis/domain/models/ai_analysis_preferences.dart';
import 'package:bugpilot_ai/features/ai_analysis/domain/models/ai_bug_analysis.dart';
import 'package:bugpilot_ai/features/ai_analysis/domain/services/ai_bug_analysis_service.dart';
import 'package:bugpilot_ai/features/bug_reports/data/repositories/in_memory_bug_repository.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_platform.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_priority.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_severity.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_status.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/models/bug_report.dart';
import 'package:bugpilot_ai/features/settings/data/repositories/in_memory_settings_repository.dart';
import 'package:bugpilot_ai/features/settings/presentation/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    binding.platformDispatcher.localeTestValue = const Locale('en');
  });

  tearDown(() {
    binding.platformDispatcher.clearLocaleTestValue();
  });

  testWidgets('renders dashboard summary and recent bugs', (tester) async {
    await tester.pumpWidget(BugPilotApp(bugRepository: _dashboardRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('TOTAL BUGS'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2));
    expect(find.text('Recent Bugs'), findsOneWidget);
    expect(find.text('Report Bug'), findsNothing);
    expect(find.text('Newest bug'), findsOneWidget);
    expect(find.text('Middle bug'), findsOneWidget);
    expect(find.text('Third newest bug'), findsOneWidget);
    expect(find.text('Oldest bug'), findsNothing);
    expect(find.text('BUGS'), findsOneWidget);
    expect(find.text('REPORT'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
  });

  testWidgets('dashboard actions navigate to existing tabs', (tester) async {
    await tester.pumpWidget(const BugPilotApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('REPORT'));
    await tester.pumpAndSettle();

    expect(find.text('Report a Bug'), findsOneWidget);
    expect(find.text('BUG TITLE'), findsOneWidget);

    await tester.tap(find.text('DASHBOARD'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VIEW ALL'));
    await tester.pumpAndSettle();

    expect(
      find.text('Track, review and manage reported issues.'),
      findsOneWidget,
    );
    expect(find.text('Login button stuck loading'), findsOneWidget);
  });

  testWidgets('creates a bug report from the report form', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = InMemoryBugRepository(seedBugs: []);
    final analysisService = _CapturingAnalysisService();

    await tester.pumpWidget(
      BugPilotApp(
        bugRepository: repository,
        aiAnalysisService: analysisService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('REPORT'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Crash on launch');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'The app crashes immediately after launch.',
    );
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'The dashboard should open.',
    );
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'The app closes before the dashboard appears.',
    );
    await tester.ensureVisible(find.text('PLATFORM'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<BugPlatform>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Android').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(4), 'Pixel 9');

    await tester.ensureVisible(find.text('Analyze with AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analyze with AI'));
    await tester.pumpAndSettle();

    expect(find.text('AI Analysis'), findsOneWidget);
    expect(
      find.text('Review the suggestions before saving the bug report.'),
      findsOneWidget,
    );
    expect(analysisService.lastBug?.title, 'Crash on launch');
    expect(analysisService.lastBug?.device, 'Pixel 9');

    expect(await repository.getBugs(), isEmpty);

    await tester.ensureVisible(find.text('SAVE BUG REPORT'));
    await tester.tap(find.text('SAVE BUG REPORT'));
    await tester.pumpAndSettle();

    expect(find.text('Bug report saved successfully.'), findsOneWidget);
    expect(find.text('Crash on launch'), findsOneWidget);

    final bugs = await repository.getBugs();
    expect(bugs, hasLength(1));
    expect(bugs.single.title, 'Crash on launch');
    expect(bugs.single.device, 'Pixel 9');
    expect(bugs.single.severity, BugSeverity.high);
    expect(bugs.single.priority, BugPriority.p1);
    expect(bugs.single.reproductionSteps, isNotEmpty);
    expect(bugs.single.testCases, isNotEmpty);
    expect(bugs.single.status, BugStatus.open);
  });

  testWidgets('switches the interface language from settings', (tester) async {
    await tester.pumpWidget(const BugPilotApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(
      find.text('Choose the interface language for BugPilot AI.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Türkçe'));
    await tester.tap(find.text('Türkçe'));
    await tester.pumpAndSettle();

    expect(find.text('Dil'), findsOneWidget);
    expect(find.text('BugPilot AI arayüz dilini seçin.'), findsOneWidget);
    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(find.text('BUGS'), findsOneWidget);
    expect(find.text('REPORT'), findsOneWidget);
    expect(find.text('SETTINGS'), findsWidgets);
  });

  testWidgets('renders settings sections and switches to dark theme', (
    tester,
  ) async {
    final settingsController = SettingsController(
      repository: InMemorySettingsRepository(),
    );

    await tester.pumpWidget(
      BugPilotApp(settingsController: settingsController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('AI Preferences'), findsOneWidget);
    expect(find.text('Default Environment'), findsOneWidget);
    expect(find.text('Privacy & AI'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('Settings').first)).brightness,
      Brightness.dark,
    );

    await tester.ensureVisible(find.text('Severity Suggestion'));
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(settingsController.settings.aiSeverityEnabled, isFalse);
  });
}

class _CapturingAnalysisService implements AiBugAnalysisService {
  final MockAiBugAnalysisService _mock = const MockAiBugAnalysisService(
    delay: Duration.zero,
  );

  BugReport? lastBug;

  @override
  Future<AiBugAnalysis> analyze(
    BugReport bug, {
    AiAnalysisPreferences preferences = AiAnalysisPreferences.defaults,
  }) {
    lastBug = bug;
    return _mock.analyze(bug, preferences: preferences);
  }
}

InMemoryBugRepository _dashboardRepository() {
  return InMemoryBugRepository(
    seedBugs: [
      _bugReport(
        id: 'bug-001',
        title: 'Newest bug',
        severity: BugSeverity.critical,
        status: BugStatus.open,
        createdAt: DateTime.utc(2026, 8, 19, 9),
      ),
      _bugReport(
        id: 'bug-002',
        title: 'Middle bug',
        severity: BugSeverity.high,
        status: BugStatus.open,
        createdAt: DateTime.utc(2026, 8, 18, 9),
      ),
      _bugReport(
        id: 'bug-003',
        title: 'Third newest bug',
        severity: BugSeverity.medium,
        status: BugStatus.resolved,
        createdAt: DateTime.utc(2026, 8, 17, 9),
      ),
      _bugReport(
        id: 'bug-004',
        title: 'Oldest bug',
        severity: BugSeverity.low,
        status: BugStatus.closed,
        createdAt: DateTime.utc(2026, 8, 16, 9),
      ),
      _bugReport(
        id: 'bug-005',
        title: 'Older bug',
        severity: BugSeverity.medium,
        status: BugStatus.inProgress,
        createdAt: DateTime.utc(2026, 8, 15, 9),
      ),
    ],
  );
}

BugReport _bugReport({
  required String id,
  required String title,
  required BugSeverity severity,
  required BugStatus status,
  required DateTime createdAt,
}) {
  return BugReport(
    id: id,
    title: title,
    description: '$title description',
    expectedBehavior: 'The feature should work as expected.',
    actualBehavior: 'The feature does not work as expected.',
    platform: BugPlatform.android,
    severity: severity,
    priority: BugPriority.p1,
    status: status,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}
