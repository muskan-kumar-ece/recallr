# Recallr Production Security Architecture & Environment Hardening v1

## 1. Executive Summary

Recallr is a dark-first, AI-assisted personal relationship intelligence application. Because relationship memory contains highly sensitive personal, professional, and contextual data, Recallr enforces a **defense-in-depth, zero-trust security architecture**.

The core security pillars:
1. **Firestore Single Source of Truth & Tenant Isolation**: Every document is strictly partitioned under `users/{userId}/*` with fail-closed rules and immutable ownership.
2. **Cloud Storage Ownership & Type Boundaries**: Media assets are confined to `users/{userId}/captures/{captureId}/*` with strict MIME whitelisting and a 25 MB maximum size limit.
3. **Fail-Closed Repository Authentication**: All production repositories resolve `FirebaseAuth.currentUser.uid` internally. Client-supplied UIDs are rejected.
4. **Air-Gapped Gemini Privacy Boundary**: Gemini never interacts with Firestore, Firebase Auth, or Firebase Storage. Gemini receives only bounded, sanitized in-memory context.
5. **Robust Input Sanitization**: Path traversal, control characters, null bytes, and unbounded strings are stripped before persistence or network transmission.
6. **Environment Hardening & App Check Readiness**: Explicit environment separation (`development`, `staging`, `production`), zero hardcoded credentials, and App Check provider mapping.

---

## 2. Authentication & Repository Tenant Isolation

```text
┌─────────────────────────────────────────────────────────────┐
│                 Client Layer (UI / ViewModel)               │
│                  Calls: repo.streamPeople()                 │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Zero client-supplied UID accepted)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│              Production Firestore Repository                │
│    String get _uid => _auth.currentUser?.uid                │
│    ├── If user == null: THROW RecallrDataException.unauth   │
│    └── Evaluated FIRST before any Firestore reference       │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│            Firebase Security Rules Authorization            │
│       match /users/{userId}/* { isOwner(userId) }           │
│       request.auth != null && request.auth.uid == userId    │
└─────────────────────────────────────────────────────────────┘
```

### Authoritative Internal UID Resolution
No repository accepts a `userId` argument from UI code or route parameters to determine tenant partition:
- `FirestorePeopleRepository`
- `FirestorePersonDetailRepository`
- `FirestoreActivityRepository`
- `FirestoreFollowUpRepository`
- `FirestoreCaptureRepository`
- `FirestoreCaptureProcessingRepository`
- `FirestoreMemoryRetrievalRepository`
- `FirebaseMediaStorageRepository`

If the user is logged out, the session has expired, or Firebase is uninitialized, every repository immediately throws `RecallrDataException.unauthenticated()` before allocating any network or database handles.

---

## 3. Firestore Security Rules Architecture

Located at `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    function isValidOwnerDoc(userId) {
      return !('userId' in request.resource.data) || request.resource.data.userId == userId;
    }

    function isImmutableOwnerDoc() {
      return !('userId' in request.resource.data) || request.resource.data.userId == resource.data.userId;
    }

    // Explicit User Subcollections
    match /users/{userId} {
      allow read: if isOwner(userId);
      allow create: if isOwner(userId) && isValidOwnerDoc(userId);
      allow update: if isOwner(userId) && isImmutableOwnerDoc();
      allow delete: if isOwner(userId);
    }

    match /users/{userId}/people/{personId} { ... }
    match /users/{userId}/activities/{activityId} { ... }
    match /users/{userId}/follow_ups/{followUpId} { ... }
    match /users/{userId}/captures/{captureId} { ... }
    match /users/{userId}/claims/{claimId} { ... }
    match /users/{userId}/interactions/{interactionId} { ... }

    // Fallback: Fail closed for any unmapped collections
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### Security Guarantees:
1. **Zero Open Rules**: No `allow read, write: if true;` or open top-level reads.
2. **Cross-Tenant Prevention**: User A cannot read, write, update, or delete User B documents under any circumstances.
3. **Immutable Ownership**: An update operation cannot mutate the `userId` field to hijack or transfer document ownership.
4. **Default Deny**: Unmapped collections default to `allow read, write: if false;`.

---

## 4. Cloud Storage Hardening & Media Security

Located at `storage.rules`:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    function isAllowedMimeType() {
      return request.resource.contentType.matches('image/(jpeg|png|webp)')
          || request.resource.contentType.matches('audio/(m4a|mp4|aac|mpeg|wav|webm)')
          || request.resource.contentType == 'application/pdf';
    }

    function isWithinSizeLimit() {
      return request.resource.size <= 25 * 1024 * 1024; // 25 MB
    }

    match /users/{userId}/captures/{captureId}/{fileName} {
      allow read, delete: if isOwner(userId);
      allow create, update: if isOwner(userId) && isAllowedMimeType() && isWithinSizeLimit();
    }

    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### Storage Security Guarantees:
- **Strict Path Scoping**: All media must reside under `/users/{userId}/captures/{captureId}/{fileName}`.
- **Whitelisted Content Types**: Executable scripts (`application/x-sh`, `application/javascript`, `application/x-msdownload`, HTML, raw binaries) are rejected.
- **25 MB Size Boundary**: File uploads exceeding 26,214,400 bytes are denied at both client and storage rule boundaries.

---

## 5. Gemini AI Privacy Boundary & Sanitization

```text
┌─────────────────────────────────────────────────────────────┐
│                       Authoritative                         │
│                    Cloud Firestore DB                       │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Strict Owner Isolated Query)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 MemoryRetrievalService                      │
│            Assembles Bounded MemoryContext                  │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                   GeminiPromptBuilder                       │
│    ├── Enforces 8,000 max context character budget          │
│    ├── Enforces 15 max candidate evidence items             │
│    ├── Redacts UIDs, Storage URLs, and internal paths       │
│    └── Injects 12 Anti-Hallucination Grounding Rules        │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Sanitized Text Prompt Only)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                   Gemini AI Provider                        │
│             (NO DATABASE OR CLOUD STORAGE ACCESS)           │
└─────────────────────────────────────────────────────────────┘
```

### The Gemini Grounding Invariant:
- **Gemini NEVER queries Firestore directly**.
- Gemini provider files (`gemini_ai_provider.dart`, `google_sdk_gemini_ai_provider.dart`, `gemini_prompt_builder.dart`, `gemini_grounded_answer_generator.dart`) contain **zero imports or instances of `cloud_firestore` or `firebase_storage`**.
- Private Firebase UIDs, auth tokens, database paths, and raw storage URLs (`gs://`, `firebase_storage`) are completely excluded from prompts.
- Output validation (`GroundedAnswerValidator`) checks that citations match candidate evidence IDs and drops any fabricated citations.

