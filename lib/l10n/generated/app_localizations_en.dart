// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BugPilot AI';

  @override
  String get dashboardNavLabel => 'Dashboard';

  @override
  String get bugsNavLabel => 'Bugs';

  @override
  String get reportNavLabel => 'Report';

  @override
  String get settingsNavLabel => 'Settings';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardDescription =>
      'Your bug reporting overview will appear here.';

  @override
  String get dashboardSubtitle => 'AI-powered bug triage';

  @override
  String get dashboardGreeting => 'Good afternoon';

  @override
  String get dashboardGreetingMessage => 'Let\'s squash some bugs.';

  @override
  String get totalBugsStatLabel => 'Total Bugs';

  @override
  String get openStatLabel => 'Open';

  @override
  String get criticalStatLabel => 'Critical';

  @override
  String get resolvedStatLabel => 'Resolved';

  @override
  String get recentBugsTitle => 'Recent Bugs';

  @override
  String get viewAllAction => 'View all';

  @override
  String get reportBugAction => 'Report Bug';

  @override
  String get bugReportsTitle => 'Bugs';

  @override
  String get bugReportsDescription =>
      'Track saved reports and current issue status.';

  @override
  String get emptyBugReportsMessage => 'No bug reports yet.';

  @override
  String get reportBugTitle => 'Report a Bug';

  @override
  String get reportBugDescription =>
      'Describe the issue and let AI help with the analysis.';

  @override
  String get issueSectionTitle => 'Issue';

  @override
  String get behaviorSectionTitle => 'Behavior';

  @override
  String get environmentSectionTitle => 'Environment';

  @override
  String get technicalDetailsSectionTitle => 'Technical Details';

  @override
  String get bugTitleFieldLabel => 'Bug Title';

  @override
  String get bugTitleFieldHint =>
      'Example: Login button stuck after submitting credentials';

  @override
  String get descriptionFieldLabel => 'Description';

  @override
  String get descriptionFieldHint => 'Describe what happened...';

  @override
  String get expectedBehaviorFieldLabel => 'Expected Behavior';

  @override
  String get expectedBehaviorFieldHint => 'What should have happened?';

  @override
  String get actualBehaviorFieldLabel => 'Actual Behavior';

  @override
  String get actualBehaviorFieldHint => 'What actually happened?';

  @override
  String get platformFieldLabel => 'Platform';

  @override
  String get deviceFieldLabel => 'Device';

  @override
  String get deviceFieldHint => 'Pixel 9, iPhone 16, Chrome Desktop';

  @override
  String get osVersionFieldLabel => 'OS Version';

  @override
  String get osVersionFieldHint => 'Example: Android 16';

  @override
  String get appVersionFieldLabel => 'App Version';

  @override
  String get appVersionFieldHint => 'Example: 1.0.0';

  @override
  String get logsFieldLabel => 'Error Logs / Stack Trace';

  @override
  String get logsFieldHint => 'Paste error logs or stack trace here...';

  @override
  String get saveBugReportAction => 'Save Bug Report';

  @override
  String get savingBugReportAction => 'Saving...';

  @override
  String get bugReportCreatedMessage => 'Bug report created successfully.';

  @override
  String get bugReportCreateErrorMessage =>
      'Could not create the bug report. Please try again.';

  @override
  String get requiredFieldValidation => 'This field is required.';

  @override
  String get platformRequiredValidation => 'Select a platform.';

  @override
  String get bugTitleMinValidation => 'Enter at least 5 characters.';

  @override
  String get bugTitleMaxValidation => 'Keep the title under 120 characters.';

  @override
  String get descriptionMinValidation => 'Enter at least 10 characters.';

  @override
  String get optionalMaxValidation => 'Keep this under 80 characters.';

  @override
  String get appVersionMaxValidation => 'Keep this under 40 characters.';

  @override
  String get discardReportTitle => 'Discard report?';

  @override
  String get discardReportMessage => 'Your unsaved changes will be lost.';

  @override
  String get keepEditingAction => 'Keep Editing';

  @override
  String get discardAction => 'Discard';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDescription =>
      'Workspace and app preferences will appear here.';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageSectionDescription =>
      'Choose the interface language for BugPilot AI.';

  @override
  String get englishLanguage => 'English';

  @override
  String get turkishLanguage => 'Türkçe';
}
