import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BugPilot AI'**
  String get appTitle;

  /// No description provided for @dashboardNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardNavLabel;

  /// No description provided for @bugsNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Bugs'**
  String get bugsNavLabel;

  /// No description provided for @reportNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportNavLabel;

  /// No description provided for @settingsNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsNavLabel;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardDescription.
  ///
  /// In en, this message translates to:
  /// **'Your bug reporting overview will appear here.'**
  String get dashboardDescription;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI-powered bug triage'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get dashboardGreeting;

  /// No description provided for @dashboardGreetingMessage.
  ///
  /// In en, this message translates to:
  /// **'Let\'s squash some bugs.'**
  String get dashboardGreetingMessage;

  /// No description provided for @totalBugsStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Bugs'**
  String get totalBugsStatLabel;

  /// No description provided for @openStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openStatLabel;

  /// No description provided for @criticalStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get criticalStatLabel;

  /// No description provided for @resolvedStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolvedStatLabel;

  /// No description provided for @recentBugsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Bugs'**
  String get recentBugsTitle;

  /// No description provided for @viewAllAction.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAllAction;

  /// No description provided for @reportBugAction.
  ///
  /// In en, this message translates to:
  /// **'Report Bug'**
  String get reportBugAction;

  /// No description provided for @bugReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bugs'**
  String get bugReportsTitle;

  /// No description provided for @bugReportsDescription.
  ///
  /// In en, this message translates to:
  /// **'Track saved reports and current issue status.'**
  String get bugReportsDescription;

  /// No description provided for @emptyBugReportsMessage.
  ///
  /// In en, this message translates to:
  /// **'No bug reports yet.'**
  String get emptyBugReportsMessage;

  /// No description provided for @reportBugTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a Bug'**
  String get reportBugTitle;

  /// No description provided for @reportBugDescription.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue and let AI help with the analysis.'**
  String get reportBugDescription;

  /// No description provided for @issueSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issueSectionTitle;

  /// No description provided for @behaviorSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Behavior'**
  String get behaviorSectionTitle;

  /// No description provided for @environmentSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get environmentSectionTitle;

  /// No description provided for @technicalDetailsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Technical Details'**
  String get technicalDetailsSectionTitle;

  /// No description provided for @bugTitleFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Bug Title'**
  String get bugTitleFieldLabel;

  /// No description provided for @bugTitleFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Login button stuck after submitting credentials'**
  String get bugTitleFieldHint;

  /// No description provided for @descriptionFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionFieldLabel;

  /// No description provided for @descriptionFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened...'**
  String get descriptionFieldHint;

  /// No description provided for @expectedBehaviorFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected Behavior'**
  String get expectedBehaviorFieldLabel;

  /// No description provided for @expectedBehaviorFieldHint.
  ///
  /// In en, this message translates to:
  /// **'What should have happened?'**
  String get expectedBehaviorFieldHint;

  /// No description provided for @actualBehaviorFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Actual Behavior'**
  String get actualBehaviorFieldLabel;

  /// No description provided for @actualBehaviorFieldHint.
  ///
  /// In en, this message translates to:
  /// **'What actually happened?'**
  String get actualBehaviorFieldHint;

  /// No description provided for @platformFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platformFieldLabel;

  /// No description provided for @deviceFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get deviceFieldLabel;

  /// No description provided for @deviceFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Pixel 9, iPhone 16, Chrome Desktop'**
  String get deviceFieldHint;

  /// No description provided for @osVersionFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'OS Version'**
  String get osVersionFieldLabel;

  /// No description provided for @osVersionFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Android 16'**
  String get osVersionFieldHint;

  /// No description provided for @appVersionFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersionFieldLabel;

  /// No description provided for @appVersionFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Example: 1.0.0'**
  String get appVersionFieldHint;

  /// No description provided for @logsFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Error Logs / Stack Trace'**
  String get logsFieldLabel;

  /// No description provided for @logsFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Paste error logs or stack trace here...'**
  String get logsFieldHint;

  /// No description provided for @saveBugReportAction.
  ///
  /// In en, this message translates to:
  /// **'Save Bug Report'**
  String get saveBugReportAction;

  /// No description provided for @savingBugReportAction.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingBugReportAction;

  /// No description provided for @bugReportCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Bug report created successfully.'**
  String get bugReportCreatedMessage;

  /// No description provided for @bugReportCreateErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not create the bug report. Please try again.'**
  String get bugReportCreateErrorMessage;

  /// No description provided for @requiredFieldValidation.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredFieldValidation;

  /// No description provided for @platformRequiredValidation.
  ///
  /// In en, this message translates to:
  /// **'Select a platform.'**
  String get platformRequiredValidation;

  /// No description provided for @bugTitleMinValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 5 characters.'**
  String get bugTitleMinValidation;

  /// No description provided for @bugTitleMaxValidation.
  ///
  /// In en, this message translates to:
  /// **'Keep the title under 120 characters.'**
  String get bugTitleMaxValidation;

  /// No description provided for @descriptionMinValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 10 characters.'**
  String get descriptionMinValidation;

  /// No description provided for @optionalMaxValidation.
  ///
  /// In en, this message translates to:
  /// **'Keep this under 80 characters.'**
  String get optionalMaxValidation;

  /// No description provided for @appVersionMaxValidation.
  ///
  /// In en, this message translates to:
  /// **'Keep this under 40 characters.'**
  String get appVersionMaxValidation;

  /// No description provided for @discardReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard report?'**
  String get discardReportTitle;

  /// No description provided for @discardReportMessage.
  ///
  /// In en, this message translates to:
  /// **'Your unsaved changes will be lost.'**
  String get discardReportMessage;

  /// No description provided for @keepEditingAction.
  ///
  /// In en, this message translates to:
  /// **'Keep Editing'**
  String get keepEditingAction;

  /// No description provided for @discardAction.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardAction;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Workspace and app preferences will appear here.'**
  String get settingsDescription;

  /// No description provided for @languageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionTitle;

  /// No description provided for @languageSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the interface language for BugPilot AI.'**
  String get languageSectionDescription;

  /// No description provided for @englishLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @turkishLanguage.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get turkishLanguage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
