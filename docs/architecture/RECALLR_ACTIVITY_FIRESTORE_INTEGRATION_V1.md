# Recallr — Activity Timeline Firestore Architecture (Phase 13C-04)

## 1. Executive Summary
Phase 13C-04 transitions Recallr’s **Activity / Relationship Timeline** (`ActivityScreen`) from static/mock data to a production **Cloud Firestore** reactive streaming pipeline. All activities are securely stored under `/users/{authenticatedUid}/activities/{activityId}`, automatically stamped with the authenticated user ID and server timestamps, and streamed live to the UI with search and category filtering.

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
ActivityRepository
     │
     ▼
FirestoreActivityRepository
     │
     ▼
/users/{authenticatedUid}/activities/{activityId}
```

### Document Schema (`/users/{uid}/activities/{activityId}`)
```json
{
  "id": "act_101",
  "type": "encounter",
  "period": "today",
  "timestamp": "10:45 AM",
  "title": "Met with Dr. Priya Sharma",
  "summary": "Met at India AI Summit to discuss quantization for Indic SLMs.",
  "personId": "per_301",
  "personName": "Dr. Priya Sharma",
  "personRole": "Principal Architect",
  "companyId": "comp_msr",
  "companyName": "Microsoft Research India",
  "location": "Bengaluru Convention Center",
  "relationshipIndicator": "New Connection · High Intent",
  "followUpStatus": "Follow-up Due: Tomorrow",
  "targetRoute": "/person/per_301",
  "actionLabel": "View Dossier",
  "isVerified": true,
  "metadata": {
    "event": "India AI Summit 2024",
    "badgeScanned": true
  },
  "userId": "usr_auth_456",
  "createdAt": "2026-08-28T10:30:00.000Z",
  "updatedAt": "2026-08-28T10:30:00.000Z"
}
```

---

## 3. Key Components & Implementation

### 1. Model Serialization (`ActivityItem`)
- Added `userId`, `createdAt`, and `updatedAt` properties.
- Resilient timestamp handling supporting `Timestamp`, `DateTime`, ISO-8601 `String`, and `null`.
- Defaulted `isVerified` safely to `true` if not explicitly `false`.
- Supported full round-trip `toMap()`, `fromMap()`, `fromFirestore()`, and `copyWith()`.

### 2. Repository Layer (`FirestoreActivityRepository`)
- **Strict User Scoping**: Always resolves `FirebaseAuth.instance.currentUser?.uid` internally.
- **Fail-Closed Security**: Throws `RecallrDataException.unauthenticated()` if no session is active.
- **Automatic Server Stamping**: Stamped with `userId: _uid`, `createdAt: FieldValue.serverTimestamp()`, and `updatedAt: FieldValue.serverTimestamp()`.
- **Search & Filtering**: Real-time snapshot filtering by search keyword (`title`, `summary`, `personName`, `companyName`, `location`) and category (`people`, `meetings`, `calls`, `notes`, `captures`, `files`, `followUps`).
- **CRUD Operations**: Complete support for `getActivity(id)`, `addActivity(item)`, and `deleteActivity(id)`.

### 3. Screen Integration (`ActivityScreen`)
- Resolves repository via `widget.repository ?? context.activityRepo`.
- Subscribes to live `_repository.streamActivities(query: _searchQuery, filter: _selectedFilter)` in live mode.
- Preserves all UI state machines: Loading, Populated, Empty, Search Empty, and Error.
- Cleans up subscriptions properly on `dispose()` and re-subscribes upon search or filter changes.
- Preserves responsive layouts (single-column mobile, two-column desktop with context inspector).

---

## 4. Verification

- **Static Analysis**: `flutter analyze` = 0 issues.
- **Automated Tests**: `flutter test` = **166 / 166 tests passing (100%)**.