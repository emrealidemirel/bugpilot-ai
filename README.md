# BugPilot AI

BugPilot AI is a Flutter app for creating and managing software bug reports. It stores reports on the device and can use OpenAI to analyze reports and review possible duplicates.

## Run the app

Install Flutter dependencies:

```sh
flutter pub get
```

To try the app without an API key, run it in mock mode:

```sh
flutter run --dart-define=USE_MOCK_AI=true
```

For live AI, copy `.env.example` to `.env`, add your own OpenAI API key, then pass that file to Flutter:

```sh
cp .env.example .env
flutter run --dart-define-from-file=.env
```

The `.env` file uses JSON because Flutter's `--dart-define-from-file` reads JSON. Keep `.env` private; only `.env.example` belongs in GitHub. Each person running this project needs their own API key and an API account with available usage quota. ChatGPT subscriptions and API billing are separate.

This direct connection is a small local demo setup. Flutter embeds build-time values in the app, so someone with the compiled app can recover its API key. Do not use your personal key in a build you distribute. A public release should send requests through a protected backend or use a provider design where each user supplies their own key.

## Sign-in setup

Sign-in uses Firebase Authentication. To connect your Firebase project, install Firebase CLI and FlutterFire CLI, log in, then run:

```sh
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

Select the platforms you need. Enable **Email/Password** and **Google** under Firebase Authentication sign-in providers. Firebase client configuration contains public project identifiers, but never commit service account keys, OAuth client secrets, or other server credentials.

Profile photos are stored locally with Hive, separately for each Firebase user. They persist across app restarts and sign-outs on the same installation. Firebase Storage and a Blaze billing plan are not needed for profile photos. Photos do not sync across devices and are removed when app data is cleared or the app is uninstalled. Google account photos remain the fallback until a local photo is selected.

On iOS Simulator, use `flutter run` or `flutter build ios --simulator --debug` with normal signing. Building with `--no-codesign` can remove the Keychain entitlements Firebase Authentication needs to save the session. The Runner target includes its own Keychain access group.

Google's consent-screen name is configured in Google Cloud → Google Auth Platform → Branding. Set the app name to **BugPilot AI**. Google may ask for account verification; use **Try another way** when a passkey or hardware security key is unavailable in the simulator.

Signing in does not enable cloud sync. Bug reports, settings, and screenshots remain on the device.

## Data and privacy

Bug reports are stored locally with Hive CE. When live AI analysis is requested, the report details and enabled optional inputs are sent from the app directly to OpenAI. Screenshots are sent only when screenshot analysis is enabled. Review descriptions, logs, and images for credentials or other sensitive information before sending them.

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
