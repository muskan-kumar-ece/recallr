# Recallr Production Configuration, App Check & Deployment Hardening v1

## 1. Executive Summary

Phase 13F-02 establishes the production configuration and deployment infrastructure required to move Recallr securely from development into Staging and Production environments.

### Core Pillars:
1. **Explicit Multi-Environment Model**: Three distinct environments (`development`, `staging`, `production`) configured via build-time `--dart-define=APP_ENV=...` flags.
2. **Firebase App Check Integration**: Mandatory device attestation using Google Play Integrity on Android, Apple App Attest on iOS/macOS, and ReCaptchaV3 on Web.
3. **Fail-Safe Startup Lifecycle**: Ordered bootstrap sequence with pre-flight configuration validation and sanitized fatal error recovery.
4. **Isolated Emulator Suite**: Local development emulator configuration with automatic production locks to prevent accidental emulator routing in production.
5. **Zero Secrets in Source Control**: All API keys, tokens, and credentials are supplied via compilation flags or environment variables.

---

## 2. Environment Matrix

| Parameter | Development | Staging | Production |
| :--- | :--- | :--- | :--- |
| **`APP_ENV`** | `development` | `staging` | `production` |
| **Firebase Project** | `recaller-cabf8` / Local Emulators | `recaller-staging` | `recaller-prod` |
| **App Check Mode** | Optional / `DebugAppCheckProvider` | Required / Staging Provider | Enforced Device Attestation |
| **Android App Check** | `AndroidProvider.debug` | `AndroidProvider.debug` | `AndroidProvider.playIntegrity` |
| **iOS App Check** | `AppleProvider.debug` | `AppleProvider.debug` | `AppleProvider.appAttestWithDeviceCheckFallback` |
| **Web App Check** | Disabled / Debug | `ReCaptchaV3Provider` | `ReCaptchaV3Provider` |
| **Emulators Permitted** | Yes (`USE_EMULATORS=true`) | Forbidden | **STRICTLY FORBIDDEN** (Fatal exception) |
| **Logging Level** | Verbose with sanitization | Safe info/warning/error | Minimal (debug suppressed) |
| **Gemini AI** | Real API or Deterministic Mock | Real API | Real Gemini + Deterministic Fallback |
| **Mock Fallback** | Allowed | Allowed | Forbidden in core data layer |

---

## 3. Ordered Bootstrap & Initialization Lifecycle

```text
┌─────────────────────────────────────────────────────────────┐
│                 1. Environment Resolution                   │
│          AppEnvironment.fromEnvironment()                   │
│    Reads --dart-define=APP_ENV=(dev|staging|prod)           │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│            2. Pre-flight Security Validation                │
│       ProductionConfigurationValidator.validateOrThrow()    │
│    Checks: No emulators in prod, App Check enabled, etc.    │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│               3. Firebase Core Initialization               │
│          Firebase.initializeApp(options: ...)               │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 4. App Check Activation                     │
│               AppCheckService.activate()                    │
│    (Idempotent, non-blocking fallback, token-redacted)      │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│             5. Optional Emulator Connection                 │
│         FirebaseEmulatorHelper.connectIfEnabled()           │
│         (Guarded against production connection)             │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│               6. Dependency Injection & Scope               │
│               RecallrDependencies.production()              │
│                 MaterialApp / RecallrScope                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Release Build Commands

### Development Build (with local debug tokens):
```bash
flutter run \
  --dart-define=APP_ENV=development \
  --dart-define=ENABLE_APP_CHECK=false \
  --dart-define=USE_EMULATORS=false \
  --dart-define=GEMINI_API_KEY=YOUR_DEV_GEMINI_KEY
```

### Staging Build:
```bash
flutter build apk \
  --dart-define=APP_ENV=staging \
  --dart-define=FIREBASE_PROJECT_ID=recaller-staging \
  --dart-define=ENABLE_APP_CHECK=true \
  --dart-define=GEMINI_API_KEY=YOUR_STAGING_GEMINI_KEY
```

### Production Release Build:
```bash
flutter build apk --release \
  --dart-define=APP_ENV=production \
  --dart-define=FIREBASE_PROJECT_ID=recaller-prod \
  --dart-define=ENABLE_APP_CHECK=true \
  --dart-define=GEMINI_API_KEY=YOUR_PROD_GEMINI_KEY \
  --dart-define=RECAPTCHA_SITE_KEY=YOUR_WEB_RECAPTCHA_KEY
```

---

## 5. Firebase App Check Provider Architecture

Implemented in `lib/core/security/app_check_service.dart`:

```dart
abstract class AppCheckService {
  Future<void> activate();
  bool get isActivated;
  AppCheckProviderType get activeProviderType;
  Map<String, dynamic> get diagnostics;
}
```

### Production Provider Mapping:
- **Android**: `AndroidProvider.playIntegrity` (Attests APK signature and Google Play licensing).
- **iOS / macOS**: `AppleProvider.appAttestWithDeviceCheckFallback` (Hardware-backed device attestation).
- **Web**: `ReCaptchaV3Provider` (Invisible bot detection).
- **Development**: `AndroidProvider.debug` / `AppleProvider.debug`.

### Security Invariants:
1. **Idempotence**: Guaranteed to initialize at most once across the application lifecycle.
2. **Safe Diagnostics**: Telemetry exposes `isActivated` and `providerType` without exposing private attestation tokens or site secrets.
3. **Fail-Safe Startup**: If App Check encounters a transient network error during initialization, the bootstrap phase logs a sanitized warning and allows the app shell to render without crashing.

---

## 6. Firebase Local Emulator Workflow

To run the local Firebase Emulator Suite during development:

```bash
# 1. Start Firebase Emulators
firebase emulators:start --only auth,firestore,storage

# 2. Run Recallr with Emulator Flags
flutter run \
  --dart-define=APP_ENV=development \
  --dart-define=USE_EMULATORS=true \
  --dart-define=EMULATOR_HOST=10.0.2.2  # For Android Emulator
  # or --dart-define=EMULATOR_HOST=localhost # For Web / iOS Simulator
```

### Default Port Assignments:
- **Authentication**: `9099`
- **Cloud Firestore**: `8080`
- **Cloud Storage**: `9199`
- **Emulator UI**: `4000`

---

## 7. Deployment Pipeline & Quality Gates

```text
┌─────────────────────────────────────────────────────────────┐
│                    1. Static Analysis                       │
│                     flutter analyze                         │
│                    (Zero issues gate)                       │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                   2. Automated Test Suite                   │
│                        flutter test                         │
│                 (30 Suites / 474+ Tests)                    │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│             3. Security Rules Pre-deploy Check              │
│       test/firebase_rules_emulator_test.dart                │
│       test/security_rules_test.dart                         │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│               4. Staging Verification Gate                  │
│       Deploy to Staging Firebase & QA Smoke Test            │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│              5. Production Release Deployment               │
│          App Store / Google Play / Web Release              │
└─────────────────────────────────────────────────────────────┘
```

---

## 8. Rollback Strategy

In the event of a production incident:
1. **Firestore & Storage Rules**: Rules are version-controlled in Git. Instant rollback via `firebase deploy --only firestore:rules,storage`.
2. **App Check Misconfiguration**: If device attestation experiences third-party outages, App Check enforcement can be toggled from "Enforce" to "Monitor" in the Firebase Console without requiring a client app update.
3. **Gemini AI Outage**: If Gemini experiences elevated latency or 429 rate limits, Recallr automatically degrades gracefully to the local `DeterministicAiAnswerGenerator` without crashing AskScreen.