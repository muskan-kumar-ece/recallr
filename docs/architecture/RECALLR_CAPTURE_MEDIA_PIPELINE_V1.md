# Recallr — Camera & Image Capture Media Pipeline Architecture (Phase 13D-01)

## 1. Executive Summary
Phase 13D-01 establishes Recallr’s **Camera & Image Capture Foundation**, bridging Omni-Capture Hub (`CaptureModal`) with a real device-based media intake and persistence pipeline. Captured encounter photos and whiteboard snapshots are securely stored in **Firebase Storage** under user-scoped paths (`users/{uid}/captures/{captureId}/original.{ext}`), while metadata is persisted to **Cloud Firestore** (`users/{uid}/captures/{captureId}`).

---

## 2. End-to-End Media & Metadata Architecture

```text
               User Action
                   │
                   ▼
              CaptureModal
                   │
                   ▼
           MediaPickerService (Camera / Gallery)
                   │
                   ▼
            PickedMediaFile (Local Preview & MIME Detection)
                   │
                   ▼
              CaptureReview
                   │
                   ▼
        MediaStorageRepository
                   │
                   ▼
    Firebase Storage (users/{uid}/captures/{captureId}/original.{ext})
                   │
                   ▼
        UploadMediaResult (mediaUrl, storagePath, mimeType, fileSize)
                   │
                   ▼
        CaptureItem (Metadata Integration)
                   │
                   ▼
       FirestoreCaptureRepository
                   │
                   ▼
   Cloud Firestore (/users/{uid}/captures/{captureId})
```

---

## 3. Storage & Firestore Security Model

### Firebase Storage Rules (`storage.rules`)
```text
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // User capture media: /users/{userId}/captures/{captureId}/{fileName}
    match /users/{userId}/captures/{captureId}/{fileName} {
      allow read, write: if isOwner(userId);
    }

    // Fail closed for all other unmapped paths
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### Cloud Firestore Rules (`firestore.rules`)
```text
match /users/{userId}/captures/{captureId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

- **Strict Multi-Tenant Isolation**: Neither media nor metadata can be read or mutated across different users.
- **Fail-Closed Verification**: Unauthenticated access throws `RecallrDataException.unauthenticated()`.

---

## 4. Key Component Specifications

### 1. `MediaPickerService`
- **Domain Model**: `PickedMediaFile(path, name, size, mimeType, bytes)`.
- **Contracts**: `pickFromCamera()` and `pickFromGallery()`.
- **Production**: `DeviceMediaPickerService` wrapping `ImagePicker` with automatic MIME-type inference, max dimensions (2048x2048), and quality optimization (85%).
- **Testing**: `MockMediaPickerService` for deterministic simulation without physical camera hardware.

### 2. `MediaStorageRepository`
- **Domain Model**: `UploadMediaResult(mediaUrl, storagePath, mimeType, fileSize)`.
- **Contracts**: `uploadCaptureImage(...)` with upload progress streaming, and `deleteCaptureMedia(...)`.
- **Production**: `FirebaseMediaStorageRepository` resolving `FirebaseAuth.instance.currentUser?.uid` internally and uploading to `users/{uid}/captures/{captureId}/original.{ext}`.
- **Testing**: `MockMediaStorageRepository` for offline and widget testing.

### 3. Canonical Domain Model Extension (`CaptureItem`)
- Added nullable fields: `mediaUrl`, `storagePath`, `mimeType`, and `fileSize`.
- Full symmetrical serialization: `toMap()`, `fromMap()`, `fromFirestore()`, and `copyWith()`.
- Backward compatible with existing captures lacking media fields.

### 4. UI & Capture Hub Integration
- **`PhotoDocCaptureView`**: Renders `Camera` and `Gallery` selection triggers, displaying local file thumbnail metadata.
- **`CaptureModal`**: Orchestrates media picking, local review, background Storage upload with progress display, and Firestore metadata persistence.
- Duplicate submission protection prevents double uploads while in `CaptureState.saving`.

---

## 5. Scope Exclusions (Preserved for Subsequent Phases)
The following are intentionally deferred:
- OCR and visiting card extraction (ML Kit, on-device OCR).
- AI entity extraction and memory synthesis (Gemini API, embeddings, RAG).
- Voice recording and audio storage.
- Document / PDF parsing.

---

## 6. Verification Results
- **Static Analysis**: `flutter analyze` = 0 issues.
- **Automated Tests**: `flutter test` = **193 / 193 passing (100%)**.