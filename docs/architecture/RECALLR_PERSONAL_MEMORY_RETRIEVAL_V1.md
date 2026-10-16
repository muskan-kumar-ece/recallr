# Recallr Architecture Specification: Personal Memory Retrieval & Context Assembly (Phase 13E-01)

## 1. Overview & Objectives

Phase 13E-01 establishes the foundational **Personal Memory Retrieval & Context Assembly Engine** for Recallr.
It sits between Recallr’s accumulated multi-source relationship memory stores in Firestore and future grounded AI reasoning capabilities.

```text
                                User Natural Query
                                        │
                                        ▼
                            Memory Query Classifier
                 (Intent, Entity, & Temporal Extraction)
                                        │
                                        ▼
                                   MemoryQuery
                                        │
                     ┌──────────────────┴──────────────────┐
                     ▼                                     ▼
        Targeted Person Lookup                   Multi-Source Store Search
   (RelationshipContextAssembler)             (MemoryRetrievalRepository)
                     │                                     │
                     │                 ┌───────────────────┼───────────────────┐
                     │                 ▼                   ▼                   ▼
                     │            users/people       users/activities    users/captures
                     │                 │                   │                   │
                     │                 └───────────────────┼───────────────────┘
                     │                                     ▼
                     │                           Candidate MemoryEvidence
                     │                                     │
                     │                                     ▼
                     │                           MemoryRelevanceRanker
                     │                     (Deterministic Scoring & Deduplication)
                     │                                     │
                     └──────────────────┬──────────────────┘
                                        │
                                        ▼
                                  MemoryContext
                  (Budgeted Evidence with Provenance & Truncation Meta)
                                        │
                                        ▼
                               MemorySearchResult
                                        │
                                        ▼
                        [Future AI Reasoning Engine]
```

---

## 2. Domain Models (`lib/features/ask/models/memory_retrieval_models.dart`)

### `MemorySourceType`
Categorizes the canonical origin of evidence:
* `person`: Canonical person profile metadata (`users/{uid}/people/{personId}`).
* `activity`: Chronological interaction encounter (`users/{uid}/activities/{activityId}`).
* `capture`: Omni-Capture media intake and extracted OCR text (`users/{uid}/captures/{captureId}`).
* `memory`: Atomic structured memory claim (`memories` sub-array in profile).
* `followUp`: Actionable commitment or promise (`users/{uid}/follow_ups/{followUpId}`).
* `timeline`: Chronological interaction timeline item (`timeline` sub-array in profile).

### `MemoryQueryIntent`
Deterministic query intent classification:
* `personLookup`: Profile, role, capabilities, and contact retrieval.
* `companyLookup`: Cross-person team and organization context.
* `interactionLookup`: Meeting notes and discussion topics.
* `memoryLookup`: Facts and atomic claims.
* `followUpLookup`: Commitments, promises, and deliverables.
* `projectLookup`: Topic and project-specific notes.
* `recentInteraction`: Temporal recency query (*"Who did I meet recently?"*).
* `relationshipOverview`: Complete 360-degree briefing.
* `generalSearch`: Multi-store keyword fallback.

### `MemoryEvidence`
Traceable evidence unit preserving complete source provenance:
```dart
class MemoryEvidence {
  final String id;
  final MemorySourceType sourceType;
  final String sourceId;
  final String? personId;
  final String? personName;
  final String? captureId;
  final String? activityId;
  final String? timestamp;
  final String content;
  final double relevanceScore; // 0.0 to 1.0
  final String matchReason;
  final Map<String, dynamic>? metadata;
}
```

### `MemoryContext`
AI-ready aggregated context with context budgeting and truncation tracking:
```dart
class MemoryContext {
  final MemoryQuery query;
  final PersonItem? targetPerson;
  final PersonProfile? targetProfile;
  final List<MemoryEvidence> evidenceItems;
  final bool wasTruncated;
  final int originalCount;
  final int returnedCount;
  final DateTime assembledAt;
}
```

---

## 3. Core Engine Components

### A. `MemoryQueryClassifier` (`lib/services/retrieval/memory_query_classifier.dart`)
* Parses raw user queries deterministically with zero LLM dependence.
* Extracts named entities (`targetPersonName`, `targetCompanyName`, `targetTopic`).
* Extracts temporal constraints (`today`, `yesterday`, `this week`, `last week`, `recently`, `latest`).
* Selects deterministic `MemoryQueryIntent`.

### B. `MemoryRelevanceRanker` (`lib/services/retrieval/memory_relevance_ranker.dart`)
* Evaluates candidate evidence against target entities, query tokens, intent alignment, and temporal recency.
* Normalizes scores into a stable `[0.0, 1.0]` range.
* Deduplicates items by evidence ID.
* Sorts descending by relevance score.

### C. `RelationshipContextAssembler` (`lib/services/retrieval/relationship_context_assembler.dart`)
* Synthesizes profile headers, chronological timeline events, memory claims, and pending commitments into a unified evidence graph.
* Enforces maximum result budgeting without silent data drops.

### D. `MemoryRetrievalRepository` & `FirestoreMemoryRetrievalRepository`
* Scoped strictly to `users/{uid}/*` collections.
* Resolves `FirebaseAuth.currentUser.uid` internally without UI parameters.
* Fails closed with `RecallrDataException.unauthenticated()` when logged out.

### E. `DeterministicMemoryRetrievalService`
* Orchestrates classification, multi-source retrieval, context assembly, and relevance scoring into a high-level API.

---

## 4. Verification & Testing

* **Unit & Integration Suite**: `test/memory_retrieval_test.dart` (30 tests).
* **Static Analysis**: `flutter analyze` $\rightarrow$ **0 warnings, 0 errors**.
* **Regression Test Suite**: `flutter test` $\rightarrow$ **344 / 344 tests passing (100%)** across 21 test files.