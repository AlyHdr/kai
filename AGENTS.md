# Repository Guidelines

## Project Structure & Module Organization
- Flutter app: `lib/` (entry `main.dart`, plus `screens/`, `widgets/`, `services/`, `models/`).
- Assets: `assets/` (referenced in `pubspec.yaml`).
- Platform shells: `android/`, `ios/`, `macos/`, `web/`, `windows/`, `linux/`.
- Tests: `test/` (place `*_test.dart` files here).
- Backend (Python functions): `functions/` (`main.py`, `requirements.txt`, `.env*`).
- Config: `pubspec.yaml`, `analysis_options.yaml`, `firebase.json`, `env.example.json`, `lib/firebase_options.dart`.

## Build, Test, and Development Commands
- Install deps: `flutter pub get`
- Run app: `flutter run`
- Provide secrets: `flutter run --dart-define-from-file=env.json` (copy `env.example.json` → `env.json`).
- Static analysis: `flutter analyze`
- Format Dart: `dart format .`
- Run tests: `flutter test`
- Backend setup: `cd functions && python -m venv venv && source venv/bin/activate && pip install -r requirements.txt`
- Backend deploy: `firebase deploy --only functions` (ensure `OPENAI_API_KEY` is set for prod).

## Coding Style & Naming Conventions
- Dart: 2‑space indent; follow `flutter_lints` (configured via `analysis_options.yaml`).
- Files: `snake_case.dart`; Classes: `UpperCamelCase`; members/locals: `lowerCamelCase`.
- Widgets: keep files focused; prefer small, composable widgets under `widgets/`.
- Python (functions): PEP 8, 4‑space indent; prefer pure functions; keep Firebase/HTTP bindings in `main.py`.

## Testing Guidelines
- Framework: `flutter_test`.
- Location: `test/` with `*_test.dart` names.
- Focus: business logic in `services/` and any non‑trivial widgets; avoid snapshot tests.
- Run locally with `flutter test`; keep `flutter analyze` clean before pushing.

## Commit & Pull Request Guidelines
- Commits: present‑tense, concise subject (≤72 chars). Optional prefixes like `feat:`, `fix:`, `chore:`, `wip:` are acceptable.
- PRs: clear description, linked issues, test plan, and screenshots/GIFs for UI changes. Note any schema or env changes (`env.json`, Firebase config).

## Security & Configuration Tips
- Do not hardcode secrets. Use `--dart-define`/`env.json` for app keys and environment variables for backend (e.g., `OPENAI_API_KEY`).
- Keep service accounts and `.env*` files out of commits; rotate if exposed.

## Architecture Overview
- Flutter client (Firebase Auth/Core/Firestore) + Python Functions backend (called from the app and via emulator in debug). Firestore holds users, plans, and intake documents.

