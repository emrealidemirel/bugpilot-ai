import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bugpilot_ai/widgets/app_shell.dart';
import 'package:bugpilot_ai/services/ai_bug_analysis_service.dart';
import 'package:bugpilot_ai/services/auth_service.dart';
import 'package:bugpilot_ai/pages/auth/sign_in_page.dart';
import 'package:bugpilot_ai/pages/auth/profile_page.dart';
import 'package:bugpilot_ai/pages/ai_analysis/ai_analysis_page.dart';
import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:bugpilot_ai/repositories/bug_repository.dart';
import 'package:bugpilot_ai/pages/bug_reports/bug_detail_page.dart';
import 'package:bugpilot_ai/pages/bug_reports/bug_reports_page.dart';
import 'package:bugpilot_ai/pages/bug_reports/edit_bug_page.dart';
import 'package:bugpilot_ai/pages/dashboard/dashboard_page.dart';
import 'package:bugpilot_ai/services/bug_duplicate_detection_service.dart';
import 'package:bugpilot_ai/pages/report_bug/report_bug_page.dart';
import 'package:bugpilot_ai/pages/settings/settings_page.dart';
import 'package:bugpilot_ai/controllers/settings_controller.dart';

GoRouter createAppRouter({
  required BugRepository bugRepository,
  required AiBugAnalysisService aiAnalysisService,
  required BugDuplicateDetectionService duplicateDetectionService,
  required SettingsController settingsController,
  required ValueListenable<int> reportResetSignal,
  required ValueListenable<int> bugRefreshSignal,
  required VoidCallback onBugChanged,
  required VoidCallback onBugSaved,
  AuthService? authService,
  bool requireAuthentication = false,
  Listenable? authRefreshSignal,
}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final dashboardNavigatorKey = GlobalKey<NavigatorState>();
  final bugsNavigatorKey = GlobalKey<NavigatorState>();
  final reportNavigatorKey = GlobalKey<NavigatorState>();
  final settingsNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: DashboardPage.routePath,
    refreshListenable: authRefreshSignal,
    redirect: (context, state) {
      if (!requireAuthentication) return null;
      final isSignIn = state.uri.path == SignInPage.routePath;
      if (authService?.currentUser == null) {
        return isSignIn ? null : SignInPage.routePath;
      }
      return isSignIn ? DashboardPage.routePath : null;
    },
    routes: [
      GoRoute(
        path: SignInPage.routePath,
        builder: (context, state) => SignInPage(authService: authService),
      ),
      GoRoute(path: '/', redirect: (context, state) => DashboardPage.routePath),
      GoRoute(
        path: ProfilePage.routePath,
        builder: (context, state) => const ProfilePage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: dashboardNavigatorKey,
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
            navigatorKey: bugsNavigatorKey,
            routes: [
              GoRoute(
                path: BugReportsPage.routePath,
                pageBuilder: (context, state) => NoTransitionPage(
                  child: BugReportsPage(
                    bugRepository: bugRepository,
                    refreshSignal: bugRefreshSignal,
                    onBugChanged: onBugChanged,
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
            navigatorKey: reportNavigatorKey,
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
            navigatorKey: settingsNavigatorKey,
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
