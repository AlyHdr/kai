Here’s a focused MVP gap review based on your repo. You’re very close — flows and data model are in place. The list below prioritizes what’s mandatory
(blockers) vs. good-to-have for a smooth v1.

What’s Already Solid

- Auth: email/password sign up + login, email verification screen.
- Onboarding: multi-step intake → writes users/{uid} and triggers macros generation.
- Plans: daily plan generation via Functions + Firestore; selection updates intake totals.
- Subscription: RevenueCat entitlement gating around main UI, paywall presentation.
- Profile: full user profile edit + “recalculate macros” + advanced manual macros override.
- Config: dart-define for RevenueCat keys, firebase_options wired, emulator hooks present.

Critical Gaps (Blockers)

- Auth completeness - Missing password reset (email-based “Forgot password?”) in login. - Email verification gate not enforced on entry. LandingScreen lets any authed user into MainScreen without checking emailVerified. Add an email-
  verified check to the auth stream and route to VerifyEmailScreen.
- Subscription UX (store compliance)
  - No “Restore Purchases” control exposed to users (only in service). Add to Profile or paywall gate.
  - No “Manage Subscription” deep link (platform-specific) and no legal links (Terms/Privacy) accessible from the paywall/profile.
- Security & secrets (must fix before release) - Service account JSON is committed under functions/ and code loads a certificate path. In Firebase Hosting/Functions, default credentials are provided
  — remove certificate loading and delete the committed key from the repo. Rotate it. - functions/.env and .env.local are in the repo. Remove and gitignore .env\* in functions/. Keep secrets only in env or Firebase config. - No Firestore security rules in the repo. Add rules to scope read/write to the owner’s users/{uid}, plans, intake with server-side validation of
  fields.
- Backend input/auth checks
  - generate_macros does not enforce auth or validate input; require req.auth.uid and validate payload types/ranges to prevent abuse.
- Broken/missing UX hook - “Generate Macros” button on DashboardScreen is not wired. It should trigger MacrosService.generateMacros using saved onboarding data or navigate users
  to Profile to recalc.

High-Value For MVP

- Account management - Account deletion (required by Apple/Google and GDPR): delete Firebase user, purge Firestore data (users/{uid}, subcollections), and de-link from
  RevenueCat. - Change email / change password (settings or profile).
- Observability
  - Crashlytics + basic Analytics events (onboarding completed, plan generated, meal selected, subscription started/renewed).
- Readiness/UX polish
  - Add “Restore Purchases” and “Manage Subscription” to Profile.
  - Splash screen (flutter_native_splash) to smooth cold start.
  - Clear empty/failed states: e.g., when plans fail, show actionable retry and support link (you already have some snackbars).
  - Timezone correctness for daily docs: ensure date keys use user-local midnight consistently (possible drift around UTC).
- Testing
  - Replace template widget_test.dart. Add small, fast tests:
    - Unit tests for UsersService.getDashboardData aggregation.
    - Unit test for MacrosService mapping protein→proteins.
    - Widget smoke test for LandingScreen routing (mocking FirebaseAuth).
- DevOps
  - CI to run flutter analyze, dart format --set-exit-if-changed ., and flutter test.
  - A minimal functions unit test for prompt builders and validation helpers (pure functions).
- Docs
  - Store readiness: add links to Privacy Policy, Terms, and Support in app and README; add “How to delete your account”.
  - Add firestore.rules and quick notes on deploying them.
  - Clarify how to configure RevenueCat products/entitlements in README.

Security & Rules (Concrete Suggestions)

- Firestore rules (outline)
  - Allow read/write only to request.auth.uid == resource.id for users/{uid}.
  - In users/{uid}/plans/{date}, allow only owner; validate date id format YYYY-MM-DD.
  - In users/{uid}/intake/{date}, allow only owner; validate numeric totals and meal object shapes.
- Functions hardening - Require req.auth on both functions; validate all numbers are reasonable; limit body size; catch and map exceptions; add minimal rate limiting (via
  Firebase App Check or simple time-based throttling).
- Secret handling
  - Remove certificate loading in functions/main.py and rely on default creds.
  - Add functions/.gitignore: .env, .env._, _.json for service accounts.
  - Rotate the leaked service account.

Product/Store Compliance

- Paywall/legal
  - Restore/Manage subscription buttons.
  - Terms, Privacy, Trial terms link near paywall and profile.
- Account deletion flow available from in-app settings and documented publicly.
- Support contact (email/web form) in app.

Small Fixes/Polish

- Wire “Generate Macros” on Dashboard to either recalc or deep-link to Profile.
- Add “Log in with link” or “Forgot password?” CTA on Login.
- Show entitlement state more clearly (e.g., “Trial X days left” if available from RevenueCat).
- Ensure offline fallback: show cached plan/intake where possible; Firestore has persistence, but render a friendly message when offline.

Prioritized Checklist

1. Enforce email verification at app entry; add password reset.
2. Expose Restore Purchases + Manage Subscription; add legal links.
3. Remove committed secrets; fix Functions to use default credentials; add Firestore rules.
4. Add account deletion.
5. Wire “Generate Macros” on Dashboard.
6. Add Crashlytics + basic Analytics.
7. Replace sample test with 2–3 meaningful unit/widget tests.
8. Add CI for analyze/format/test.
