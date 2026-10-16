# Recallr — Person Detail / Relationship Dossier Firestore Architecture (Phase 13C-03)

## 1. Executive Summary
Phase 13C-03 wires the **Person / Relationship Memory Detail** surface (`PersonDetailScreen`) to live **Cloud Firestore** streams while maintaining 100% backward compatibility with all UI mock modes, test harnesses, and responsive designs.

The dossier document resides under `/users/{authenticatedUid}/people/{personId}`, ensuring that a person's core directory item and their rich relationship intelligence dossier share the same canonical identity and document root.

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
PersonDetailRepository
     │
     ▼
FirestorePersonDetailRepository
     │
     ▼
/users/{authenticatedUid}/people/{personId}
```

### Document Schema (`/users/{uid}/people/{personId}`)
```json
{
  "id": "per_301",
  "name": "Dr. Priya Sharma",
  "role": "Principal Architect & SLM Lead",
  "company": "Microsoft Research India",
  "companyId": "comp_msr",
  "email": "priya.sharma@microsoft.com",
  "phone": "+91 98765 43210",
  "location": "Bengaluru / Hyderabad",
  "initials": "PS",
  "relationshipType": "collaborator",
  "relationshipStrength": "Core Network",
  "firstMet": "India AI Summit 2024",
  "lastInteraction": "2 days ago · Coffee catch-up",
  "totalInteractions": 8,
  "sharedEventsCount": 3,
  "aiSummary": "Leading edge research on quantization for Indic SLMs.",
  "keyTakeaways": ["Specializes in RISC-V LLVM quantization", "Key speaker at Bengaluru AI Summit"],
  "capabilities": ["Quantization", "SLMs", "RISC-V", "LLVM"],
  "timeline": [
    {
      "id": "time_1",
      "type": "meeting",
      "title": "Coffee catch-up at Indiranagar",
      "subtitle": "Discussed edge deployment",
      "date": "2 days ago",
      "locationOrEvent": "Third Wave Coffee, Indiranagar",
      "summary": "Priya shared insights on 4-bit quantization.",
      "keyBullets": ["Explored ONNX runtime", "Agreed to exchange drafts"],
      "targetRoute": "/interaction/time_1"
    }
  ],
  "memories": [
    {
      "id": "mem_1",
      "category": "Expertise",
      "text": "Specializes in INT4 quantization on ARM and RISC-V",
      "isVerified": true,
      "source": "India AI Summit 2024",
      "timestamp": "Nov 2024"
    }
  ],
  "followUps": [
    {
      "id": "fol_1",
      "title": "Send SLM quantization benchmark paper",
      "personName": "Dr. Priya Sharma",
      "personId": "per_301",
      "dueDate": "Tomorrow",
      "commitmentType": "iPromised",
      "targetRoute": "/follow-up/fol_1"
    }
  ],
  "connectedEntities": [
    {
      "id": "ent_1",
      "type": "company",
      "title": "Microsoft Research",
      "subtitle": "Enterprise AI",
      "targetRoute": "/company/comp_msr"
    }
  ],
  "promptSuggestions": ["What were Priya’s thoughts on 4-bit quantization?"],
  "userId": "usr_auth_789",
  "createdAt": "2026-08-28T10:30:00.000Z",
  "updatedAt": "2026-08-28T10:30:00.000Z"
}
```

---

## 3. Key Components & Implementation

### 1. Model Serialization (`PersonProfile`)
- Enriched with `email`, `phone`, `userId`, `createdAt`, `updatedAt`.
- Added resilient initials fallback computation: `PersonProfile.computeInitials(name)` if `initials` is omitted.
- Robust parsing for `Timestamp`, `DateTime`, ISO-8601 strings, and `null`.

### 2. Repository Layer (`FirestorePersonDetailRepository`)
- **Strict User Scoping**: Queries and writes are strictly restricted to `/users/{FirebaseAuth.currentUser.uid}/people/{personId}`.
- **Fail-Closed Security**: Throws `RecallrDataException.unauthenticated()` if no session is active.
- **Server Timestamps**: Auto-stamps `userId: _uid` and `updatedAt: FieldValue.serverTimestamp()`.
- **Atomic Operations**:
  - `addTimelineItem()`: prepends interaction and increments `totalInteractions`.
  - `addMemoryItem()`: prepends memory claim and updates `updatedAt`.

### 3. Screen Integration (`PersonDetailScreen`)
- Injects repository via `widget.repository ?? context.personDetailRepo`.
- Subscribes to live `_repository.streamProfile(widget.personId)` in live mode.
- Respects explicit UI flags (`initialProfile`, `isLoading`, `isError`) during widget testing.
- Disposes of stream subscriptions cleanly.
- Preserves all 10 dossier sections, actions, and responsive layout grids.

---

## 4. Verification

- **Static Analysis**: `flutter analyze` = 0 issues.
- **Unit & Integration Tests**: `flutter test` = **160 / 160 tests passing (100%)**.