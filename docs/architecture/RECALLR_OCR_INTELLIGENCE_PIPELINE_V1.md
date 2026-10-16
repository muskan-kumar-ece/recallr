# Recallr — OCR & Document Intelligence Pipeline (Phase 13D-04)

## 1. Executive Summary
Phase 13D-04 enhances Recallr's Capture Processing Foundation with a production-ready **OCR and Document Intelligence Pipeline**. The architecture enables optical character recognition on local device images and documents, extracts structured relationship entities deterministically (person name, title/role, company, email, phone, website, location, date), and stores the resulting intelligence directly on canonical Firestore capture documents (`/users/{uid}/captures/{captureId}`).

---

## 2. OCR Architecture Pipeline

```text
                  User Ingests Media
          (Business Card, Photo, Document)
                          │
                          ▼
                 MediaStorageRepository
             (Persists to Firebase Storage)
                          │
                          ▼
                  CaptureRepository
            (Persists Item to Firestore)
                          │
                          ▼
             CaptureProcessingRepository
                          │
                          ▼
              CaptureProcessingService
                          │
                          ▼
                   OcrService Contract
                          │
         ┌────────────────┴────────────────┐
         ▼                                 ▼
   MlKitOcrService                   MockOcrService
(Google ML Kit Latin)           (Deterministic Offline)
         │                                 │
         └────────────────┬────────────────┘
                          ▼
                      OcrResult
            (text, blocks, lines, confidence)
                          │
                          ▼
                 OcrEntityExtractor
     (Deterministic Pattern & Heuristic Extractor)
     ┌───────────────────────────────────────────┐
     │ • Name: Capitalized top lines / Email user│
     │ • Role: VP, Director, Architect, Lead ... │
     │ • Company: Inc, LLC, Tech, Labs, Domain...│
     │ • Email: Standard RFC email regex         │
     │ • Phone: E.164 / International / US format│
     │ • Website: FQDN & Protocol URLs           │
     │ • Location: Geo keywords & street patterns│
     │ • Date: ISO & human date patterns         │
     └───────────────────────────────────────────┘
                          │
                          ▼
            Merge into Canonical Document
         (/users/{uid}/captures/{captureId})
```

---

## 3. OCR Domain Models (`lib/features/capture/models/ocr_models.dart`)

### 1. `OcrTextLine`
- `text`: Recognized line text.
- `confidence`: Certainty score (0.0 to 1.0).

### 2. `OcrTextBlock`
- `text`: Multi-line block text.
- `confidence`: Block-level confidence.
- `boundingBox`: Spatial coordinates (`left`, `top`, `width`, `height`).
- `lines`: Ordered list of `OcrTextLine` items.

### 3. `OcrResult`
- `text`: Complete concatenated text.
- `confidence`: Overall extraction score.
- `language`: Detected language (e.g. `en`).
- `blocks`: Structural text blocks.
- `lines`: Individual text lines.
- `metadata`: Provider diagnostics.

### 4. `OcrExtractedEntities`
- `name`: Detected person name.
- `role`: Detected professional role.
- `company`: Detected company or organization.
- `email`: Extracted email address.
- `phone`: Extracted phone number.
- `website`: Extracted website URL.
- `location`: Extracted location/address.
- `date`: Extracted date.
- `keyPoints`: Unstructured takeaway lines.

---

## 4. Key Contracts & Services

- **`OcrService`** (`lib/services/ocr/ocr_service.dart`):
  Provider-agnostic interface with `extractText({required String mediaPath, String? mimeType})` and `dispose()`.
- **`MlKitOcrService`** (`lib/services/ocr/mlkit_ocr_service.dart`):
  Production on-device implementation using Google ML Kit Text Recognition (`google_mlkit_text_recognition`).
- **`MockOcrService`** (`lib/services/ocr/mock_ocr_service.dart`):
  Deterministic mock provider for headless unit, widget, and CI testing.
- **`OcrEntityExtractor`** (`lib/services/ocr/ocr_entity_extractor.dart`):
  Regex and heuristic parser for deterministic field extraction.

---

## 5. Dependency Injection

- Added `ocrService` to `RecallrDependencies`:
  - `RecallrDependencies.production`: Injects `MlKitOcrService` and wires it to `DeterministicCaptureProcessingService`.
  - `RecallrDependencies.mock`: Injects `MockOcrService`.
  - `context.ocrService`: Convenient `BuildContext` accessor.

---

## 6. Failure Separation & Non-Destructive Invariant

- **Media save failure**: Capture save fails; Storage uploaded media is cleaned up.
- **OCR / Processing failure**: Capture **REMAINS SAVED**; Storage media is **RETAINED**; UI displays retry option.
- **Retry**: Re-executes on the existing `captureId` without creating duplicate records or re-uploading media.

---

## 7. Verification Metrics
- **Static Analysis**: `flutter analyze` = **0 issues**
- **Automated Test Suite**: `flutter test` = **256 / 256 passing (100%)**