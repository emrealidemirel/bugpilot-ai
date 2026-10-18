import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bugpilot_ai/theme/app_theme.dart';
import 'package:bugpilot_ai/models/ai_bug_analysis.dart';
import 'package:bugpilot_ai/models/ai_analysis_preferences.dart';
import 'package:bugpilot_ai/services/ai_bug_analysis_service.dart';
import 'package:bugpilot_ai/pages/ai_analysis/ai_analysis_page.dart';
import 'package:bugpilot_ai/models/bug_platform.dart';
import 'package:bugpilot_ai/models/bug_priority.dart';
import 'package:bugpilot_ai/models/bug_severity.dart';
import 'package:bugpilot_ai/models/bug_status.dart';
import 'package:bugpilot_ai/models/bug_test_case_type.dart';
import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:bugpilot_ai/models/bug_test_case.dart';
import 'package:bugpilot_ai/repositories/bug_repository.dart';
import 'package:bugpilot_ai/repositories/in_memory_settings_repository.dart';
import 'package:bugpilot_ai/models/app_settings.dart';
import 'package:bugpilot_ai/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  for (final language in ['tr', 'en']) {
    testWidgets('first automatic analysis works in $language', (tester) async {
      final service = _FakeAnalysisService(result: _analysis());
      final controller = SettingsController(
        repository: InMemorySettingsRepository(),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('tr'), Locale('en')],
          startLocale: Locale(language),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: const _TestTranslationLoader(),
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              theme: AppTheme.light,
              home: Scaffold(
                body: AiAnalysisPage(
                  draft: _draft(),
                  bugRepository: _FakeBugRepository(),
                  analysisService: service,
                  settingsController: controller,
                  onBugSaved: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.callCount, 1);
      expect(service.lastLanguageCode, language);
      expect(
        find.byKey(const ValueKey('ai-analysis-edit-severity')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      final pageContext = tester.element(find.byType(AiAnalysisPage));
      await pageContext.setLocale(Locale(language == 'tr' ? 'en' : 'tr'));
      await tester.pumpAndSettle();
      expect(
        service.callCount,
        1,
        reason: 'Language rebuild must not restart analysis',
      );
    });
  }

  testWidgets('renders completed mock analysis sections', (tester) async {
    await tester.pumpWidget(
      _analysisHarness(
        repository: _FakeBugRepository(),
        analysisService: _FakeAnalysisService(result: _analysis()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'AI has drafted triage metadata, reproduction guidance and QA coverage from your report.',
      ),
      findsOneWidget,
    );
    expect(find.text('Severity'), findsOneWidget);
    expect(find.text('Priority'), findsOneWidget);
    expect(find.text('Reproduction Steps'), findsOneWidget);
    expect(find.text('Test Cases'), findsOneWidget);
    expect(find.text('Possible Root Cause'), findsOneWidget);
    expect(find.text('Report Quality'), findsOneWidget);
    expect(find.text('Save Bug Report'), findsOneWidget);
  });

  testWidgets('saves one final analyzed bug report', (tester) async {
    final repository = _FakeBugRepository();

    await tester.pumpWidget(
      _analysisHarness(
        repository: repository,
        analysisService: _FakeAnalysisService(result: _analysis()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save Bug Report'));
    await tester.tap(find.text('Save Bug Report'));
    await tester.tap(find.text('Save Bug Report'));
    await tester.pumpAndSettle();

    expect(repository.createdReports, hasLength(1));
    final created = repository.createdReports.single;
    expect(created.title, 'Crash on launch');
    expect(created.description, 'The app crashes immediately after launch.');
    expect(created.severity, BugSeverity.high);
    expect(created.priority, BugPriority.p1);
    expect(created.reproductionSteps, isNotEmpty);
    expect(created.testCases, isNotEmpty);
    expect(created.possibleRootCause, 'State may not update.');
    expect(created.rootCauseConfidence, 0.72);
    expect(created.status, BugStatus.open);
  });

  testWidgets('shows retryable analysis error and does not create a bug', (
    tester,
  ) async {
    final repository = _FakeBugRepository();
    final service = _FakeAnalysisService(error: StateError('failed'));

    await tester.pumpWidget(
      _analysisHarness(repository: repository, analysisService: service),
    );
    await tester.pumpAndSettle();

    expect(find.text('Analysis failed'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(service.lastBug?.title, 'Crash on launch');
    expect(repository.createdReports, isEmpty);
  });

  testWidgets('keeps analysis visible when saving fails', (tester) async {
    final repository = _FakeBugRepository(throwOnCreate: true);

    await tester.pumpWidget(
      _analysisHarness(
        repository: repository,
        analysisService: _FakeAnalysisService(result: _analysis()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save Bug Report'));
    await tester.tap(find.text('Save Bug Report'));
    await tester.pump();

    expect(
      find.text(
        'AI has drafted triage metadata, reproduction guidance and QA coverage from your report.',
      ),
      findsOneWidget,
    );
    expect(find.text('Severity'), findsOneWidget);
    expect(
      find.text('Could not save the bug report. Please try again.'),
      findsWidgets,
    );
  });

  testWidgets('saves manually edited AI recommendations', (tester) async {
    final repository = _FakeBugRepository();

    await tester.pumpWidget(
      _analysisHarness(
        repository: repository,
        analysisService: _FakeAnalysisService(result: _analysis()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ai-analysis-edit-severity')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Critical'));
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ai-analysis-edit-priority')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Immediate'));
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Reproduction Steps'));
    await tester.tap(
      find.byKey(const ValueKey('ai-analysis-edit-reproduction-steps')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), ' Open app again ');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add Test Case'));
    await tester.tap(find.text('Add Test Case'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Manual coverage');
    await tester.enterText(find.byType(TextField).at(1), 'A reviewer exists');
    await tester.enterText(find.byType(TextField).at(2), 'They save the bug');
    await tester.enterText(
      find.byType(TextField).at(3),
      'Manual case is saved',
    );
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Possible Root Cause'));
    await tester.tap(find.byKey(const ValueKey('ai-analysis-edit-root-cause')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).at(0),
      'Navigation callback may be skipped.',
    );
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save Bug Report'));
    await tester.tap(find.text('Save Bug Report'));
    await tester.pumpAndSettle();

    final created = repository.createdReports.single;
    expect(created.severity, BugSeverity.critical);
    expect(created.priority, BugPriority.p0);
    expect(created.reproductionSteps.first, 'Open app again');
    expect(created.testCases.last.id, 'TC-02');
    expect(created.testCases.last.title, 'Manual coverage');
    expect(created.possibleRootCause, 'Navigation callback may be skipped.');
  });

  testWidgets('regenerates only the selected section', (tester) async {
    final repository = _FakeBugRepository();

    await tester.pumpWidget(
      _analysisHarness(
        repository: repository,
        analysisService: _FakeAnalysisService(
          results: [
            _analysis(),
            _analysis().copyWith(
              severity: BugSeverity.low,
              priority: BugPriority.p3,
              reproductionSteps: const ['Regenerated step'],
              testCases: const [
                BugTestCase(
                  id: 'TC-09',
                  type: BugTestCaseType.negative,
                  title: 'Regenerated test case',
                  given: 'A refreshed analysis exists',
                  when: 'The selected section is regenerated',
                  then: 'Only test cases are replaced',
                ),
              ],
              possibleRootCause: 'Regenerated root cause.',
              rootCauseConfidence: 0.31,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ai-analysis-edit-severity')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Critical'));
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add Test Case'));
    final regenerateTestCases = find.byKey(
      const ValueKey('ai-analysis-regenerate-test-cases'),
    );
    await tester.ensureVisible(regenerateTestCases);
    await tester.tap(regenerateTestCases);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save Bug Report'));
    await tester.tap(find.text('Save Bug Report'));
    await tester.pumpAndSettle();

    final created = repository.createdReports.single;
    expect(created.severity, BugSeverity.critical);
    expect(created.priority, BugPriority.p1);
    expect(created.reproductionSteps, ['Open app', 'Tap Login']);
    expect(created.testCases.single.title, 'Regenerated test case');
    expect(created.possibleRootCause, 'State may not update.');
    expect(created.rootCauseConfidence, 0.72);
  });

  testWidgets('hides disabled test cases and root cause and saves nulls', (
    tester,
  ) async {
    final repository = _FakeBugRepository();
    final service = _FakeAnalysisService(
      result: _analysis().copyWith(
        testCases: const [],
        possibleRootCause: null,
        rootCauseConfidence: null,
      ),
    );

    await tester.pumpWidget(
      _analysisHarness(
        repository: repository,
        analysisService: service,
        settings: const AppSettings(
          aiTestCasesEnabled: false,
          aiRootCauseEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Cases'), findsNothing);
    expect(find.text('Possible Root Cause'), findsNothing);
    expect(service.lastPreferences?.testCases, isFalse);
    expect(service.lastPreferences?.rootCause, isFalse);

    await tester.ensureVisible(find.text('Save Bug Report'));
    await tester.tap(find.text('Save Bug Report'));
    await tester.pumpAndSettle();

    final created = repository.createdReports.single;
    expect(created.testCases, isEmpty);
    expect(created.possibleRootCause, isNull);
    expect(created.rootCauseConfidence, isNull);
  });

  testWidgets('handles disabled severity and priority recommendations', (
    tester,
  ) async {
    await tester.pumpWidget(
      _analysisHarness(
        repository: _FakeBugRepository(),
        analysisService: _FakeAnalysisService(
          result: _analysis().copyWith(
            severity: null,
            severityReason: null,
            priority: null,
            priorityReason: null,
          ),
        ),
        settings: const AppSettings(
          aiSeverityEnabled: false,
          aiPriorityEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Severity'), findsOneWidget);
    expect(find.text('Priority'), findsOneWidget);
    expect(find.text('Not generated'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('ai-analysis-regenerate-severity')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('ai-analysis-regenerate-priority')),
      findsNothing,
    );
  });
}

Widget _analysisHarness({
  required BugRepository repository,
  required AiBugAnalysisService analysisService,
  AppSettings settings = AppSettings.defaults,
}) {
  final settingsController = SettingsController(
    repository: InMemorySettingsRepository(initialSettings: settings),
    initialSettings: settings,
  );
  addTearDown(settingsController.dispose);

  final router = GoRouter(
    initialLocation: AiAnalysisPage.routePath,
    routes: [
      GoRoute(
        path: AiAnalysisPage.routePath,
        builder: (context, state) => Scaffold(
          body: AiAnalysisPage(
            draft: _draft(),
            bugRepository: repository,
            analysisService: analysisService,
            settingsController: settingsController,
            onBugSaved: () {},
          ),
        ),
      ),
      GoRoute(
        path: '/bugs',
        builder: (context, state) => const Scaffold(body: Text('Bugs page')),
      ),
    ],
  );
  addTearDown(router.dispose);

  return EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('tr')],
    startLocale: const Locale('en'),
    saveLocale: false,
    path: 'assets/translations',
    assetLoader: const _TestTranslationLoader(),
    child: Builder(
      builder: (context) => MaterialApp.router(
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
}

AiBugAnalysis _analysis() {
  return AiBugAnalysis(
    severity: BugSeverity.high,
    severityReason: 'Blocks a core workflow.',
    priority: BugPriority.p1,
    priorityReason: 'Needs attention soon.',
    reproductionSteps: const ['Open app', 'Tap Login'],
    testCases: const [
      BugTestCase(
        id: 'TC-01',
        type: BugTestCaseType.positive,
        title: 'Expected flow completes successfully',
        given: 'A user is on the login screen',
        when: 'The valid action is performed',
        then: 'The dashboard opens',
      ),
    ],
    possibleRootCause: 'State may not update.',
    rootCauseConfidence: 0.72,
    missingInformation: const ['Error logs were not provided.'],
    qualityScore: 82,
  );
}

BugReport _draft() {
  return BugReport(
    id: 'bug-001',
    title: 'Crash on launch',
    description: 'The app crashes immediately after launch.',
    expectedBehavior: 'The dashboard should open.',
    actualBehavior: 'The app closes before the dashboard appears.',
    platform: BugPlatform.android,
    status: BugStatus.open,
    createdAt: DateTime.utc(2026, 8, 19),
    updatedAt: DateTime.utc(2026, 8, 19),
  );
}

class _FakeAnalysisService implements AiBugAnalysisService {
  _FakeAnalysisService({
    AiBugAnalysis? result,
    List<AiBugAnalysis>? results,
    this.error,
  }) : results = results ?? [?result];

  final List<AiBugAnalysis> results;
  final Object? error;
  BugReport? lastBug;
  AiAnalysisPreferences? lastPreferences;
  int callCount = 0;
  String? lastLanguageCode;

  @override
  Future<AiBugAnalysis> analyze(
    BugReport bug, {
    AiAnalysisPreferences preferences = AiAnalysisPreferences.defaults,
    String languageCode = 'en',
  }) async {
    lastLanguageCode = languageCode;
    lastBug = bug;
    lastPreferences = preferences;
    callCount += 1;
    final error = this.error;
    if (error != null) {
      throw error;
    }

    if (results.isEmpty) {
      throw StateError('No fake analysis result configured');
    }

    final resultIndex = (callCount - 1).clamp(0, results.length - 1);
    return results[resultIndex];
  }
}

class _FakeBugRepository implements BugRepository {
  _FakeBugRepository({this.throwOnCreate = false});

  final bool throwOnCreate;
  final List<BugReport> createdReports = [];

  @override
  Future<void> createBug(BugReport bug) async {
    if (createdReports.any((existing) => existing.id == bug.id)) {
      throw StateError('Duplicate bug');
    }
    if (throwOnCreate) {
      throw StateError('Create failed');
    }
    createdReports.add(bug);
  }

  @override
  Future<void> deleteBug(String id) async {}

  @override
  Future<BugReport?> getBugById(String id) async => null;

  @override
  Future<List<BugReport>> getBugs() async => createdReports;

  @override
  Future<void> updateBug(BugReport bug) async {}
}

class _TestTranslationLoader extends AssetLoader {
  const _TestTranslationLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return jsonDecode(
          File('$path/${locale.languageCode}.json').readAsStringSync(),
        )
        as Map<String, dynamic>;
  }
}
