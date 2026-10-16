# Recallr Release Blocker Classification & Triage v1.0.0-rc1

## Classification Framework

- **P0 â€” Launch Blocker**: Critical issue preventing production deployment. Zero tolerance.
- **P1 â€” Must Fix Before Public Launch**: High-impact functional defect that degrades primary workflows.
- **P2 â€” Ship With Monitoring**: Non-blocking edge case or cosmetic issue acceptable for initial rollout.
- **P3 â€” Post-Launch Enhancement**: Optimization, refinement, or secondary platform parity feature.

---

## 1. P0 â€” Launch Blockers (Zero Found in Codebase)

| Item ID | Description | Status | Resolution / Verification |
| :--- | :--- | :--- | :--- |
| **P0-01** | Multi-tenant user data leakage across Firestore collections | **RESOLVED** | Hardened `firestore.rules` with `isImmutableOwnerDoc` & `isValidOwnerDoc`. Tested across all 7 user subcollections. |
| **P0-02** | Exposure of secrets, API keys, or private tokens in source code | **RESOLVED** | Automated regex scan verified 0 instances of hardcoded `GEMINI_API_KEY`, `private_key`, `client_secret`, or `Bearer` tokens. |
| **P0-03** | Fatal crash on unauthenticated data access | **RESOLVED** | Repositories fail closed with `RecallrDataException.unauthenticated` without throwing unhandled exceptions. |
| **P0-04** | Accidental connection to local emulators in production builds | **RESOLVED** | `FirebaseEmulatorHelper` and `ProductionConfigurationValidator` strictly abort execution if emulators are configured with `APP_ENV=production`. |
| **P0-05** | Storage upload orphan leak on Firestore commit failure | **RESOLVED** | Storage repository catches Firestore failure and deletes uploaded object automatically. Verified in `voice_capture_test.dart`. |

---

## 2. P1 â€” Must Complete Before Public Launch (External Infrastructure)

| Item ID | Description | Owner | Status | Blocker Type |
| :--- | :--- | :--- | :--- | :--- |
| **P1-01** | Register Android Play Integrity SHA-256 release fingerprint in Firebase Console | DevOps / Android Lead | **PENDING** | External Cloud Config |
| **P1-02** | Register Apple App Attest Team ID & Bundle ID in Firebase Console | DevOps / iOS Lead | **PENDING** | External Cloud Config |
| **P1-03** | Add ReCaptcha v3 Secret Key in Firebase Console for Web Domain | DevOps / Web Lead | **PENDING** | External Cloud Config |
| **P1-04** | Provision Firebase Blaze Plan to support production Storage & Firestore quotas | Account Owner | **PENDING** | External Billing |

---

## 3. P2 â€” Ship With Monitoring

| Item ID | Description | Mitigation Strategy |
| :--- | :--- | :--- |
| **P2-01** | Gemini API Rate Limits (HTTP 429) during burst user inquiries | Automatic seamless degradation to `DeterministicAiAnswerGenerator` with warning telemetry. |
| **P2-02** | Offline Capture Sync | Captures made during temporary connection loss degrade gracefully; UI prompts user to retry once reconnected. |
| **P2-03** | Low-contrast or blurry business card OCR | `DeterministicCaptureProcessingService` fail-soft behavior saves capture for manual review without failing the save operation. |

---

## 4. P3 â€” Post-Launch Enhancements

| Item ID | Description | Target Milestone |
| :--- | :--- | :--- |
| **P3-01** | Vector search and cloud embedding pipeline for multi-lingual semantic retrieval | v1.1.0 |
| **P3-02** | Background audio transcription streaming using Gemini Multimodal Live | v1.2.0 |
| **P3-03** | Automated calendar sync with Google Calendar and Outlook | v1.3.0 |