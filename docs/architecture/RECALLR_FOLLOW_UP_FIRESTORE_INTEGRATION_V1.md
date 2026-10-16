# Recallr — Follow-ups & Relationship Commitments Firestore Architecture (Phase 13C-05)

## 1. Executive Summary
Phase 13C-05 transitions Recallr’s **Follow-ups / Relationship Commitments** surface (`FollowUpsScreen`) from static/mock state to a production-ready, authenticated, real-time **Cloud Firestore** data pipeline. All relationship commitments are securely stored under `/users/{authenticatedUid}/follow_ups/{followUpId}`, automatically stamped with authoritative user IDs and server timestamps, and streamed live to the UI with search, category filtering, summary statistics derivation, and persistent optimistic completion mutations.

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
FollowUpRepository
     │
     ▼
FirestoreFollowUpRepository
     │
     ▼
/users/{authenticatedUid}/follow_ups/{followUpId}
```

### Document Schema (`/users/{uid}/follow_ups/{followUpId}`)
```json
{
  "id": "fol_101",
  "title": "Send SLM quantization benchmark paper",
  "context": "Discussed 4-bit integer quantization over coffee catch-up.",
  "commitmentType": "iPromised",
  "status": "dueToday",
  "priority": "high",
  "dueDate": "Today · 5:00 PM",
  "createdDate": "Yesterday",
  "personId": "per_301",
  "personName": "Dr. Priya Sharma",
  "personRole": "Principal Architect & SLM Lead",
  "companyId": "comp_msr",
  "companyName": "Microsoft Research India",
  "sourceInteractionId": "act_101",
  "sourceMemoryTitle": "Coffee catch-up at Indiranagar",
  "sourceMemoryDate": "2 days ago",
  "location": "Bengaluru",
  "isVerified": true,
  "targetRoute": "/follow-up/fol_101",
  "isCompleted": false,
  "completedAt": null,
  "metadata": {
    "tag": "SLM-Benchmark"
  },
  "userId": "usr_auth_456",
  "createdAt": "2026-08-28T10:30:00.000Z",
  "updatedAt": "2026-08-28T10:30:00.000Z"
}
```

---

## 3. Key Components & Implementation

### 1. Canonical Domain Model (`FollowUpItem`)
- Retains single source of truth in `lib/features/follow_ups/models/follow_up_models.dart`.
- Uses canonical `CommitmentType` (`iPromised`, `theyPromised`, `followUp`, `waiting`, `overdue`) with `isIPromised` and `isTheyPromised` helpers.
- Added `userId`, `createdAt`, `updatedAt`, `completedAt`, and `clearCompletedAt` parameters.
- Resilient timestamp parsing supporting Firestore `Timestamp`, `DateTime`, ISO-8601 `String`, and `null`.
- Defaulted `isVerified` safely to `true` if not explicitly `false`.

### 2. Production Repository (`FirestoreFollowUpRepository`)
- **Strict User Scoping**: Resolves `FirebaseAuth.instance.currentUser?.uid` internally.
- **Fail-Closed Auth Guard**: Throws typed `RecallrDataException.unauthenticated()` if no session is active.
- **Server Timestamps**: Writes use `FieldValue.serverTimestamp()` for `createdAt`, `updatedAt`, and `completedAt`.
- **Persistent Completion Toggle**:
  - Setting complete: `isCompleted: true`, `status: completed`, `completedAt: FieldValue.serverTimestamp()`, `updatedAt: FieldValue.serverTimestamp()`.
  - Setting uncomplete: `isCompleted: false`, `status: dueToday`, `completedAt: null`, `updatedAt: FieldValue.serverTimestamp()`.
- **Live Search & Category Filtering**: Stream filters snapshot by search keyword across `title`, `context`, `personName`, `companyName`, `location`, and badge, and by `FollowUpFilter` (`all`, `dueToday`, `upcoming`, `waiting`, `overdue`, `completed`).
- **Live Statistics Stream**: Derives `todayCount`, `upcomingCount`, `waitingCount`, `overdueCount`, `completedCount`, and `totalActive` directly from the snapshot dataset.

### 3. Screen Integration (`FollowUpsScreen`)
- Injects repository via `widget.repository ?? context.followUpRepo`.
- Subscribes to live `_repository.streamFollowUps(query: _searchQuery, filter: _selectedFilter)` in live mode.
- Optimistic completion UI mutation with automatic rollback upon repository write error.
- Preserves all UI state machines: Loading, Populated, Empty, Search Empty, and Error.
- Preserves responsive layouts (single-column mobile, two-column desktop with relationship context inspector).

---

## 4. Verification

- **Static Analysis**: `flutter analyze` = 0 issues.
- **Automated Tests**: `flutter test` = **173 / 173 tests passing (100%)**.