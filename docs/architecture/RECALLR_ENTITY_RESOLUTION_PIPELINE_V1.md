# Architecture Specification: Capture → People & Relationship Entity Resolution (Phase 13D-05)

## 1. Overview & Objective

Phase 13D-05 introduces Recallr's **Deterministic Identity Resolution & Relationship Memory Pipeline**.
When media (business cards, whiteboard photos, voice memos, documents, and quick notes) is ingested and OCR/entity extraction completes, the identity resolution layer deterministically resolves the detected individuals against canonical People (`users/{uid}/people`), enriches existing profiles safely, creates new person records when appropriate, links chronological Activity records (`users/{uid}/activities`), and persists all resolution metadata on the capture item (`users/{uid}/captures/{captureId}`).

```text
                  User Ingests Media
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
                     OcrService
             (Google ML Kit / Mock OCR)
                          │
                          ▼
                 OcrEntityExtractor
     (Deterministic Pattern & Heuristic Extractor)
                          │
                          ▼
               EntityResolutionService
     ┌───────────────────────────────────────────┐
     │ 1. Explicit personId on Capture           │
     │ 2. Exact Normalized Email Match           │
     │ 3. Exact Normalized Phone Match           │
     │ 4. Strong Name + Company Match            │
     │ 5. Contextual Name Match (Unique)         │
     │ 6. Multiple Candidates -> requiresReview  │
     │ 7. No Match -> Create New Canonical Person│
     └───────────────────────────────────────────┘
                          │
                          ├──> Enrich Existing Person (Safe field merges)
                          ├──> Create Chronological Activity (users/{uid}/activities)
                          └──> Update Capture Record (users/{uid}/captures/{id})
```

---

## 2. Multi-Signal Deterministic Precedence

Identity matching evaluates signals in descending order of certainty:

| Priority | Match Type | Signal Tested | Confidence | Behavior |
|---|---|---|---|---|
| **1** | `explicitId` | Capture already has `personId` | `1.0` | Match existing; enrich missing fields |
| **2** | `exactEmail` | Case-insensitive email exact match | `0.99` | Match existing; enrich missing fields |
| **3** | `exactPhone` | Normalized digit-only phone match | `0.96` | Match existing; enrich missing fields |
| **4** | `strongNameCompany` | Normalized Name + Company matches 1 person | `0.93` | Match existing; enrich missing fields |
| **4b** | `ambiguous` | Name + Company matches >1 person | `0.65` | **Never merge**; set `requiresReview: true` |
| **5** | `contextualName` | Normalized Name matches exactly 1 person | `0.85` | Match existing; enrich missing fields |
| **5b** | `ambiguous` | Normalized Name matches >1 person | `0.50` | **Never merge**; set `requiresReview: true` |
| **6** | `none` | No matching candidate found; Name present | `0.90` | Create new canonical `PersonItem` |
| **7** | `skipped` | No name or identity signal detected | `0.0` | Skip person resolution; complete processing |

---

## 3. Person Safe Enrichment & Conflict Rules

When an existing person is matched:
1. **Verified Field Protection**: Never blindly overwrite non-empty existing data (`role`, `company`, `email`, `phone`).
2. **Missing Value Ingestion**: If existing person lacks a field (e.g. `email == null`) and incoming capture has it, the field is populated.
3. **Conflict Detection**: If incoming capture has a differing company or email, an `EntityConflict` record is generated with existing vs incoming values for user review without corrupting the profile.
4. **Interaction Timestamp**: Updates `lastInteraction` and `lastInteractionDate` to reflect the latest encounter.
5. **Increment Interaction Count**: Atomically increments `interactionCount`.

---

## 4. Chronological Activity Linking

If enabled (`autoLinkActivity: true`), an `ActivityItem` is created in `users/{uid}/activities`:
- **Deterministic ID**: `act_cap_${capture.id}` ensures idempotent retries without duplicate entries.
- **Linked Person**: Attaches `personId`, `personName`, `companyName`, and target route `/person/${person.id}`.
- **Activity Type Mapping**:
  - `CaptureType.businessCard` $\rightarrow$ `ActivityType.capture`
  - `CaptureType.voice` $\rightarrow$ `ActivityType.call`
  - `CaptureType.note` $\rightarrow$ `ActivityType.note`
  - `CaptureType.photo` $\rightarrow$ `ActivityType.encounter`
  - `CaptureType.document` $\rightarrow$ `ActivityType.file`

---

## 5. Security & Multi-Tenant Isolation

- **Authoritative Resolution**: All Firestore calls (`FirestorePeopleRepository`, `FirestoreActivityRepository`, `FirestoreCaptureProcessingRepository`) resolve `FirebaseAuth.instance.currentUser?.uid` internally.
- **Fail-Closed Unauthenticated**: If unauthenticated, all queries immediately throw `RecallrDataException.unauthenticated()`.
- **Strict User Scoping**:
  - `users/{uid}/people/{personId}`
  - `users/{uid}/activities/{activityId}`
  - `users/{uid}/captures/{captureId}`

---

## 6. Verification Metrics

- **Static Analysis**: `flutter analyze` $\rightarrow$ **0 issues**.
- **Automated Tests**: `flutter test` $\rightarrow$ **284 / 284 tests passing (100%)**.