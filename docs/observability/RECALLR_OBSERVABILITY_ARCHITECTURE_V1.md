# Recallr Production Observability, Error Telemetry & Operational Monitoring v1

## 1. Architecture Overview

Phase 13F-03 establishes comprehensive operational observability, crash reporting, telemetry, performance metrics, and health diagnostics for Recallr.

```text
                           Recallr Application
                                    ↓
┌───────────────────────────────────┬───────────────────────────────────┐
│       Flutter Error Boundary      │      Repository & Service Hooks   │
│   FlutterError.onError            │      PerformanceTracker           │
│   PlatformDispatcher.instance     │      SafeLogger                   │
└─────────────────┬─────────────────┴─────────────────┬─────────────────┘
                  │                                   │
                  ▼                                   ▼
┌───────────────────────────────────┐ ┌───────────────────────────────────┐
│     CrashReportingService         │ │       TelemetryService            │
│   (Fatal & Non-Fatal Errors)      │ │   (Deduplicated Events & Metrics) │
└─────────────────┬─────────────────┘ └─────────────────┬─────────────────┘
                  │                                   │
                  └─────────────────┬─────────────────┘
                                    │
                                    ▼
┌───────────────────────────────────────────────────────────────────────┐
│                  Privacy & Sanitization Boundary                      │
│   • Redacts: API Keys, Tokens, UIDs, Emails, Phones, Raw Memories     │
│   • Enforces: Bounded Payloads, Typed Categories, Zero Secrets       │
└───────────────────────────────────┬───────────────────────────────────┘
                                    │
                                    ▼
┌───────────────────────────────────────────────────────────────────────┐
│             Production Diagnostics & Feature Health Metrics           │
│   • Aggregate counters across People, Capture, OCR, AI, and Storage   │
│   • SystemHealthReport (Healthy / Degraded / Unavailable)             │
└───────────────────────────────────────────────────────────────────────┘
```

---

## 2. Privacy & Data Exfiltration Boundary

To protect personal relationship memories and confidential user data, the following elements are **STRICTLY PROHIBITED** from entering telemetry, crash logs, and analytics:

| Category | Strictly Prohibited Items | Safe Telemetry Substitution |
| :--- | :--- | :--- |
| **Authentication** | Firebase UIDs, passwords, OAuth tokens, Bearer JWTs | Anonymous session count, event: `auth_signed_in` |
| **Secrets & Keys** | Google / Gemini API Keys (`AIza...`), service keys | `provider: gemini`, `geminiConfigured: true` |
| **PII & Contacts** | Names, email addresses, phone numbers, addresses | `feature: people`, operation: `writePerson` |
| **Relationship Data**| Raw memories, dossiers, notes, interaction text | `feature: relationshipMemory`, status: `enriched` |
| **Capture Intelligence**| Raw OCR text, audio transcripts, image URLs | `feature: ocr`, `modality: card`, `status: success` |
| **AI Queries** | Raw user questions, prompt templates, answers | `feature: geminiAi`, `answerState: grounded` |
| **Cloud Storage** | Storage signed download URLs, private storage paths | `feature: storage`, `operation: uploadMedia` |

---

## 3. Telemetry Event Taxonomy

All events are strictly typed and categorized by feature domain:

### Bootstrap & System
- `app_started`: Application startup triggered.
- `firebase_initialized`: Firebase Core successfully initialized.
- `app_check_activated`: Device attestation active with provider (`playIntegrity`, `appAttest`, `reCaptchaV3`).
- `bootstrap_validation_failed`: Pre-flight configuration validation failure.

### Authentication
- `auth_signed_in`: Successful user authentication.
- `auth_signed_out`: User signed out.
- `auth_failure`: Authentication failed with safe error category.

### Capture & Storage Pipeline
- `capture_created`: User initiated capture modality.
- `capture_saved`: Capture document committed to Firestore.
- `storage_upload_success`: Media binary uploaded to Cloud Storage.
- `storage_upload_failed`: Media upload failure (retryable/network).
- `ocr_success` / `ocr_failed`: Text extraction completed or soft-failed.
- `entity_matched` / `entity_created`: Entity resolution outcome.
- `rel_enriched` / `rel_failed`: Relationship timeline enrichment outcome.

### Ask & Gemini AI
- `ai_request_started`: User submitted a network memory query.
- `ai_request_completed`: Grounded or ungrounded synthesis completed.
- `ai_fallback_used`: Deterministic fallback activated due to API limits or network.
- `ai_request_failed`: Gemini completion error (timeout, 429, malformed).

---

## 4. Severity Classification Model

| Severity | Usage Criteria | Telemetry Action |
| :--- | :--- | :--- |
| `debug` | Verbose development traces | Suppressed in production builds |
| `info` | Normal lifecycle milestones | Logged, metrics updated |
| `warning` | Soft failures (e.g. OCR unreadable, fallback used) | Deduplicated (5s window), warning log |
| `error` | Operation failure (network down, permission denied) | Deduplicated (5s window), error log |
| `fatal` | Uncaught crash, bootstrap abort | Always recorded in crash reporting |

---

## 5. Gemini AI Operational Monitoring

Operators can monitor Gemini AI health and performance without inspecting private queries:

```text
┌─────────────────────────────────────────────────────────────┐
│                 Gemini Operational Dashboard                │
├───────────────────────────────┬─────────────────────────────┤
│ Total Inquiries:      1,420   │ Grounded Rate:        94.2% │
│ Gemini Successes:     1,380   │ Fallback Rate:         2.8% │
│ Rate Limited (429):       4   │ Timeouts (>15s):          2 │
│ Average Latency:      840ms   │ Provider Status:    HEALTHY │
└───────────────────────────────┴─────────────────────────────┘
```

### Key Health Signals:
1. **Fallback Rate (`geminiFallback / aiQuestions`)**: If $>10\%$, indicates API quota exhaustion or elevated latency.
2. **Rate Limits (`geminiRateLimited`)**: Triggers alert to scale Gemini API tier.
3. **Timeout Rate (`geminiTimeout`)**: Alerts when network latency exceeds 15 seconds.

---

## 6. Incident Response & Recovery Model

```text
[Healthy] ──────────► [Degraded] ──────────► [Incident]
   ▲                       │                     │
   │ (Recovery)            │ (Fail-soft)         │ (Emergency)
   │                       ▼                     ▼
[Restored] ◄────────── [Fallback] ◄──────── [Mitigation]
```

1. **Phase 1: Automated Fail-Soft**:
   - Gemini outage $\rightarrow$ Automatic seamless switch to `DeterministicAiAnswerGenerator`.
   - OCR failure $\rightarrow$ Capture saved as unindexed document for manual review.
2. **Phase 2: App Check Outage Mitigation**:
   - Switch App Check from "Enforce" to "Monitor" via Firebase Console.
3. **Phase 3: Hotfix & Recovery**:
   - Push Firestore / Storage rules or release candidate hotfix.