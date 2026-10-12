import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_shell.dart';
import '../../features/ai_analysis/domain/services/ai_bug_analysis_service.dart';
import '../../features/ai_analysis/presentation/pages/ai_analysis_page.dart';
import '../../features/bug_reports/domain/models/bug_report.dart';
import '../../features/bug_reports/domain/repositories/bug_repository.dart';
import '../../features/bug_reports/presentation/pages/bug_detail_page.dart';
import '../../features/bug_reports/presentation/pages/bug_reports_page.dart';
import '../../features/bug_reports/presentation/pages/edit_bug_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/duplicate_detection/domain/services/bug_duplicate_detection_service.dart';
import '../../features/report_bug/presentation/pages/report_bug_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/controllers/settings_controller.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _dashboardNavigatorKey = GlobalKey<NavigatorState>();
final _bugsNavigatorKey = GlobalKey<NavigatorState>();
final _reportNavigatorKey = GlobalKey<NavigatorState>();
final _settingsNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter({
  required BugRepository bugRepository,
  required AiBugAnalysisService aiAnalysisService,
  required BugDuplicateDetectionService duplicateDetectionService,
  required SettingsController settingsController,
  required ValueListenable<int> reportResetSignal,
  required ValueListenable<int> bugRefreshSignal,
  required VoidCallback onBugChanged,
  required VoidCallback onBugSaved,
}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: DashboardPage.routePath,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => DashboardPage.routePath),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _dashboardNavigatorKey,
            routes: [
              GoRoute(
                path: DashboardPage.routePath,
                pageBuilder: (context, state) => NoTransitionPage(
                  child: DashboardPage(
                    bugRepository: bugRepository,
                    refreshSignal: bugRefreshSignal,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _bugsNavigatorKey,
            routes: [
              GoRoute(
                path: BugReportsPage.routePath,
                pageBuilder: (context, state) => NoTransitionPage(
                  child: BugReportsPage(
                    bugRepository: bugRepository,
                    refreshSignal: bugRefreshSignal,
                  ),
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => BugDetailPage(
                      bugId: state.pathParameters['id']!,
                      bugRepository: bugRepository,
                      refreshSignal: bugRefreshSignal,
                      onBugChanged: onBugChanged,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) => EditBugPage(
                          bugId: state.pathParameters['id']!,
                          bugRepository: bugRepository,
                          onBugChanged: onBugChanged,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _reportNavigatorKey,
            routes: [
              GoRoute(
                path: ReportBugPage.routePath,
                pageBuilder: (context, state) => NoTransitionPage(
                  child: ReportBugPage(
                    bugRepository: bugRepository,
                    duplicateDetectionService: duplicateDetectionService,
                    settingsController: settingsController,
                    resetSignal: reportResetSignal,
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'analysis',
                    builder: (context, state) => AiAnalysisPage(
                      draft: state.extra is BugReport
                          ? state.extra! as BugReport
                          : null,
                      bugRepository: bugRepository,
                      analysisService: aiAnalysisService,
                      settingsController: settingsController,
                      onBugSaved: onBugSaved,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsNavigatorKey,
            routes: [
              GoRoute(
                path: SettingsPage.routePath,
                pageBuilder: (context, state) => NoTransitionPage(
                  child: SettingsPage(controller: settingsController),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
