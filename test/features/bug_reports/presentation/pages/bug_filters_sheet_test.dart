import 'package:bugpilot_ai/utils/bug_report_filters.dart';
import 'package:bugpilot_ai/theme/app_theme.dart';
import 'dart:convert';
import 'dart:io';

import 'package:bugpilot_ai/repositories/in_memory_bug_repository.dart';
import 'package:bugpilot_ai/models/bug_platform.dart';
import 'package:bugpilot_ai/models/bug_severity.dart';
import 'package:bugpilot_ai/models/bug_status.dart';
import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:bugpilot_ai/pages/bug_reports/bug_reports_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  for (final language in ['tr', 'en']) {
    testWidgets('filters apply and clear on a small screen in $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final signal = ValueNotifier(0);
      addTearDown(signal.dispose);
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('tr'), Locale('en')],
          startLocale: Locale(language),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: const _Loader(),
          child: Builder(
            builder: (context) => MaterialApp(
              theme: AppTheme.light,
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(
                body: BugReportsPage(
                  bugRepository: InMemoryBugRepository(
                    seedBugs: [
                      _bug('Critical report', BugSeverity.critical),
                      _bug('Low report', BugSeverity.low),
                    ],
                  ),
                  refreshSignal: signal,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<BugSeverity?>));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(language == 'tr' ? 'Kritik' : 'Critical').last,
      );
      await tester.pumpAndSettle();
      final apply = find.widgetWithText(FilledButton, 'applyAction'.tr());
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(find.text('Critical report'), findsOneWidget);
      expect(find.text('Low report'), findsNothing);
      expect(find.byType(InputChip), findsOneWidget);

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      final clear = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextButton),
      );
      await tester.ensureVisible(clear);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      final severity = tester.state<FormFieldState<BugSeverity?>>(
        find.byType(DropdownButtonFormField<BugSeverity?>),
      );
      expect(severity.value, isNull);
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(find.text('Critical report'), findsOneWidget);
      expect(find.text('Low report'), findsOneWidget);
      expect(find.byType(InputChip), findsNothing);

      expect(
        find.byType(DropdownButtonFormField<BugReportSortOption>),
        findsNothing,
      );
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      final sortField = find.byType(
        DropdownButtonFormField<BugReportSortOption>,
      );
      await tester.tap(sortField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('oldestSort'.tr()).last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      expect(
        tester.state<FormFieldState<BugReportSortOption>>(sortField).value,
        BugReportSortOption.oldest,
      );
      await tester.ensureVisible(clear);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(
        tester.state<FormFieldState<BugReportSortOption>>(sortField).value,
        BugReportSortOption.newest,
      );
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

BugReport _bug(String title, BugSeverity severity) => BugReport(
  id: title,
  title: title,
  description: 'Example description',
  expectedBehavior: 'Expected',
  actualBehavior: 'Actual',
  platform: BugPlatform.ios,
  severity: severity,
  status: BugStatus.open,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class _Loader extends AssetLoader {
  const _Loader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
          as Map<String, dynamic>;
}
