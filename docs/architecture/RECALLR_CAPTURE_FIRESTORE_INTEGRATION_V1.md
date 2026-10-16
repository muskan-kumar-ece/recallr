# Recallr — Omni-Capture Hub Firestore Architecture (Phase 13C-06)

## 1. Executive Summary
Phase 13C-06 transitions Recallr’s **Omni-Capture Hub** (`CaptureModal`) from local state to a production-ready, authenticated, real-time **Cloud Firestore** data pipeline. Ingested memory captures across all 5 modalities (Business Card, Voice Memo, Quick Note, Photo, Document) are securely stored under `/users/{authenticatedUid}/captures/{captureId}`, stamped with authoritative user IDs and server timestamps, streamed live to the UI, and protected against duplicate submissions.

---

## 2. Target Architecture

```text
FirebaseAuth
     │
     ▼
authenticated UID
     │
     ▼
RecallrScope / BuildContext
     │
     ▼
CaptureRepository
     │
     ▼
FirestoreCaptureRepository
     │
     ▼
/users/{authenticatedUid}/captures/{captureId}
```

### Document Schema (`/users/{uid}/captures/{captureId}`)
```json
{
  "id": "cap_101",
  "type": "businessCard",
  "title": "Dr. Priya Sharma — Microsoft Research India",
  "description": "Principal Architect & SLM Lead, Bengaluru.",
  "timestamp": "Just now",
  "personId": "per_301",
  "personName": "Dr. Priya Sharma",
  "personRole": "Principal Architect & SLM Lead",
  "companyId": "comp_msr",
  "companyName": "Microsoft Research India",
  "eventName": "India AI Summit 2024",
  "location": "Bengaluru Convention Center",
  "targetRoute": "/person/per_301",
  "isVerified": true,
  "metadata": {
    "badge": "Speaker",
    "contactDetails": {
      "email": "priya.sharma@microsoft.com"
    }
  },
  "userId": "usr_auth_456",
  "createdAt": "2026-08-28T10:30:00.000Z",
  "updatedAt": "2026-08-28T10:30:00.000Z"
}
```

---

## 3. Key Components & Implementation

### 1. Canonical Domain Model (`CaptureItem`)
- Retains single source of truth in `lib/features/capture/models/capture_models.dart`.
- Full symmetrical serialization: `toMap()`, `fromMap()`, `fromFirestore()`, and `copyWith()`.
- Added `userId`, `createdAt`, and `updatedAt`.
- Resilient timestamp parsing supporting Firestore `Timestamp`, `DateTime`, ISO-8601 `String`, and `null`.
- Preserves all 5 modalities (`businessCard`, `voice`, `note`, `photo`, `document`).

### 2. Production Repository (`FirestoreCaptureRepository`)
- **Strict User Scoping**: Resolves `FirebaseAuth.instance.currentUser?.uid` internally.
- **Fail-Closed Auth Guard**: Throws typed `RecallrDataException.unauthenticated()` if no session is active.
- **Server Timestamps**: Writes use `FieldValue.serverTimestamp()` for `createdAt` and `updatedAt`.
- **Authoritative Stamping**: Injects `userId: _uid` automatically, never trusting client-supplied IDs.
- **Real-Time Recent Captures Stream**: `streamRecentCaptures({limit = 10})` delivers live snapshots from Firestore.
- **CRUD Operations**: `saveCapture(item)`, `getCapture(id)`, and `deleteCapture(id)`.

### 3. Screen Integration (`CaptureModal`)
- Resolves repository via `widget.repository ?? context.captureRepo`.
- Subscribes to live `_repository.streamRecentCaptures()` for recent capture history.
- Duplicate submission protection: prevents duplicate saves while in `CaptureState.saving`.
- Preserves all UI states: `idle`, `capturing`, `recording`, `processing`, `review`, `saving`, `saved`, `error`.
- Retains all visual design tokens, header styling, modal bottom sheet sizing, and responsive layouts.

---

## 4. Scope Exclusions (Preserved for Subsequent Phases)
The following are intentionally deferred to future phases:
- Hardware intake (Camera device access, native microphone recording, ML Kit on-device OCR, Speech-to-Text).
- AI extraction engines (Live Gemini API integration, embeddings, vector RAG).
- File storage (Firebase Storage binary uploads, signed URLs).

---

## 5. Verification

- **Static Analysis**: `flutter analyze` = 0 issues.
- **Automated Tests**: `flutter test` = **180 / 180 tests passing (100%)**.