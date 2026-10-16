# Recallr Production Operations, Disaster Recovery & Incident Response Runbook v1.0.0

## 1. System Overview & Architecture

Recallr is a dark-first relationship intelligence mobile app utilizing a hardened Firebase Serverless Architecture:
- **Client Tier**: Flutter (iOS 15.0+, Android API 24+, Modern Evergreen Web)
- **Identity & Access**: Firebase Authentication + Firebase App Check (Play Integrity on Android & App Attest on iOS)
- **Database**: Cloud Firestore (Multi-tenant isolated subcollections under `users/{uid}/*`)
- **Storage**: Firebase Storage (MIME/size-restricted media under `users/{uid}/captures/{captureId}/*`)
- **AI Intelligence**: Google Gemini API via SDK with Deterministic Grounded Fallback Engine
- **Observability**: `CrashReportingService`, `ProductionTelemetryService`, `PerformanceTracker`, `SafeLogger`

---

## 2. Startup Diagnostics & Health Checks

Upon client launch:
1. **Firebase Bootstrap** verifies Core initialization and environment settings.
2. **App Check** obtains device attestation from native provider.
3. **Fail-Closed Auth Check**: Repositories resolve `_auth.currentUser` dynamically on each read/write.
4. **Production Configuration Validator**: Enforces that no emulators, debug App Check providers, or development flags run in production.

---

## 3. Disaster Recovery & Backup Strategy

### Firestore Backups & Point-in-Time Recovery (PITR)
- **Point-in-Time Recovery (PITR)**: Enabled on production Firestore database `(default)` with a 7-day continuous recovery window.
- **Automated Daily Backups**: Scheduled Cloud Function export targeting `gs://recaller-prod-firestore-backups`.
- **Restore Command**:
  ```bash
  gcloud firestore databases restore \
    --source-backup=projects/recaller-prod/locations/nam5/backups/BACKUP_ID \
    --destination-database=RESTORED_DB_NAME
  ```

### Storage Backups & Object Versioning
- **Object Versioning**: Enabled on `gs://recaller-prod.appspot.com` to prevent accidental loss.
- **Lifecycle Policy**: Delete soft-deleted non-current versions after 30 days.

---

## 4. Firebase Security Rules Rollback Procedures

If a newly deployed security rule causes client regressions:

1. **Inspect previous rule version in Firebase Console History** or local Git tag `v1.0.0`.
2. **Deploy known good rules**:
   ```bash
   git checkout tags/v1.0.0 -- firestore.rules storage.rules firestore.indexes.json
   firebase deploy --only firestore,storage
   ```
3. **Verify rule deployment via automated test suite**:
   ```bash
   flutter test test/security_rules_test.dart test/security_boundary_test.dart
   ```

---

## 5. Emergency Outage & Fallback Procedures

### Gemini API Outage / Elevated Latency / Rate Limits
- The client-side `GeminiGroundedAnswerGenerator` automatically routes queries to `DeterministicAiAnswerGenerator` on timeouts ($>15\text{s}$), HTTP 429 rate limits, or parse errors.
- **No manual backend intervention required**.
- To globally disable remote Gemini calls during API degradation: revoke or rotate the `GEMINI_API_KEY` in Google Cloud Console.

### App Check False-Positive Emergencies
If legitimate user devices are blocked by Play Integrity / App Attest:
1. Open **Firebase Console $\rightarrow$ App Check**.
2. Select **Firestore** and **Cloud Storage**.
3. Toggle enforcement mode from **"Enforce"** to **"Monitor"**.
4. The backend will continue logging attestation metrics without denying requests.

### Authentication Outage Mitigation
- Repositories fail closed and present `RecallrDataException.unauthenticated` with safe retry triggers.
- Token refresh happens automatically via Firebase Auth SDK background loop.

---

## 6. Privacy Incident & Data Exfiltration Escalation

If an un-sanitized attribute is reported in telemetry:
1. **P0 Incident**: Immediately rotate telemetry ingestion endpoint / suppress logging.
2. Review `EnvironmentConfig.sanitizeForLog` regex filters.
3. Ensure no UID, Bearer token, Gemini key, email, or raw memory is logged.
4. Deploy client hotfix patch if necessary.

---

## 7. Operational SLA & Monitoring Thresholds

| Metric | Target SLA | Alert Threshold | Severity / Action |
| :--- | :---: | :---: | :--- |
| **Crash-Free Sessions** | $> 99.9\%$ | $< 99.5\%$ | P0 Incident $\rightarrow$ Halt rollout, inspect Crashlytics |
| **Firestore Query Latency (P95)** | $< 350\text{ms}$ | $> 1000\text{ms}$ | P1 Incident $\rightarrow$ Review missing composite indexes |
| **Gemini AI Fallback Rate** | $< 5.0\%$ | $> 15.0\%$ | P1 Incident $\rightarrow$ Check Gemini quota limits in Cloud Console |
| **Capture Media Upload Failure**| $< 1.0\%$ | $> 3.0\%$ | P2 Incident $\rightarrow$ Check Storage bucket permissions/MIME filters |
| **OCR Soft-Failure Rate** | $< 3.0\%$ | $> 8.0\%$ | P2 Incident $\rightarrow$ Inspect input image quality/ML Kit model updates |