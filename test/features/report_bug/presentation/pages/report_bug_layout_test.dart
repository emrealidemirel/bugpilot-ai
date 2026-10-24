import 'dart:convert';
import 'dart:io';

import 'package:bugpilot_ai/theme/app_theme.dart';
import 'package:bugpilot_ai/repositories/in_memory_bug_repository.dart';
import '../../../../support/mock_bug_duplicate_detection_service.dart';
import 'package:bugpilot_ai/pages/report_bug/report_bug_page.dart';
import 'package:bugpilot_ai/repositories/in_memory_settings_repository.dart';
import 'package:bugpilot_ai/controllers/settings_controller.dart';
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
    testWidgets('report form fits narrow screen with large text in $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
          assetLoader: const _Loader(),
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              theme: language == 'tr' ? AppTheme.light : AppTheme.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: Scaffold(
                body: ReportBugPage(
                  bugRepository: InMemoryBugRepository(),
                  duplicateDetectionService:
                      const MockBugDuplicateDetectionService(),
                  settingsController: controller,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      for (var i = 0; i < fields.evaluate().length; i++) {
        await tester.ensureVisible(fields.at(i));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      final analyze = find.widgetWithText(
        FilledButton,
        'analyzeWithAiAction'.tr(),
      );
      await tester.ensureVisible(analyze);
      await tester.pumpAndSettle();
      expect(analyze.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

class _Loader extends AssetLoader {
  const _Loader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
          as Map<String, dynamic>;
}
