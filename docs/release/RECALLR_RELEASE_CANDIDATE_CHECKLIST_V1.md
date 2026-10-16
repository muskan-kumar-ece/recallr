# Recallr Release Candidate Deployment & Release Checklist v1.0.0-rc1

## 1. Prerequisites & Build Environment

- Flutter SDK: `^3.5.0`
- Dart SDK: `^3.5.0`
- Target Platforms: Android (API 24+), iOS (iOS 15.0+), Web (Modern Evergreen Browsers)
- Firebase CLI: `latest`

---

## 2. Release Candidate Verification Pipeline

### Step 1: Clean & Dependencies
```bash
flutter clean
flutter pub get
```

### Step 2: Static Analysis
```bash
flutter analyze
# Must output: No issues found!
```

### Step 3: Automated Test Execution
```bash
flutter test
# Must output: All 505 tests passed across 34 suites!
```

### Step 4: Security Rules Deployment
```bash
firebase use recaller-prod
firebase deploy --only firestore:rules,storage
```

### Step 5: Production Android Build
```bash
flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=FIREBASE_PROJECT_ID=recaller-prod \
  --dart-define=ENABLE_APP_CHECK=true \
  --dart-define=GEMINI_API_KEY=PROD_GEMINI_KEY_VALUE
```

### Step 6: Production iOS Build
```bash
flutter build ipa --release \
  --dart-define=APP_ENV=production \
  --dart-define=FIREBASE_PROJECT_ID=recaller-prod \
  --dart-define=ENABLE_APP_CHECK=true \
  --dart-define=GEMINI_API_KEY=PROD_GEMINI_KEY_VALUE
```

---

## 3. Rollback & Contingency Procedures

- **App Check Issues**: If attestation causes device false-positives, set App Check enforcement to "Monitor" in Firebase Console.
- **Gemini Outage / Latency**: The app automatically switches to the built-in deterministic fallback engine without crashing.
- **Rules Hotfix**: Deploy corrected rules instantly via `firebase deploy --only firestore:rules`.