---

## 6. Input Sanitization & Validation

Implemented in `lib/core/security/input_sanitizer.dart`:

| Method | Security Check |
|---|---|
| `sanitizeQuery(query, {maxLength: 500})` | Removes null bytes (`\x00`), control chars, collapses whitespace, bounds length to 500. |
| `sanitizeText(text, {maxLength: 10000})` | Strips null bytes and control chars while preserving valid `\n` and `\t`, bounds length to 10,000. |
| `sanitizeName(name, {maxLength: 100})` | Preserves international diacritics and letters while stripping control characters. |
| `sanitizeEmail(email)` | Validates RFC-5322 compliance, lowercases, and bounds to 254 characters. |
| `sanitizePhone(phone)` | Strips invalid characters, enforces 5-20 digit length. |
| `isValidStoragePath(path, uid)` | Enforces `users/{uid}/captures/{captureId}/{fileName}` structure and rejects path traversal (`..`, `//`, `\`). |
| `isValidMimeType(mime, allowed)` | Validates against image, audio, and PDF MIME whitelist. |
| `isValidFileSize(bytes, {maxBytes: 25MB})` | Rejects empty (0) or oversized ($>25\text{ MB}$) files. |

---

## 7. Environment Hardening & App Check Readiness

Implemented in `lib/core/security/environment_config.dart`:

### Environment Separation:
- **`development`**: Local testing, verbose logging permitted.
- **`staging`**: Pre-production testing, debug App Check provider (`DebugAppCheckProvider`).
- **`production`**: Release compilation (`kReleaseMode`), debug logs suppressed, enforced App Check.

### App Check Provider Mapping:
- **Android**: `PlayIntegrityAppCheckProvider`
- **iOS**: `DeviceCheckProvider` / `AppAttestProvider`
- **Web**: `ReCaptchaV3AppCheckProvider`
- **Debug / Testing**: `DebugAppCheckProvider`

### Log Sanitization:
`EnvironmentConfig.sanitizeForLog(text)` automatically redacts:
- Google / Gemini API Keys (`AIzaSy...`) $\rightarrow$ `[REDACTED_API_KEY]`
- Bearer Tokens $\rightarrow$ `Bearer [REDACTED_TOKEN]`
- Private Firebase UIDs in paths $\rightarrow$ `users/[REDACTED_UID]/`

---

## 8. Comprehensive Security Test Matrix

| Test Suite | File | Tests Passing | Focus |
|---|---|---|---|
| Firestore & Storage Rules | `test/security_rules_test.dart` | **22 / 22** | Rule syntax, owner isolation, immutability, MIME whitelist, 25MB boundary, fail-closed defaults. |
| Repository & Gemini Boundary | `test/security_boundary_test.dart` | **10 / 10** | Fail-closed unauthenticated checks, internal UID resolution, Gemini air-gap isolation from Firestore. |
| Environment & Sanitization | `test/environment_security_test.dart` | **10 / 10** | Input sanitization, path traversal rejection, log redaction, zero hardcoded API keys audit. |
| Total Project Test Suite | `flutter test` | **446 / 446** | Complete regression verification across 26 test suites. |