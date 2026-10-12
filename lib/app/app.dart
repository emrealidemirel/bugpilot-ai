import 'package:flutter/material.dart';

import 'config/app_config.dart';
import '../l10n/generated/app_localizations.dart';
import '../features/ai_analysis/data/clients/http_ai_analysis_api_client.dart';
import '../features/ai_analysis/data/services/mock_ai_bug_analysis_service.dart';
import '../features/ai_analysis/data/services/remote_ai_bug_analysis_service.dart';
import '../features/ai_analysis/domain/services/ai_bug_analysis_service.dart';
import '../features/bug_reports/data/repositories/in_memory_bug_repository.dart';
import '../features/bug_reports/domain/repositories/bug_repository.dart';
import '../features/duplicate_detection/data/clients/http_duplicate_detection_api_client.dart';
import '../features/duplicate_detection/data/services/mock_bug_duplicate_detection_service.dart';
import '../features/duplicate_detection/data/services/remote_bug_duplicate_detection_service.dart';
import '../features/duplicate_detection/domain/services/bug_duplicate_detection_service.dart';
import '../features/settings/data/repositories/in_memory_settings_repository.dart';
import '../features/settings/domain/models/app_theme_mode.dart' as settings;
import '../features/settings/presentation/controllers/settings_controller.dart';
import 'localization/locale_controller.dart';
import 'localization/locale_controller_scope.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class BugPilotApp extends StatefulWidget {
  const BugPilotApp({
    this.bugRepository,
    this.aiAnalysisService,
    this.duplicateDetectionService,
    this.settingsController,
    super.key,
  });

  final BugRepository? bugRepository;
  final AiBugAnalysisService? aiAnalysisService;
  final BugDuplicateDetectionService? duplicateDetectionService;
  final SettingsController? settingsController;

  @override
  State<BugPilotApp> createState() => _BugPilotAppState();
}

class _BugPilotAppState extends State<BugPilotApp> {
  late final LocaleController _localeController;
  late final BugRepository _bugRepository;
  late final AiBugAnalysisService _aiAnalysisService;
  late final BugDuplicateDetectionService _duplicateDetectionService;
  late final SettingsController _settingsController;
  late final bool _ownsSettingsController;
  late final ValueNotifier<int> _reportResetSignal;
  late final ValueNotifier<int> _bugRefreshSignal;
  late final RouterConfig<Object> _router;

  @override
  void initState() {
    super.initState();
    _localeController = LocaleController();
    _bugRepository = widget.bugRepository ?? InMemoryBugRepository();
    _aiAnalysisService = widget.aiAnalysisService ?? _createAiAnalysisService();
    _duplicateDetectionService =
        widget.duplicateDetectionService ?? _createDuplicateDetectionService();
    _settingsController =
        widget.settingsController ??
        SettingsController(repository: InMemorySettingsRepository());
    _ownsSettingsController = widget.settingsController == null;
    _reportResetSignal = ValueNotifier<int>(0);
    _bugRefreshSignal = ValueNotifier<int>(0);
    _router = createAppRouter(
      bugRepository: _bugRepository,
      aiAnalysisService: _aiAnalysisService,
      duplicateDetectionService: _duplicateDetectionService,
      settingsController: _settingsController,
      reportResetSignal: _reportResetSignal,
      bugRefreshSignal: _bugRefreshSignal,
      onBugChanged: () {
        _bugRefreshSignal.value++;
      },
      onBugSaved: () {
        _reportResetSignal.value++;
        _bugRefreshSignal.value++;
      },
    );
  }

  AiBugAnalysisService _createAiAnalysisService() {
    if (AppConfig.useMockAi) {
      return const MockAiBugAnalysisService();
    }

    return RemoteAiBugAnalysisService(
      apiClient: HttpAiAnalysisApiClient(
        baseUrl: Uri.parse(AppConfig.apiBaseUrl),
        timeout: AppConfig.aiAnalysisTimeout,
      ),
    );
  }

  BugDuplicateDetectionService _createDuplicateDetectionService() {
    if (AppConfig.useMockAi) {
      return const MockBugDuplicateDetectionService();
    }

    return RemoteBugDuplicateDetectionService(
      apiClient: HttpDuplicateDetectionApiClient(
        baseUrl: Uri.parse(AppConfig.apiBaseUrl),
        timeout: AppConfig.duplicateCheckTimeout,
      ),
    );
  }

  @override
  void dispose() {
    _localeController.dispose();
    if (_ownsSettingsController) {
      _settingsController.dispose();
    }
    _reportResetSignal.dispose();
    _bugRefreshSignal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocaleControllerScope(
      controller: _localeController,
      child: AnimatedBuilder(
        animation: Listenable.merge([_localeController, _settingsController]),
        builder: (context, child) {
          return MaterialApp.router(
            title: 'BugPilot AI',
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _themeModeFor(_settingsController.settings.themeMode),
            locale: _localeController.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: _router,
          );
        },
      ),
    );
  }

  ThemeMode _themeModeFor(settings.AppThemeMode mode) {
    return switch (mode) {
      settings.AppThemeMode.system => ThemeMode.system,
      settings.AppThemeMode.light => ThemeMode.light,
      settings.AppThemeMode.dark => ThemeMode.dark,
    };
  }
}
