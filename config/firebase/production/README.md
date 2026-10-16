# Production Firebase Environment

- Project ID: `recaller-prod` (Dedicated production project)
- App Check Provider: `PlayIntegrity` (Android) / `AppAttest` (iOS) / `ReCaptchaV3` (Web)
- Emulators: FORBIDDEN
- Logging: Minimal safe logging, zero debug logs
- Build Command:
  ```bash
  flutter build apk \
    --dart-define=APP_ENV=production \
    --dart-define=GEMINI_API_KEY=YOUR_PROD_GEMINI_KEY \
    --dart-define=FIREBASE_PROJECT_ID=recaller-prod
  ```