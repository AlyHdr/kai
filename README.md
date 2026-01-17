# kai

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## MVP scope:

- User authentication
- Store onboarding data
- Generate daily meal plans using LLM + connect to user data
- Store generated daily calorie consumption, macros and connect them to the interface
- Update values based on user consumption
- allow users to update the macros manually if needed

## Running the App

- Prereqs: Flutter SDK, Firebase CLI, valid Firebase project setup.
- Install deps: `flutter pub get`
- Configure Firebase: ensure `lib/firebase_options.dart` matches your project (`firebase.json` already points to `kai-nutrition-assistant`).
- Run: `flutter run`

RevenueCat
- Do NOT hardcode SDK keys in source.
- Provide keys at build/run time using `--dart-define` or a local `env.json` (gitignored).

Inject via CLI
- iOS: `flutter run --dart-define=RC_IOS_SDK_KEY=appl_xxx`
- Android: `flutter run --dart-define=RC_ANDROID_SDK_KEY=goog_xxx`

Using a local file
- Copy `env.example.json` to `env.json` and fill in your keys.
- Run: `flutter run --dart-define-from-file=env.json`
- `env.json` is ignored by git (see .gitignore).

## Cloud Functions (Python)

- Location: `functions/`
- Requirements: Python 3.11+, `pip install -r requirements.txt`
- Env: set `OPENAI_API_KEY` in `.env.local` or environment.
- Deploy: `firebase deploy --only functions`

Local Emulator (optional)
- The app calls the Functions emulator only in debug/profile builds for the plan regenerate action.
- If using emulator, run it and ensure it’s listening on `localhost:5001`.

## Firestore Data Model

- `users/{uid}`: onboarding fields + `macros` sub-map
  - Macros keys: `calories`, `carbs`, `proteins`, `fats` (note: `proteins` is plural for daily targets)
- `users/{uid}/plans/{YYYY-MM-DD}`: generated meal plan for a day
  - Keys: `breakfast`, `lunch`, `dinner`, `snack` → List of 3 meal options each
  - `selected`: chosen option per meal
- `users/{uid}/intake/{YYYY-MM-DD}`: daily intake totals
  - `meals`: chosen meals per slot
  - `totals`: `calories`, `carbs`, `proteins`, `fats`

Meal Option Macros
- Each meal option (in a plan) carries a `macros` object with keys: `calories`, `protein`, `carbs`, `fats` (note: `protein` is singular for per-meal macros).

## Notes

- Macro key normalization: The app saves daily target macros with a `proteins` field. Cloud Function output is aliased on save so both `protein` and `proteins` are supported, and the backend accepts either when generating plans.
- The sample Flutter widget test is from the template and not aligned with this app’s UI.
