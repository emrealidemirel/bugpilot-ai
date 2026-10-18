import 'package:bugpilot_ai/app/app.dart';
import 'package:bugpilot_ai/services/mock_ai_bug_analysis_service.dart';
import 'package:bugpilot_ai/models/ai_analysis_preferences.dart';
import 'package:bugpilot_ai/models/ai_bug_analysis.dart';
import 'package:bugpilot_ai/services/ai_bug_analysis_service.dart';
import 'package:bugpilot_ai/repositories/in_memory_bug_repository.dart';
import 'package:bugpilot_ai/models/bug_platform.dart';
import 'package:bugpilot_ai/models/bug_priority.dart';
import 'package:bugpilot_ai/models/bug_severity.dart';
import 'package:bugpilot_ai/models/bug_status.dart';
import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:bugpilot_ai/models/duplicate_check_result.dart';
import 'package:bugpilot_ai/models/similar_bug_candidate.dart';
import 'package:bugpilot_ai/services/bug_duplicate_detection_service.dart';
import 'package:bugpilot_ai/repositories/in_memory_settings_repository.dart';
import 'package:bugpilot_ai/models/app_settings.dart';
import 'package:bugpilot_ai/controllers/settings_controller.dart';
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

  testWidgets('shows similar bugs and continues without losing draft', (
    tester,
  ) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = InMemoryBugRepository(seedBugs: [_similarLoginBug()]);
    final analysisService = _CapturingAnalysisService();
    final duplicateService = _FakeDuplicateDetectionService(
      result: DuplicateCheckResult(
        matches: const [
          DuplicateMatch(
            bugId: 'bug-001',
            similarity: DuplicateSimilarity.likelyDuplicate,
            confidence: 0.83,
            reason: 'Both reports describe login remaining stuck.',
          ),
        ],
      ),
    );

    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      BugPilotApp(
        initialLocale: const Locale('en'),
        saveLocale: false,
        bugRepository: repository,
        aiAnalysisService: analysisService,
        duplicateDetectionService: duplicateService,
      ),
    );
    await _settleTranslations(tester);

    await tester.tap(find.text('REPORT'));
    await _settleTranslations(tester);
    await _fillLoginBugForm(tester);

    await tester.ensureVisible(find.text('Analyze with AI'));
    await tester.tap(find.text('Analyze with AI'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Similar bugs found'), findsOneWidget);
    expect(find.text('Existing login spinner never clears'), findsOneWidget);
    expect(find.text('Possible Duplicate'), findsOneWidget);
    expect(duplicateService.callCount, 1);
    expect(duplicateService.lastCandidates, hasLength(1));

    await tester.scrollUntilVisible(
      find.text('Continue Anyway'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Continue Anyway'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(
      find.text(
        'AI has drafted triage metadata, reproduction guidance and QA coverage from your report.',
      ),
      findsOneWidget,
    );
    expect(analysisService.lastBug?.title, 'Login button stuck loading');
    expect(analysisService.lastBug?.actualBehavior, contains('spinner'));
    expect(await repository.getBugs(), hasLength(1));
  });

  testWidgets('skips remote duplicate check when no local candidates exist', (
    tester,
  ) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final duplicateService = _FakeDuplicateDetectionService(
      result: DuplicateCheckResult(matches: const []),
    );

    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      BugPilotApp(
        initialLocale: const Locale('en'),
        saveLocale: false,
        bugRepository: InMemoryBugRepository(seedBugs: [_profileImageBug()]),
        aiAnalysisService: _CapturingAnalysisService(),
        duplicateDetectionService: duplicateService,
      ),
    );
    await _settleTranslations(tester);

    await tester.tap(find.text('REPORT'));
    await _settleTranslations(tester);
    await _fillLoginBugForm(tester);

    await tester.ensureVisible(find.text('Analyze with AI'));
    await tester.tap(find.text('Analyze with AI'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('Similar bugs found'), findsNothing);
    expect(
      find.text(
        'AI has drafted triage metadata, reproduction guidance and QA coverage from your report.',
      ),
      findsOneWidget,
    );
    expect(duplicateService.callCount, 0);
  });

  testWidgets('prefills a fresh report with default environment settings', (
    tester,
  ) async {
    const settings = AppSettings(
      defaultPlatform: BugPlatform.android,
      defaultDevice: 'Pixel 9',
      defaultOsVersion: 'Android 16',
      defaultAppVersion: '2.3.0',
    );
    final settingsController = SettingsController(
      repository: InMemorySettingsRepository(initialSettings: settings),
      initialSettings: settings,
    );

    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      BugPilotApp(
        initialLocale: const Locale('en'),
        saveLocale: false,
        bugRepository: InMemoryBugRepository(seedBugs: []),
        settingsController: settingsController,
      ),
    );
    await _settleTranslations(tester);

    await tester.tap(find.text('REPORT'));
    await _settleTranslations(tester);

    expect(find.text('Android'), findsOneWidget);
    expect(find.text('Pixel 9'), findsOneWidget);
    expect(find.text('Android 16'), findsOneWidget);
    expect(find.text('2.3.0'), findsOneWidget);
  });

  testWidgets('skips local and remote duplicate detection when disabled', (
    tester,
  ) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final duplicateService = _FakeDuplicateDetectionService(
      result: DuplicateCheckResult(matches: const []),
    );
    const settings = AppSettings(duplicateDetectionEnabled: false);
    final settingsController = SettingsController(
      repository: InMemorySettingsRepository(initialSettings: settings),
      initialSettings: settings,
    );

    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      BugPilotApp(
        initialLocale: const Locale('en'),
        saveLocale: false,
        bugRepository: InMemoryBugRepository(seedBugs: [_similarLoginBug()]),
        aiAnalysisService: _CapturingAnalysisService(),
        duplicateDetectionService: duplicateService,
        settingsController: settingsController,
      ),
    );
    await _settleTranslations(tester);

    await tester.tap(find.text('REPORT'));
    await _settleTranslations(tester);
    await _fillLoginBugForm(tester);

    await tester.ensureVisible(find.text('Analyze with AI'));
    await tester.tap(find.text('Analyze with AI'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('Similar bugs found'), findsNothing);
    expect(
      find.text(
        'AI has drafted triage metadata, reproduction guidance and QA coverage from your report.',
      ),
      findsOneWidget,
    );
    expect(duplicateService.callCount, 0);
  });
}

