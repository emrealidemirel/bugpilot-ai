# BugPilot AI

BugPilot AI is a Flutter app for creating and managing software bug reports. It stores reports on the device and uses OpenAI to analyze reports and review possible duplicates.

## Run the app

Install Flutter dependencies:

```sh
flutter pub get
```

Run the app with live AI by creating a private `.env` file from the example, adding your OpenAI API key, and passing it to Flutter:

```sh
cp .env.example .env
chmod 600 .env
flutter run --debug --dart-define-from-file=.env
```

The `.env` file uses JSON because Flutter's `--dart-define-from-file` reads JSON. `.env` is ignored by Git; only `.env.example`, which contains a placeholder, belongs in GitHub. If the key is missing, AI requests show an error instead of returning mock analysis. Each person running this project needs their own API key and an API account with available usage quota. ChatGPT subscriptions and API billing are separate.

Direct AI access is for private development only. The key is used only in debug mode; profile and release modes ignore `OPENAI_API_KEY`. Flutter can embed build-time values in artifacts and build metadata, so never pass the key to a distributable build or share debug artifacts/logs. Git ignore protects source control, not compiled applications. If a key is exposed, rotate it.

**No backend is included or deployed. Release AI is intentionally unavailable until a secure server integration is implemented.** A README warning alone cannot protect a secret shipped in a mobile application.

## Sign-in setup

Sign-in uses Firebase Authentication. To connect your Firebase project, install Firebase CLI and FlutterFire CLI, log in, then run:

```sh
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

Select the platforms you need. Enable **Email/Password** and **Google** under Firebase Authentication sign-in providers. Firebase client configuration contains public project identifiers, but never commit service account keys, OAuth client secrets, or other server credentials.

Profile photos are stored locally in an encrypted Hive box, keyed separately for each Firebase user. They persist across app restarts and sign-outs on the same installation. Firebase Storage and a Blaze billing plan are not needed for profile photos. Photos do not sync across devices and are removed when app data is cleared or the app is uninstalled. Google account photos remain the fallback until a local photo is selected.

On iOS Simulator, use `flutter run` or `flutter build ios --simulator --debug` with normal signing. Building with `--no-codesign` can remove the Keychain entitlements Firebase Authentication needs to save the session. The Runner target includes its own Keychain access group.

Google's consent-screen name is configured in Google Cloud → Google Auth Platform → Branding. Set the app name to **BugPilot AI**. Google may ask for account verification; use **Try another way** when a passkey or hardware security key is unavailable in the simulator.

Signing in does not enable cloud sync. Bug reports, settings, and screenshots remain on the device.

## Data and privacy

Bug reports and settings use separate encrypted Hive CE boxes for each account. The encryption key is stored using the platform secure storage. Profile photos are encrypted too; report screenshots are ordinary files inside the app sandbox. Android cloud backup and device transfer are excluded. This is local storage, not end-to-end encrypted cloud sync.

Changing accounts recreates navigation and drafts. Existing installations expose a one-time report import only to the account signed in during the first upgraded startup; signed-out legacy data is preserved but never assigned to the next person who signs in. Import copies all reports before removing old records. Unimported legacy reports remain in the old unencrypted database until import or deletion.

Email/password accounts receive a verification email; unverified accounts cannot start AI sharing. The app asks for explicit AI sharing consent per session, and the privacy panel lets users withdraw it. Account deletion requires reauthentication and deletes the Firebase account plus this installation's reports, settings, attachments and profile photo. Other devices remain separate local copies. Interrupted local cleanup is retried at startup; failed remote deletion preserves local data.

The in-app privacy summary describes this development setup. A public privacy policy, owner/support contact and external account-deletion request URL still need to be provided before store submission.

 When live AI analysis is requested, the report details and enabled optional inputs are sent from the app directly to OpenAI. Screenshots are sent only when screenshot analysis is enabled. Review descriptions, logs, and images for credentials or other sensitive information before sending them.

## Project structure

```text
lib/
  app/                 App startup and routing
  constants/           App and Firebase configuration
  controllers/         Screen and settings state
  models/              Bug, AI, account, and settings models
  pages/               Screens grouped by app area
  repositories/        Local data access and repository contracts
  services/            AI, authentication, storage, and app services
  theme/               App theme and shared dimensions
  utils/               Validation, filtering, formatting, localization
  widgets/             Shared and screen-specific UI components
assets/translations/    Turkish and English strings
```

## GitHub

Do not commit `.env`, API keys, Firebase service credentials, local build output, or device data. The root `.gitignore` excludes environment files and Flutter build artifacts.

## Verification and release preparation

```sh
flutter analyze
flutter test
flutter build ios --simulator --debug --dart-define-from-file=.env
flutter build apk --debug
```

Keep `test/`: automated tests are normal for release applications and are not bundled in the app. Canned AI implementations live only under `test/support/`; runtime AI never falls back to mock results. CI runs analysis and tests without a personal API key.

Before distributing:

- Implement authenticated server-side AI, request limits and abuse controls. The current debug setup is not a production AI service.
- Choose permanent iOS/Android identifiers and update Firebase/OAuth configuration together. Existing development identifiers remain unchanged to preserve sign-in.
- Configure real Android release signing in ignored `android/key.properties` (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`). Release builds fail without it; debug signing is never a fallback. Configure Apple signing/provisioning separately.
- Configure Sign in with Apple in Apple Developer and Firebase, add the capability/entitlement, then enable `--dart-define=APPLE_SIGN_IN_ENABLED=true` and test on device. It is hidden by default until configured.
- Set a real HTTPS `PRIVACY_POLICY_URL`, support contact and public deletion-request page; complete store privacy/data-safety disclosures and review SDK privacy manifests.
- Verify Google/password/Apple sign-in, reset/verification emails, deletion, offline recovery, account switching and accessibility on physical iOS/Android devices with test accounts. Firebase console restrictions, OAuth settings and store compliance cannot be established by unit tests.

Do not add advertising or paid features until their SDK/data disclosures and store billing requirements have been reviewed. No ads, payments or placeholder legal pages are added by this preparation.
