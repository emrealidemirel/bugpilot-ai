import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import 'package:bugpilot_ai/models/bug_platform.dart';
import 'package:bugpilot_ai/models/bug_priority.dart';
import 'package:bugpilot_ai/models/bug_severity.dart';
import 'package:bugpilot_ai/models/bug_status.dart';
import 'package:bugpilot_ai/models/bug_test_case_type.dart';
import 'package:bugpilot_ai/models/app_theme_mode.dart';

class LocalizationStrings {
  String get appTitle => 'appTitle'.tr();
  String get dashboardNavLabel => 'dashboardNavLabel'.tr();
  String get bugsNavLabel => 'bugsNavLabel'.tr();
  String get reportNavLabel => 'reportNavLabel'.tr();
  String get settingsNavLabel => 'settingsNavLabel'.tr();
  String get dashboardTitle => 'dashboardTitle'.tr();
  String get dashboardDescription => 'dashboardDescription'.tr();
  String get dashboardSubtitle => 'dashboardSubtitle'.tr();
  String get dashboardGreeting => 'dashboardGreeting'.tr();
  String get dashboardGreetingMessage => 'dashboardGreetingMessage'.tr();
  String get totalBugsStatLabel => 'totalBugsStatLabel'.tr();
  String get openStatLabel => 'openStatLabel'.tr();
  String get criticalStatLabel => 'criticalStatLabel'.tr();
  String get resolvedStatLabel => 'resolvedStatLabel'.tr();
  String get recentBugsTitle => 'recentBugsTitle'.tr();
  String get viewAllAction => 'viewAllAction'.tr();
  String get reportBugAction => 'reportBugAction'.tr();
  String get bugReportsTitle => 'bugReportsTitle'.tr();
  String get bugReportsDescription => 'bugReportsDescription'.tr();
  String get emptyBugReportsMessage => 'emptyBugReportsMessage'.tr();
  String get reportBugTitle => 'reportBugTitle'.tr();
  String get reportBugDescription => 'reportBugDescription'.tr();
  String get issueSectionTitle => 'issueSectionTitle'.tr();
  String get behaviorSectionTitle => 'behaviorSectionTitle'.tr();
  String get environmentSectionTitle => 'environmentSectionTitle'.tr();
  String get technicalDetailsSectionTitle =>
      'technicalDetailsSectionTitle'.tr();
  String get bugTitleFieldLabel => 'bugTitleFieldLabel'.tr();
  String get bugTitleFieldHint => 'bugTitleFieldHint'.tr();
  String get descriptionFieldLabel => 'descriptionFieldLabel'.tr();
  String get descriptionFieldHint => 'descriptionFieldHint'.tr();
  String get expectedBehaviorFieldLabel => 'expectedBehaviorFieldLabel'.tr();
  String get expectedBehaviorFieldHint => 'expectedBehaviorFieldHint'.tr();
  String get actualBehaviorFieldLabel => 'actualBehaviorFieldLabel'.tr();
  String get actualBehaviorFieldHint => 'actualBehaviorFieldHint'.tr();
  String get platformFieldLabel => 'platformFieldLabel'.tr();
  String get deviceFieldLabel => 'deviceFieldLabel'.tr();
  String get deviceFieldHint => 'deviceFieldHint'.tr();
  String get osVersionFieldLabel => 'osVersionFieldLabel'.tr();
  String get osVersionFieldHint => 'osVersionFieldHint'.tr();
  String get appVersionFieldLabel => 'appVersionFieldLabel'.tr();
  String get appVersionFieldHint => 'appVersionFieldHint'.tr();
  String get logsFieldLabel => 'logsFieldLabel'.tr();
  String get logsFieldHint => 'logsFieldHint'.tr();
  String get saveBugReportAction => 'saveBugReportAction'.tr();
  String get savingBugReportAction => 'savingBugReportAction'.tr();
  String get bugReportCreatedMessage => 'bugReportCreatedMessage'.tr();
  String get bugReportCreateErrorMessage => 'bugReportCreateErrorMessage'.tr();
  String get requiredFieldValidation => 'requiredFieldValidation'.tr();
  String get platformRequiredValidation => 'platformRequiredValidation'.tr();
  String get bugTitleMinValidation => 'bugTitleMinValidation'.tr();
  String get bugTitleMaxValidation => 'bugTitleMaxValidation'.tr();
  String get descriptionMinValidation => 'descriptionMinValidation'.tr();
  String get optionalMaxValidation => 'optionalMaxValidation'.tr();
  String get appVersionMaxValidation => 'appVersionMaxValidation'.tr();
  String get discardReportTitle => 'discardReportTitle'.tr();
  String get discardReportMessage => 'discardReportMessage'.tr();
  String get keepEditingAction => 'keepEditingAction'.tr();
  String get discardAction => 'discardAction'.tr();
  String get settingsTitle => 'settingsTitle'.tr();
  String get settingsDescription => 'settingsDescription'.tr();
  String get languageSectionTitle => 'languageSectionTitle'.tr();
  String get languageSectionDescription => 'languageSectionDescription'.tr();
  String get englishLanguage => 'englishLanguage'.tr();
  String get turkishLanguage => 'turkishLanguage'.tr();
  String get firebaseSetupRequired => 'firebaseSetupRequired'.tr();
  String get emailLabel => 'emailLabel'.tr();
  String get passwordLabel => 'passwordLabel'.tr();
  String get validEmailMessage => 'validEmailMessage'.tr();
  String get passwordMinMessage => 'passwordMinMessage'.tr();
  String get pleaseWait => 'pleaseWait'.tr();
  String get createAccount => 'createAccount'.tr();
  String get signIn => 'signIn'.tr();
  String get haveAccountSignIn => 'haveAccountSignIn'.tr();
  String get needAccountCreate => 'needAccountCreate'.tr();
  String get forgotPassword => 'forgotPassword'.tr();
  String get continueWithGoogle => 'continueWithGoogle'.tr();
  String get passwordResetSent => 'passwordResetSent'.tr();
  String get emailAlreadyInUse => 'emailAlreadyInUse'.tr();
  String get invalidCredentials => 'invalidCredentials'.tr();
  String get networkError => 'networkError'.tr();
  String get authGenericError => 'authGenericError'.tr();
  String get signOut => 'signOut'.tr();
  String get account => 'account'.tr();
  String get appearanceTitle => 'appearanceTitle'.tr();
  String get themeLabel => 'themeLabel'.tr();
  String get aiPreferencesTitle => 'aiPreferencesTitle'.tr();
  String get severitySuggestion => 'severitySuggestion'.tr();
  String get severitySuggestionDescription =>
      'severitySuggestionDescription'.tr();
  String get prioritySuggestion => 'prioritySuggestion'.tr();
  String get prioritySuggestionDescription =>
      'prioritySuggestionDescription'.tr();
  String get generateTestCases => 'generateTestCases'.tr();
  String get generateTestCasesDescription =>
      'generateTestCasesDescription'.tr();
  String get rootCauseHypothesis => 'rootCauseHypothesis'.tr();
  String get rootCauseHypothesisDescription =>
      'rootCauseHypothesisDescription'.tr();
  String get duplicateDetection => 'duplicateDetection'.tr();
  String get duplicateDetectionDescription =>
      'duplicateDetectionDescription'.tr();
  String get screenshotAnalysis => 'screenshotAnalysis'.tr();
  String get screenshotAnalysisDescriptionOn =>
      'screenshotAnalysisDescriptionOn'.tr();
  String get screenshotAnalysisDescriptionOff =>
      'screenshotAnalysisDescriptionOff'.tr();
  String get defaultEnvironmentTitle => 'defaultEnvironmentTitle'.tr();
  String get defaultPlatformLabel => 'defaultPlatformLabel'.tr();
  String get defaultDeviceLabel => 'defaultDeviceLabel'.tr();
  String get defaultOsVersionLabel => 'defaultOsVersionLabel'.tr();
  String get defaultAppVersionLabel => 'defaultAppVersionLabel'.tr();
  String get saveDefaultsAction => 'saveDefaultsAction'.tr();
  String get privacyAiTitle => 'privacyAiTitle'.tr();
  String get aiDataUseTitle => 'aiDataUseTitle'.tr();
  String get aiDataUseDescription => 'aiDataUseDescription'.tr();
  String get reviewLogsTitle => 'reviewLogsTitle'.tr();
  String get reviewLogsDescription => 'reviewLogsDescription'.tr();
  String get aboutTitle => 'aboutTitle'.tr();
  String get aboutDescription => 'aboutDescription'.tr();
  String get openSourceLicenses => 'openSourceLicenses'.tr();
  String get resetSettingsTitle => 'resetSettingsTitle'.tr();
  String get resetSettingsDescription => 'resetSettingsDescription'.tr();
  String get cancelAction => 'cancelAction'.tr();
  String get resetAction => 'resetAction'.tr();
  String get resetSettingsSuccess => 'resetSettingsSuccess'.tr();
  String get settingsSaved => 'settingsSaved'.tr();
  String get settingsSaveError => 'settingsSaveError'.tr();
  String get settingsResetLabel => 'settingsResetLabel'.tr();
  String get accountMenu => 'accountMenu'.tr();
  String get mainNavigation => 'mainNavigation'.tr();
  String get platformAndroid => 'platformAndroid'.tr();
  String get platformIos => 'platformIos'.tr();
  String get platformWeb => 'platformWeb'.tr();
  String get platformOther => 'platformOther'.tr();
  String get themeSystem => 'themeSystem'.tr();
  String get themeLight => 'themeLight'.tr();
  String get themeDark => 'themeDark'.tr();
  String get statusOpen => 'statusOpen'.tr();
  String get statusInProgress => 'statusInProgress'.tr();
  String get statusResolved => 'statusResolved'.tr();
  String get statusClosed => 'statusClosed'.tr();
  String get severityCritical => 'severityCritical'.tr();
  String get severityHigh => 'severityHigh'.tr();
  String get severityMedium => 'severityMedium'.tr();
  String get severityLow => 'severityLow'.tr();
  String get priorityImmediate => 'priorityImmediate'.tr();
  String get priorityHigh => 'priorityHigh'.tr();
  String get priorityNormal => 'priorityNormal'.tr();
  String get priorityLow => 'priorityLow'.tr();
  String get priorityUnassigned => 'priorityUnassigned'.tr();
  String get severityUnassigned => 'severityUnassigned'.tr();
  String get bugListSubtitle => 'bugListSubtitle'.tr();
  String get searchBugsHint => 'searchBugsHint'.tr();
  String get clearSearch => 'clearSearch'.tr();
  String get filtersLabel => 'filtersLabel'.tr();
  String get sortLabel => 'sortLabel'.tr();
  String get clearFilters => 'clearFilters'.tr();
  String get filterAll => 'filterAll'.tr();
  String get applyAction => 'applyAction'.tr();
  String get noBugReports => 'noBugReports'.tr();
  String get emptyBugHelp => 'emptyBugHelp'.tr();
  String get noMatchingBugs => 'noMatchingBugs'.tr();
  String get adjustSearchFilters => 'adjustSearchFilters'.tr();
  String get unableToLoadBugs => 'unableToLoadBugs'.tr();
  String get reportBugsAction => 'reportBugsAction'.tr();
  String get newestSort => 'newestSort'.tr();
  String get oldestSort => 'oldestSort'.tr();
  String get severitySort => 'severitySort'.tr();
  String get prioritySort => 'prioritySort'.tr();
  String get severityLabel => 'severityLabel'.tr();
  String get priorityLabel => 'priorityLabel'.tr();
  String get platformLabel => 'platformLabel'.tr();
  String get platformMetadataLabel => 'platformMetadataLabel'.tr();

