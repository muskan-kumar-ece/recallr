# Recallr — Production Data Architecture v1
**Phase 13B Specification: Security Hardening + Canonical Domain Models + Production Repository Foundation**

---

## 1. Executive Summary

Phase 13B establishes the foundational data access, security rules, and canonical domain model contracts for Recallr. It transitions the application from isolated in-memory/mock UI states toward a clean, multi-tenant, authenticated repository layer backed by Cloud Firestore and offline-first repositories.

All existing Phase 01–12 UI surfaces (Home, People, Person Detail, Ask, Activity, Follow-ups, Omni-Capture Hub, App Shell, Navigation, Design Tokens) remain strictly **locked and preserved**.

---

## 2. Architecture Diagram

```
┌────────────────────────────────────────────────────────────────────────┐
│                          Recallr UI Layer                              │
│  (Home · People · Person Detail · Ask · Activity · Follow-ups · Hub)   │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   Abstract Repository Interfaces                       │
│  (PeopleRepository · PersonDetailRepo · ActivityRepo · FollowUpRepo)   │
└──────────────────┬──────────────────────────────────┬──────────────────┘
                   │                                  │
         ┌─────────┴─────────┐              ┌─────────┴─────────┐
         ▼                   ▼              ▼                   ▼
┌──────────────────┐┌──────────────────┐┌──────────────────┐┌──────────────────┐
│  Mock Repos      ││ Firestore Repos  ││ Data Exceptions  ││ Canonical Models │
│ (Deterministic   ││ (users/{uid}/*   ││ (Unauth, Denied, ││ (PersonItem,     │
│  test fixtures)  ││  scoped queries) ││  NotFound, Net)  ││  FollowUpItem)   │
└──────────────────┘└────────┬─────────┘└──────────────────┘└──────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────────────────┐
│                         Cloud Firestore                                │
│   /users/{userId} (Profile document)                                   │
│   /users/{userId}/people/{personId} (Directory & Dossiers)             │
│   /users/{userId}/activities/{activityId} (Timeline & Interactions)    │
│   /users/{userId}/follow_ups/{followUpId} (Commitments & Follow-ups)   │
│   /users/{userId}/captures/{captureId} (Ingested Omni-Captures)        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Security Hardening (`firestore.rules`)

### 3.1 Vulnerability Elimination
- **Legacy Issue**: The root collection `/items/{itemId}` previously permitted open reads to any authenticated user regardless of resource ownership.
- **Remediation**: The `/items/{itemId}` rule has been locked down so that reads, updates, and deletes strictly require `resource.data.userId == request.auth.uid`.
- **Immutable Ownership**: Updates to items forbid changing the `userId` field: `request.resource.data.userId == resource.data.userId`.
- **Fail-Closed Default**: Any unmapped collection in Firestore defaults to `allow read, write: if false;`.

### 3.2 Multi-Tenant User Isolation
All core domain collections are nested under `/users/{userId}/*` and enforce:
```javascript
function isAuthenticated() {
  return request.auth != null;
}

function isOwner(userId) {
  return isAuthenticated() && request.auth.uid == userId;
}

match /users/{userId} {
  allow read, write: if isOwner(userId);
}

match /users/{userId}/{document=**} {
  allow read, write: if isOwner(userId);
}
```

---

## 4. Canonical Domain Models & Serialization

### 4.1 FollowUpItem & Direction Consolidation
- **Resolved Conflict**: Removed redundant `FollowUpItem` and `FollowUpDirection` from `person_profile_model.dart`.
- **Unified Canonical Model**: `lib/features/follow_ups/models/follow_up_models.dart` now acts as the single source of truth for `FollowUpItem` and `CommitmentType` (`iPromised`, `theyPromised`, `followUp`, `waiting`, `overdue`).
- **Helpers**: Added `followUp.isIPromised` and `followUp.isTheyPromised` convenience getters.

### 4.2 Standardized Firestore Serialization
All domain models provide symmetrical serializers:
- `toMap()`: Serializes Dart entity into Firestore-compatible `Map<String, dynamic>`.
- `fromMap(Map<String, dynamic> map, [String? docId])`: Deserializes raw map with fallback defaults for missing fields.
- `fromFirestore(DocumentSnapshot doc)`: Directly parses Cloud Firestore documents.

| Domain Entity | File Location | Serializers Added |
|---|---|---|
| `PersonItem` | `lib/features/people/models/person_item.dart` | `toMap`, `fromMap`, `fromFirestore`, `copyWith` |
| `PersonProfile` | `lib/features/person_detail/models/person_profile_model.dart` | `toMap`, `fromMap`, `fromFirestore`, `copyWith` |
| `TimelineItem` | `lib/features/person_detail/models/person_profile_model.dart` | `toMap`, `fromMap` |
| `MemoryItem` | `lib/features/person_detail/models/person_profile_model.dart` | `toMap`, `fromMap` |
| `ConnectedEntity` | `lib/features/person_detail/models/person_profile_model.dart` | `toMap`, `fromMap` |
| `FollowUpItem` | `lib/features/follow_ups/models/follow_up_models.dart` | `toMap`, `fromMap`, `fromFirestore`, `copyWith` |
| `ActivityItem` | `lib/features/activity/models/activity_models.dart` | `toMap`, `fromMap`, `fromFirestore`, `copyWith` |
| `CaptureItem` | `lib/features/capture/models/capture_models.dart` | `toMap`, `fromMap`, `fromFirestore`, `copyWith` |
| `CaptureReviewData`| `lib/features/capture/models/capture_models.dart` | `toMap`, `fromMap` |
| `GroundedAnswer` | `lib/features/ask/models/ask_models.dart` | `toMap`, `fromMap` |

---

## 5. Standardized Error Architecture

Located in `lib/core/errors/data_exceptions.dart`:

```dart
enum DataErrorType {
  unauthenticated,
  permissionDenied,
  notFound,
  networkUnavailable,
  invalidData,
  unknown,
}
```

The `RecallrDataException` class encapsulates:
- Typed error category (`DataErrorType`)
- Human-readable error message for UI consumption
- Underlying exception (`originalError`) and `StackTrace`
- Automatic pattern matching from Firebase exceptions (`permission-denied`, `unauthenticated`, `not-found`, `unavailable`).

---

## 6. Repository Architecture

### 6.1 Abstract Interfaces (`lib/repositories/`)
- `PeopleRepository`: Stream people, filter directory, get person, add/update/delete.
- `PersonDetailRepository`: Stream/fetch 360-degree dossiers, add timeline encounters, record atomic memory claims.
- `ActivityRepository`: Stream chronological relationship timeline, category filters, record encounters.
- `FollowUpRepository`: Stream active/overdue commitments, toggle completion state, stream live stats.
- `CaptureRepository`: Ingest multi-modal captures (visiting cards, voice memos, notes), stream recent captures.

### 6.2 Implementations
1. **Mock Repositories** (`lib/data/mock/`):
   - `MockPeopleRepository`
   - `MockPersonDetailRepository`
   - `MockActivityRepository`
   - `MockFollowUpRepository`
   - `MockCaptureRepository`
   - Maintain instant test execution without requiring network connectivity or Firebase initialization.
2. **Firestore Repositories** (`lib/data/firestore/`):
   - `FirestorePeopleRepository`
   - `FirestorePersonDetailRepository`
   - `FirestoreActivityRepository`
   - `FirestoreFollowUpRepository`
   - `FirestoreCaptureRepository`
   - Lazy instantiation of `FirebaseFirestore` and `FirebaseAuth`.
   - Automatic `_uid` extraction with fail-closed unauthenticated exception handling.
   - User-scoped path queries under `users/{uid}/*`.

---

## 7. Verification & Regression Metrics

- **Static Analysis**: `flutter analyze` completed with **0 errors, 0 warnings**.
- **Unit & Widget Test Suite**: **139 / 139 tests passed (100% pass rate)**.
  - Phase 04 Navigation & Shell: 21 tests passed
  - Phase 05 Home Command Center: 21 tests passed
  - Phase 06 People Directory: 20 tests passed
  - Phase 08 Ask Grounded Memory: 19 tests passed
  - Phase 09 Activity Timeline: 20 tests passed
  - Phase 10 Follow-ups: 22 tests passed
  - Phase 11 Omni-Capture Hub: 22 tests passed
  - Phase 12 Person Memory Detail: 22 tests passed
  - Phase 13B Repository & Security Suite: 16 tests passed