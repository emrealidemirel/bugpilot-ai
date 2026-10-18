import 'dart:typed_data';

import 'package:bugpilot_ai/app/app.dart';
import 'package:bugpilot_ai/models/auth_user.dart';
import 'package:bugpilot_ai/services/auth_service.dart';
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
import 'package:bugpilot_ai/repositories/in_memory_settings_repository.dart';
import 'package:bugpilot_ai/controllers/settings_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
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

  testWidgets('renders dashboard summary and recent bugs', (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      BugPilotApp(
        initialLocale: const Locale('en'),
        saveLocale: false,
        bugRepository: _dashboardRepository(),
      ),
    );
    await _settleTranslations(tester);

    expect(find.text('Good afternoon'), findsWidgets);
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
    await tester.pumpWidget(
      BugPilotApp(
        initialLocale: const Locale('en'),
        saveLocale: false,
        bugRepository: _dashboardRepository(),
      ),
    );
    await _settleTranslations(tester);

    await tester.tap(find.text('REPORT'));
    await _settleTranslations(tester);

    expect(find.text('Issue'), findsOneWidget);
    expect(find.text('Bug Title'), findsOneWidget);

    await tester.tap(find.text('DASHBOARD'));
    await _settleTranslations(tester);
    await tester.tap(find.text('VIEW ALL'));
    await _settleTranslations(tester);

    expect(find.text('Search bugs...'), findsOneWidget);
    expect(find.text('Newest bug'), findsOneWidget);
  });

  testWidgets('opens the profile editor from the left account button', (
    tester,
  ) async {
    await tester.pumpWidget(
      BugPilotApp(
        initialLocale: const Locale('en'),
        saveLocale: false,
        bugRepository: _dashboardRepository(),
      ),
    );
    await _settleTranslations(tester);

    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();

    expect(find.text('Your profile'), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Good afternoon'), findsWidgets);
  });

  testWidgets('shows the Firebase error code in the profile message', (
    tester,
  ) async {
    await tester.pumpWidget(
      BugPilotApp(
        initialLocale: const Locale('en'),
        saveLocale: false,
        bugRepository: _dashboardRepository(),
        authService: _FailingProfileAuthService(),
      ),
    );
    await _settleTranslations(tester);

    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not update your profile. Firebase error code: unauthorized.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('creates a bug report from the report form', (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = InMemoryBugRepository(seedBugs: []);
    final analysisService = _CapturingAnalysisService();

    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      BugPilotApp(
        initialLocale: const Locale('en'),
        saveLocale: false,
        bugRepository: repository,
        aiAnalysisService: analysisService,
      ),
    );
    await _settleTranslations(tester);

    await tester.tap(find.text('REPORT'));
    await _settleTranslations(tester);

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
    await tester.ensureVisible(find.text('Platform'));
    await _settleTranslations(tester);
    await tester.tap(find.byType(DropdownButtonFormField<BugPlatform>));
    await _settleTranslations(tester);
    await tester.tap(find.text('Android').last);
    await _settleTranslations(tester);
    await tester.enterText(find.byType(TextFormField).at(4), 'Pixel 9');

    await tester.ensureVisible(find.text('Analyze with AI'));
    await _settleTranslations(tester);
    await tester.tap(find.text('Analyze with AI'));
    await _settleTranslations(tester);

    expect(
      find.text(
        'AI has drafted triage metadata, reproduction guidance and QA coverage from your report.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'AI has drafted triage metadata, reproduction guidance and QA coverage from your report.',
      ),
      findsOneWidget,
    );
    expect(analysisService.lastBug?.title, 'Crash on launch');
    expect(analysisService.lastBug?.device, 'Pixel 9');

    expect(await repository.getBugs(), isEmpty);

    await tester.ensureVisible(find.text('Save Bug Report'));
    await tester.tap(find.text('Save Bug Report'));
    await _settleTranslations(tester);

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
    await tester.pumpWidget(
      const BugPilotApp(initialLocale: Locale('en'), saveLocale: false),
    );
    await _settleTranslations(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await _settleTranslations(tester);

    expect(find.text('Language'), findsOneWidget);
    expect(
      find.text('Choose the interface language for BugPilot AI.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Türkçe'));
    await tester.tap(find.text('Türkçe'));
    await _settleTranslations(tester);

    expect(find.text('Dil'), findsOneWidget);
    expect(find.text('BugPilot AI arayüz dilini seçin.'), findsOneWidget);
    expect(find.text('PANEL'), findsOneWidget);
    expect(find.text('HATALAR'), findsOneWidget);
    expect(find.text('BILDIR'), findsOneWidget);
    expect(find.text('AYARLAR'), findsWidgets);
  });

  testWidgets('renders settings sections and switches to dark theme', (
    tester,
  ) async {
    final settingsController = SettingsController(
      repository: InMemorySettingsRepository(),
    );

    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      BugPilotApp(
        initialLocale: const Locale('en'),
        saveLocale: false,
        settingsController: settingsController,
      ),
    );
    await _settleTranslations(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await _settleTranslations(tester);

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('AI Preferences'), findsOneWidget);
    expect(find.text('Default Environment'), findsOneWidget);
    expect(find.text('Privacy & AI'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await _settleTranslations(tester);

    expect(
      Theme.of(tester.element(find.text('Appearance'))).brightness,
      Brightness.dark,
    );

    await tester.ensureVisible(find.text('Severity Suggestion'));
    await tester.tap(find.byType(Switch).first);
    await _settleTranslations(tester);

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

class _FailingProfileAuthService implements AuthService {
  @override
  AuthUser? get currentUser => const AuthUser(
    id: 'test-user',
    email: 'alex@example.com',
    displayName: 'Alex Example',
  );

  @override
  Stream<AuthUser?> get userChanges =>
      Stream<AuthUser?>.value(currentUser).asBroadcastStream();

  @override
  Future<void> createAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    Uint8List? photoBytes,
    String? photoContentType,
  }) async {
    throw FirebaseException(plugin: 'firebase_storage', code: 'unauthorized');
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

Future<void> _settleTranslations(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}
