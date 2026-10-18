import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'package:bugpilot_ai/constants/app_config.dart';
import 'package:bugpilot_ai/services/auth_service.dart';
import 'package:bugpilot_ai/models/auth_user.dart';
import 'package:bugpilot_ai/widgets/auth_service_scope.dart';
import 'package:bugpilot_ai/services/openai_responses_client.dart';
import 'package:bugpilot_ai/services/mock_ai_bug_analysis_service.dart';
import 'package:bugpilot_ai/services/remote_ai_bug_analysis_service.dart';
import 'package:bugpilot_ai/services/ai_bug_analysis_service.dart';
import 'package:bugpilot_ai/repositories/in_memory_bug_repository.dart';
import 'package:bugpilot_ai/repositories/bug_repository.dart';
import 'package:bugpilot_ai/services/mock_bug_duplicate_detection_service.dart';
import 'package:bugpilot_ai/services/remote_bug_duplicate_detection_service.dart';
import 'package:bugpilot_ai/services/bug_duplicate_detection_service.dart';
import 'package:bugpilot_ai/repositories/in_memory_settings_repository.dart';
import 'package:bugpilot_ai/models/app_theme_mode.dart' as settings;
import 'package:bugpilot_ai/controllers/settings_controller.dart';
import 'package:bugpilot_ai/app/router/app_router.dart';
import 'package:bugpilot_ai/theme/app_theme.dart';

class BugPilotApp extends StatefulWidget {
  const BugPilotApp({
    this.bugRepository,
    this.aiAnalysisService,
    this.duplicateDetectionService,
    this.settingsController,
    this.authService,
    this.requireAuthentication = false,
    this.initialLocale,
    this.saveLocale = true,
    super.key,
  });

  final BugRepository? bugRepository;
  final AiBugAnalysisService? aiAnalysisService;
  final BugDuplicateDetectionService? duplicateDetectionService;
  final SettingsController? settingsController;
  final AuthService? authService;
  final bool requireAuthentication;
  final Locale? initialLocale;
  final bool saveLocale;

  @override
  State<BugPilotApp> createState() => _BugPilotAppState();
}

class _BugPilotAppState extends State<BugPilotApp> {
  late final BugRepository _bugRepository;
  late final AiBugAnalysisService _aiAnalysisService;
  late final BugDuplicateDetectionService _duplicateDetectionService;
  late final SettingsController _settingsController;
  late final bool _ownsSettingsController;
  late final ValueNotifier<int> _reportResetSignal;
  late final ValueNotifier<int> _bugRefreshSignal;
  late final ValueNotifier<int> _authRefreshSignal;
  late final Stream<AuthUser?>? _authUserChanges;
  StreamSubscription<Object?>? _authSubscription;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
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
    _authRefreshSignal = ValueNotifier<int>(0);
    _authUserChanges = widget.authService?.userChanges;
    _authSubscription = _authUserChanges?.listen((_) {
      _authRefreshSignal.value++;
    });
    _router = createAppRouter(
      bugRepository: _bugRepository,
      aiAnalysisService: _aiAnalysisService,
      duplicateDetectionService: _duplicateDetectionService,
      settingsController: _settingsController,
      reportResetSignal: _reportResetSignal,
      bugRefreshSignal: _bugRefreshSignal,
      authService: widget.authService,
      requireAuthentication: widget.requireAuthentication,
      authRefreshSignal: _authRefreshSignal,
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
      apiClient: OpenAiResponsesClient(
        apiKey: AppConfig.openAiApiKey,
        model: AppConfig.openAiModel,
        timeout: AppConfig.aiAnalysisTimeout,
      ),
    );
  }

  BugDuplicateDetectionService _createDuplicateDetectionService() {
    if (AppConfig.useMockAi) {
      return const MockBugDuplicateDetectionService();
    }

    return RemoteBugDuplicateDetectionService(
      apiClient: OpenAiResponsesClient(
        apiKey: AppConfig.openAiApiKey,
        model: AppConfig.openAiModel,
        timeout: AppConfig.duplicateCheckTimeout,
      ),
    );
  }

  @override
  void dispose() {
    _router.dispose();
    if (_ownsSettingsController) {
      _settingsController.dispose();
    }
    _reportResetSignal.dispose();
    _bugRefreshSignal.dispose();
    _authSubscription?.cancel();
    _authRefreshSignal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('tr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: widget.initialLocale,
      saveLocale: widget.saveLocale,
      useOnlyLangCode: true,
      child: AnimatedBuilder(
        animation: _settingsController,
        builder: (context, child) {
          return StreamBuilder(
            stream: _authUserChanges,
            initialData: widget.authService?.currentUser,
            builder: (context, snapshot) => AuthServiceScope(
              service: widget.authService,
              user: snapshot.data,
              child: MaterialApp.router(
                title: 'BugPilot AI',
                onGenerateTitle: (context) => 'appTitle'.tr(),
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: _themeModeFor(
                  _settingsController.settings.themeMode,
                ),
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                routerConfig: _router,
              ),
            ),
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