Future<void> _fillLoginBugForm(WidgetTester tester) async {
  await tester.enterText(
    find.byType(TextFormField).at(0),
    'Login button stuck loading',
  );
  await tester.enterText(
    find.byType(TextFormField).at(1),
    'The login screen remains loading after valid credentials.',
  );
  await tester.enterText(
    find.byType(TextFormField).at(2),
    'The dashboard should open.',
  );
  await tester.enterText(
    find.byType(TextFormField).at(3),
    'The login spinner remains visible forever.',
  );
  final platformField = find.byType(DropdownButtonFormField<BugPlatform>);
  await tester.ensureVisible(platformField);
  await tester.tap(platformField);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Android').last);
  await tester.pumpAndSettle();
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
    String languageCode = 'en',
  }) {
    lastBug = bug;
    return _mock.analyze(
      bug,
      preferences: preferences,
      languageCode: languageCode,
    );
  }
}

class _FakeDuplicateDetectionService implements BugDuplicateDetectionService {
  _FakeDuplicateDetectionService({required this.result});

  final DuplicateCheckResult result;
  int callCount = 0;
  List<SimilarBugCandidate> lastCandidates = const [];

  @override
  Future<DuplicateCheckResult> checkDuplicates({
    required BugReport draft,
    required List<SimilarBugCandidate> candidates,
    String languageCode = 'en',
  }) async {
    callCount++;
    lastCandidates = candidates;
    return result;
  }
}

BugReport _similarLoginBug() {
  return _bug(
    id: 'bug-001',
    title: 'Existing login spinner never clears',
    description: 'Valid login submits but stays loading.',
    expectedBehavior: 'The dashboard should open.',
    actualBehavior: 'The login spinner remains visible forever.',
  );
}

BugReport _profileImageBug() {
  return _bug(
    id: 'bug-002',
    title: 'Profile image disappears',
    description: 'The avatar disappears after refreshing profile.',
    expectedBehavior: 'The profile image should stay visible.',
    actualBehavior: 'The avatar area is blank.',
  );
}

BugReport _bug({
  required String id,
  required String title,
  required String description,
  required String expectedBehavior,
  required String actualBehavior,
}) {
  return BugReport(
    id: id,
    title: title,
    description: description,
    expectedBehavior: expectedBehavior,
    actualBehavior: actualBehavior,
    platform: BugPlatform.android,
    severity: BugSeverity.high,
    priority: BugPriority.p1,
    status: BugStatus.open,
    createdAt: DateTime.utc(2026, 8, 19),
    updatedAt: DateTime.utc(2026, 8, 19),
  );
}

Future<void> _settleTranslations(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}
