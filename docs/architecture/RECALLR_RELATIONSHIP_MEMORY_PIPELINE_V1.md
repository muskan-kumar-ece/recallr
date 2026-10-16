# Recallr Architecture — Phase 13D-06: Relationship Memory Enrichment & Timeline Intelligence v1

## 1. Executive Summary

Phase 13D-06 establishes Recallr''s **Relationship Memory Enrichment & Timeline Intelligence Pipeline**.
Building on top of Phase 13D-05 Entity Resolution, this layer consumes resolved persons and linked interactions to build chronological encounters, atomic memory claims, follow-up commitment candidates, and explainable relationship statistics on canonical Person Profiles (`users/{uid}/people/{personId}`).

---

## 2. End-to-End Pipeline Architecture

```text
                  User Omni-Capture Intake
                             │
                             ▼
                    Media Storage Upload
                 (Firebase Storage Bucket)
                             │
                             ▼
                    Capture Ingestion
                (users/{uid}/captures/{id})
                             │
                             ▼
                  OCR / Document Intake
               (Google ML Kit / Mock OCR)
                             │
                             ▼
                    Entity Extraction
              (Regex & Heuristic Extractor)
                             │
                             ▼
                    Entity Resolution
             (Deterministic Signal Matcher)
                             │
            ┌────────────────┴────────────────┐
            ▼                                 ▼
   Existing Person Match              New Person Created
   (Safe Field Enrichment)        (users/{uid}/people/{id})
            │                                 │
            └────────────────┬────────────────┘
                             │
                             ▼
                  Activity Relationship Link
                 (users/{uid}/activities/{id})
                             │
                             ▼
              Relationship Memory Enrichment
     ┌─────────────────────────────────────────────────┐
     │ 1. Idempotent Timeline Item (tl_cap_{id})       │
     │ 2. Structured Memories (mem_cap_{id}_*)         │
     │ 3. Follow-up Detection (fu_cap_{id})            │
     │ 4. Total Interactions & Last Interaction Date   │
     │ 5. Deterministic Relationship Strength Score    │
     └─────────────────────────────────────────────────┘
                             │
                             ▼
               Firestore Person Dossier Write
                (users/{uid}/people/{personId})
```

---

## 3. Core Principles & System Invariants

### 1. Provider-Agnostic & Zero-LLM Determinism
All timeline generation, memory extraction, follow-up detection, and score calculations operate deterministically without external AI APIs or hallucinations.

### 2. Idempotency & Duplicate Prevention
- Timeline entries use deterministic IDs (`tl_cap_${capture.id}`). Re-running processing on the same capture never produces duplicate timeline entries.
- Memory claims deduplicate on unique claim ID (`mem_cap_${capture.id}_*`) and exact text matching.
- Follow-ups use deterministic ID (`fu_cap_${capture.id}`).
- Total interactions counter only increments for unrecorded interaction IDs.

### 3. Non-Destructive Fail-Soft Isolation
- If relationship memory enrichment fails, the Capture, Storage media, Person record, and Activity record **remain completely intact and saved**.
- Retrying re-executes on the existing entity IDs safely.

### 4. Multi-Tenant Security & Authenticated Scoping
- All Firestore writes strictly scope to `users/{uid}/people/{personId}` and `users/{uid}/follow_ups/{followUpId}`.
- Authenticated UID is resolved internally via `FirebaseAuth.instance.currentUser.uid`.
- Fail-closed security throws `RecallrDataException.unauthenticated()` if user is logged out.

---

## 4. Relationship Strength Scoring Contract

| Interaction Range | Tier Name | Description |
|---|---|---|
| **1 Interaction** | `Emerging Connection` | Single captured interaction or card scan |
| **2 – 3 Interactions** | `Active Collaborator` | Multiple recent encounters or follow-ups |
| **4 – 6 Interactions** | `Strong Connection` | Established cadence across meetings/topics |
| **≥ 7 Interactions** | `Core Network / High Trust` | Deep collaborative history with shared context |

---

## 5. Verification & Test Suite

- `flutter analyze`: **0 warnings, 0 errors**.
- `flutter test`: **314 / 314 tests passing (100%)**.
  - `test/relationship_memory_test.dart` (30 new domain, service, enrichment, commitment detection, and pipeline tests).