  String localizedPlatformLabel(BugPlatform value) => switch (value) {
    BugPlatform.android => platformAndroid,
    BugPlatform.ios => platformIos,
    BugPlatform.web => platformWeb,
    BugPlatform.other => platformOther,
  };
  String localizedThemeLabel(AppThemeMode value) => switch (value) {
    AppThemeMode.system => themeSystem,
    AppThemeMode.light => themeLight,
    AppThemeMode.dark => themeDark,
  };
  String localizedTestCaseType(BugTestCaseType value) => switch (value) {
    BugTestCaseType.positive => 'testTypePositive'.tr(),
    BugTestCaseType.negative => 'testTypeNegative'.tr(),
    BugTestCaseType.edgeCase => 'testTypeEdgeCase'.tr(),
  };
  String statusLabel(BugStatus value) => switch (value) {
    BugStatus.open => statusOpen,
    BugStatus.inProgress => statusInProgress,
    BugStatus.resolved => statusResolved,
    BugStatus.closed => statusClosed,
  };
  String bugSeverityLabel(BugSeverity value) => switch (value) {
    BugSeverity.critical => severityCritical,
    BugSeverity.high => severityHigh,
    BugSeverity.medium => severityMedium,
    BugSeverity.low => severityLow,
  };
  String priorityDescription(BugPriority value) => switch (value) {
    BugPriority.p0 => priorityImmediate,
    BugPriority.p1 => priorityHigh,
    BugPriority.p2 => priorityNormal,
    BugPriority.p3 => priorityLow,
  };
}

extension LocalizationExtensions on BuildContext {
  LocalizationStrings get l10n => LocalizationStrings();
}
