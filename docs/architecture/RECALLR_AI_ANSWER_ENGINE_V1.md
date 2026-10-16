# Recallr AI Answer Generation & Grounded Personal Memory Q&A Engine v1

## 1. Architectural Overview

The **AI Answer Generation Engine** transforms raw multi-source personal memory retrieval into strictly grounded, trustworthy answers with explicit citations, confidence scores, and navigation routes.

```text
┌────────────────────────────────────────────────────────────────────────┐
│                          User Question Prompt                          │
│                "What did I discuss with Priya about RISC-V?"           │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   Phase 13E-01: Retrieval Foundation                   │
│   MemoryQueryClassifier → Multi-Source Firestore → ContextAssembler    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                              MemoryContext
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                 Phase 13E-02: Answer Grounding Service                 │
│      - Deduplicates evidence across 4 collections                      │
│      - Assigns canonical deep links (/person/:id, /interaction/:id)    │
│      - Computes normalized confidence score [0.0, 1.0]                 │
│      - Extracts mentioned people & actionable follow-up next steps     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                           AiAnswerEvidence List
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                     AiAnswerGenerator Abstraction                      │
│        (DeterministicAiAnswerGenerator / Future Gemini Provider)       │
│      - Multi-intent synthesis without hallucinations                   │
│      - Person, Company, Interaction, Memory, Follow-up, Overview       │
│      - Explicit uncertainty response on empty/insufficient context     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                 AiAnswer
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                       AskScreen UI Integration                         │
│  GroundedAnswerCard · MemorySourcesSection · PeopleMentions · Badges   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Canonical Domain Models

All answer domain models reside in `lib/features/ask/models/ai_answer_models.dart`:

| Model / Enum | Role & Responsibilities |
|---|---|
| `AiAnswerStatus` | Lifecycle states: `idle`, `generating`, `completed`, `empty`, `failed` |
| `AiAnswerEvidence` | Grounded source citation with `sourceType`, `sourceId`, `title`, `content`, `timestamp`, `relevanceScore`, `matchReason`, `targetRoute` |
| `AiAnswerTurn` | Multi-turn conversational question-answer-evidence snapshot |
| `AiAnswerRequest` | Answer synthesis request carrying `query`, `conversationHistory`, `targetPersonId`, `maxEvidence` |
| `AiAnswerConfiguration`| Operational limits: `maxEvidenceItems: 15`, `maxContextChars: 8000`, `minConfidenceThreshold: 0.40` |
| `AiAnswer` | Complete grounded answer output with `answer`, `status`, `intent`, `confidence`, `evidence`, `mentionedPeople`, `suggestedActions` |

---

## 3. Grounding & Anti-Hallucination Invariants

The engine strictly enforces 5 core anti-hallucination rules:

1. **Rule 1 (Zero Invention):** Answers must never invent facts, names, dates, or promises not traceable to `MemoryContext`.
2. **Rule 2 (Evidence Traceability):** Every synthesized claim is mapped directly to an `AiAnswerEvidence` item with deep link routes.
3. **Rule 3 (Explicit Uncertainty):** If context is empty or ungrounded, the engine returns:
   > *"I don't have enough information in your Recallr memory to answer that confidently."*
4. **Rule 4 (Empty State Status):** Ungrounded answers yield `AiAnswerStatus.empty` with `confidence: 0.0`.
5. **Rule 5 (Normalized Scoring):** Confidence is strictly calculated between `0.0` and `1.0` based on candidate relevance scores and context depth.

---

## 4. Multi-Intent Deterministic Synthesizer

The `DeterministicAiAnswerGenerator` handles all query intents deterministically:

- **Person Lookup:** Synthesizes role, company, location, and key capabilities.
- **Company Lookup:** Lists known colleagues and their respective roles.
- **Interaction Lookup:** Synthesizes meeting date, title, and key notes.
- **Memory Lookup:** Surfaces specific preference and fact claims.
- **Follow-up Lookup:** Surfaces upcoming commitments and due dates.
- **Recent Interaction:** Lists chronological recent encounters.
- **Relationship Overview:** Delivers a 360-degree briefing including relationship strength and total interactions.
- **General Search:** Highlights top relevance matches.

---

## 5. Security & Authentication Isolation

All personal memory retrieval and answer generation strictly enforce tenant isolation:
- Scoped to `users/{FirebaseAuth.currentUser.uid}/*`.
- Fails closed with `RecallrDataException.unauthenticated()` if no user session is active.
- Zero client-supplied UID parameters.

---

## 6. Verification & Quality Metrics

- **Analyzer Status:** Zero issues (`flutter analyze` $\rightarrow$ clean).
- **Test Suite Status:** 374 / 374 tests passing across 22 test files (100% pass rate).
- **Phase 13E-02 Test Suite:** 30 comprehensive unit, generator, grounding, service pipeline, and widget integration tests in `test/ai_answer_generation_test.dart`.