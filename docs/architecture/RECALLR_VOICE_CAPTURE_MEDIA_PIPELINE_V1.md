# Recallr — Voice Capture & Audio Storage Pipeline Architecture (Phase 13D-02)

## 1. Executive Summary
Phase 13D-02 establishes Recallr’s **Voice Capture Foundation**, replacing simulated voice-memo recording inside Omni-Capture Hub (`CaptureModal`) with a real device-based microphone recording and Firebase Storage persistence pipeline. Audio memos captured during relationship encounters are recorded to local `.m4a` files, uploaded to **Firebase Storage** under user-scoped paths (`users/{uid}/captures/{captureId}/original.m4a`), and metadata (including `durationSeconds`, `mediaUrl`, `storagePath`, `fileSize`, `mimeType`) is persisted to **Cloud Firestore** (`/users/{uid}/captures/{captureId}`).

---

## 2. End-to-End Voice Capture Pipeline

```text
               User Action (Voice Memo)
                         │
                         ▼
                    CaptureModal
                         │
                         ▼
        AudioRecorderService.startRecording()
                         │
                         ▼
            Microphone & Hardware Audio Input
                         │
                         ▼
       Real-Time Duration Stream (durationStream)
                         │
                         ▼
        AudioRecorderService.stopRecording()
                         │
                         ▼
                  RecordedAudioFile
      (path, name, size, mimeType, duration, bytes)
                         │
                         ▼
                 CaptureReviewView
                         │
                         ▼
       MediaStorageRepository.uploadCaptureAudio()
                         │
                         ▼
   Firebase Storage (/users/{uid}/captures/{id}/original.m4a)
                         │
                         ▼
                 UploadMediaResult
     (mediaUrl, storagePath, mimeType, fileSize)
                         │
                         ▼
       CaptureRepository.saveCapture(CaptureItem)
                         │
                         ▼
    Cloud Firestore (/users/{uid}/captures/{captureId})
```

---

## 3. Storage Security & Multi-Tenant Isolation

### Storage Rules (`storage.rules`)
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

    // User capture media (Images & Audio): /users/{userId}/captures/{captureId}/{fileName}
    match /users/{userId}/captures/{captureId}/{fileName} {
      allow read, write: if isOwner(userId);
    }

    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### Firestore Security Rules (`firestore.rules`)
```text
match /users/{userId}/captures/{captureId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

- **Strict Multi-Tenant Isolation**: Neither audio files nor Firestore metadata can be accessed or modified across users.
- **Fail-Closed Auth Guard**: Repository methods resolve `FirebaseAuth.instance.currentUser?.uid` internally and reject unauthenticated requests with `RecallrDataException.unauthenticated()`.

---

## 4. Controlled Partial Failure & Cleanup Strategy

In distributed cloud architectures, an upload may succeed in Firebase Storage, but the subsequent Firestore document write might fail due to connectivity interruption. Recallr implements controlled cleanup:

```text
1. Upload audio to Firebase Storage -> Success (storagePath recorded)
2. Persist metadata to Cloud Firestore -> Throws Exception
3. Catch block initiates Storage cleanup:
   deleteCaptureMedia(captureId, storagePath)
4. UI transitions to recoverable CaptureState.error
```

---

## 5. Key Component Specifications

### 1. `AudioRecorderService` (`lib/services/audio_recorder_service.dart`)
- **Domain Model**: `RecordedAudioFile(path, name, size, mimeType, duration, bytes)`.
- **Contracts**:
  - `hasPermission()`
  - `startRecording({String? customPath})`
  - `stopRecording()`
  - `cancelRecording()`
  - `durationStream`
  - `isRecording`
  - `dispose()`
- **Production**: `DeviceAudioRecorderService` leveraging `record` package (`RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100)`).
- **Testing**: `MockAudioRecorderService` simulating duration ticks, cancellation, permission denial, and failure modes.

### 2. `MediaStorageRepository` Extension
- Contract updated with `uploadCaptureAudio({required String captureId, required RecordedAudioFile file, onProgress})`.
- In `FirebaseMediaStorageRepository`:
  - Scoped to `users/{uid}/captures/{captureId}/original.m4a`.
  - Sets `SettableMetadata(contentType: 'audio/m4a', customMetadata: {'durationSeconds': ...})`.
  - Streams real-time upload progress.

### 3. Canonical Domain Model Extension (`CaptureItem`)
- Added nullable `final int? durationSeconds;`.
- Symmetrical serialization across `toMap()`, `fromMap()`, `fromFirestore()`, and `copyWith()`.
- Backward compatible with non-audio captures and legacy captures lacking duration.

### 4. Dependency Injection
- Injected `AudioRecorderService` into `RecallrDependencies` and `RecallrScope`.
- Provided `context.audioRecorderService` accessor.

---

## 6. Scope Exclusions (Strictly Preserved for Subsequent Phases)
The following are explicitly omitted from Phase 13D-02:
- Speech-to-text / automatic audio transcription.
- Gemini API multimodal ingestion / entity synthesis.
- Vector embeddings and RAG over voice memos.
- Speaker identification and sentiment scoring.

---

## 7. Verification & Regression Metrics
- **Static Analysis**: `flutter analyze` = **0 issues**
- **Unit & Widget Tests**: `flutter test` = **210 / 210 passing (100%)**