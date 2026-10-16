# Recallr — Capture Processing & Metadata Intelligence Architecture (Phase 13D-03)

## 1. Executive Summary
Phase 13D-03 establishes Recallr’s **Capture Processing & Metadata Intelligence Foundation**. It introduces a dedicated, provider-agnostic processing layer that takes ingested captures (business cards, voice memos, quick notes, whiteboard photos, and spec documents) and transforms them into structured, searchable metadata persisted directly on canonical Firestore capture documents (`/users/{uid}/captures/{captureId}`).

---

## 2. Capture Processing Architecture

```text
                 Omni-Capture (CaptureModal)
                             │
                             ▼
                    CaptureRepository
                             │
                             ▼
                 CaptureProcessingRepository
                             │
                             ▼
                  CaptureProcessingService
                             │
          ┌──────────────────┼──────────────────┐
          ▼                  ▼                  ▼
     Image / Photo         Voice             Document & Note
        Capture           Capture                Capture
          │                  │                      │
          ▼                  ▼                      ▼
       Metadata            Audio                 Metadata
       Analysis          Metadata                Analysis
          │                  │                      │
          └──────────────────┼──────────────────────┘
                             ▼
                  Structured Capture Metadata
          (extractedText, summary, confidence, entities)
                             │
                             ▼
             Cloud Firestore (/users/{uid}/captures/{id})
```

---

## 3. Domain Model Architecture

### 1. `CaptureProcessingStatus`
```dart
enum CaptureProcessingStatus {
  pending,
  processing,
  completed,
  failed;
}
```

### 2. `CaptureProcessingResult` (`lib/features/capture/models/capture_processing_models.dart`)
- `captureId`: Canonical capture document identifier.
- `status`: Lifecycle processing status (`pending`, `processing`, `completed`, `failed`).
- `processedAt`: Timestamp when intelligence extraction completed.
- `title`: Derived subject or title.
- `summary`: High-level summary of encounter / document.
- `extractedText`: Raw extracted OCR text or audio transcript.
- `detectedPeople`: List of person entities detected.
- `detectedCompany`: Company/organization detected.
- `detectedLocation`: Geo or venue entity.
- `detectedDate`: Temporal entity.
- `confidence`: Extraction certainty score (0.0 to 1.0).
- `metadata`: Modality-specific extensible metadata.
- `errorMessage`: Error description if status is `failed`.

### 3. Extended Canonical `CaptureItem` (`lib/features/capture/models/capture_models.dart`)
Seamlessly extended with backward-compatible nullable fields:
- `processingStatus`
- `processedAt`
- `processingError`
- `extractedText`
- `summary`
- `confidence`

---

## 4. Key Contracts & Services

### 1. `CaptureProcessingRepository` (`lib/repositories/capture_processing_repository.dart`)
- `Future<CaptureItem> processCapture(CaptureItem capture)`
- `Future<CaptureProcessingResult?> getProcessingResult(String captureId)`
- `Stream<CaptureProcessingResult> streamProcessingResult(String captureId)`
- `Future<void> updateProcessingStatus(String captureId, CaptureProcessingStatus status, ...)`
- `Future<CaptureItem> retryProcessing(String captureId)`

### 2. `FirestoreCaptureProcessingRepository` (`lib/data/firestore/firestore_capture_processing_repository.dart`)
- Enforces internal authentication resolution via `FirebaseAuth.instance.currentUser?.uid`.
- Writes directly to `/users/{uid}/captures/{captureId}` using `SetOptions(merge: true)`.
- Updates `processingStatus`, timestamps, and derived fields.

### 3. `DeterministicCaptureProcessingService` (`lib/services/capture_processing_service.dart`)
- Provider-agnostic, deterministic processing engine.
- Extracts structured entity graphs without external AI vendor lock-in.
- Ready for pluggable provider adapters (e.g. Gemini, ML Kit, Whisper) in subsequent phases.

---

## 5. Failure Separation & Non-Destructive Behavior

A critical architectural invariant enforced in Phase 13D-03:

```text
Media Save Failure      →  Capture save fails; Storage uploaded media is cleaned up.
Processing Failure      →  Capture REMAINS SAVED; Storage media is RETAINED; UI shows retry option.
```

- Processing failure does **NOT** delete successfully saved captures or uploaded media files.
- Users are presented with clear extraction status ("Processed & Indexed" or "Entity extraction failed · Retry").
- Retrying re-executes on the existing capture record idempotently without creating duplicate documents or Storage assets.

---

## 6. Dependency Injection

- Extended `RecallrDependencies` and `RecallrScope` with:
  - `CaptureProcessingRepository` (`context.captureProcessingRepo`)
  - `CaptureProcessingService` (`context.captureProcessingService`)
- Production uses `FirestoreCaptureProcessingRepository` + `DeterministicCaptureProcessingService`.
- Tests use `MockCaptureProcessingRepository` + `MockCaptureProcessingService`.

---

## 7. Verification Metrics
- **Static Analysis**: `flutter analyze` = **0 issues**
- **Full Test Suite**: `flutter test` = **228 / 228 passing (100%)**