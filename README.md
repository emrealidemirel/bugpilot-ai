# BugPilot AI

BugPilot AI is a Flutter app for capturing and managing software bug reports, with an optional AI assistant for triage and QA suggestions. It is intended for personal use and GitHub sharing; this project does not target app stores.

## Features

- Create, edit, view, and delete bug reports.
- Keep reports and screenshot attachments on the device with Hive CE.
- Search and filter reports by status, severity, priority, and platform.
- View dashboard counts and recent reports.
- Check for similar reports locally, with an optional AI duplicate review.
- Ask an OpenAI-backed service for severity, priority, reproduction steps, test cases, missing details, and a possible root cause.
- Configure AI sections, screenshot sharing, default environment values, theme, and interface language.
- Run without a backend in mock AI mode.

## Requirements

- Flutter and Dart versions compatible with `pubspec.yaml`.
- Node.js and npm if you want to run the optional AI backend.
- An OpenAI API key for live AI analysis. Keep the key in the backend environment; never put it in Flutter `--dart-define` values or commit it.

## Run the app

Install Flutter dependencies and start the app with mock AI:

```sh
flutter pub get
flutter run --dart-define=USE_MOCK_AI=true
```

Mock mode is useful for exploring the app without network access or an API key. Bug reports are still saved locally.

For live analysis, start the backend first (see below), then set `API_BASE_URL` to an address reachable from the device:

```sh
# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# iOS simulator or desktop on the same machine
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

For a physical device, use the development machine's LAN address and make sure the device can reach that port. The app has no production backend URL configured.

## Run the AI backend

```sh
cd backend
npm ci
cp .env.example .env
```

Set `OPENAI_API_KEY` in `backend/.env`. `OPENAI_MODEL` and `PORT` have defaults; `ALLOWED_ORIGINS` is an optional comma-separated list for browser clients. Then run:

```sh
npm run dev
```

The backend provides `GET /health`, `POST /api/v1/ai/analyze-bug`, and `POST /api/v1/ai/check-duplicates`. The app sends only the top local duplicate candidates. Uploaded screenshots are held in memory for the analysis request and are not retained by the backend.

See [backend/README.md](backend/README.md) and the [AI API contract](docs/ai_api_contract.md) for details.

## Data and privacy

Bug reports, settings, and screenshot attachments are stored locally on the current device. There is no account or cloud sync. Removing the app or its data can remove saved reports. Local app data is not encrypted in this version.

When live AI analysis is requested, the bug details and enabled optional inputs are sent to the configured backend and then to its configured AI provider. Screenshots are included only when screenshot analysis is enabled. Review bug descriptions, logs, and images for credentials or other sensitive information before sending them.

The backend has no user authentication or rate limiting. Deploy it only in an environment whose access and usage you control; do not expose an unauthenticated instance as a public service.

## Project layout

```text
lib/
  app/                       App setup, routing, theme, localization
  core/                      Shared UI and utilities
  features/                  Dashboard, bug reports, AI, settings
backend/
  src/                       Express API, validation, and AI services
docs/                        API contract and project documentation
test/                        Flutter unit and widget tests
backend/tests/               Backend tests
```

Flutter features follow a presentation / domain / data structure. The repository and service interfaces keep local persistence and remote AI clients replaceable.

## Quality checks

```sh
dart format .
flutter analyze
flutter test

cd backend
npm run build
npm test
```

## GitHub sharing

Before publishing, choose a repository visibility and add a license if you want to grant others permission to reuse the code. Do not include `.env`, API keys, local build output, or device data in commits. The root `.gitignore` excludes these environment and build files.
