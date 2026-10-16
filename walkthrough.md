# Phase 13H-03 Verification Walkthrough: Relationship Attention Intelligence & Command Center Prioritization

---

## 1. Overview & Objective

Phase 13H-03 establishes Recallr's **Relationship Attention Intelligence Engine**, building on top of the verified 13H-01 Relationship Intelligence Foundation and 13H-02 Proactive Relationship Actions Engine.

The engine answers the core user question:
> **"Who in my professional network needs my attention right now, and why?"**

It transforms raw relationship signals and proactive actions into a **deterministic, explainable, prioritized attention layer** that drives the Home Command Center and Person Dossiers without introducing secondary databases, mock data, or LLM hallucinations.

---

## 2. Key Architectural Deliverables

### A. Domain Models (`lib/features/relationship_intelligence/models/relationship_attention.dart`)
- **`RelationshipAttentionPriority`**: `critical` (Rank 4, Alert Crimson `#EF4444`), `high` (Rank 3, Warm Amber `#F59E0B`), `medium` (Rank 2, AI Cyan `#06B6D4`), `low` (Rank 1, Muted Secondary `#A1A1AA`).
- **`RelationshipAttentionReason`**: Structured grounded reason with unique code, human-readable title, narrative description referencing authentic facts, and relative weight.
- **`RelationshipAttention`**: Canonical immutable entity with bounded attention scores ($0.0 \dots 100.0$), NaN/Infinity safety, stable deduplication key (`attention_${personId}_${priority.name}_${primaryReasonCode}`), copyWith, and JSON serialization.

### B. Deterministic Calculation & Ranking Services
- **`RelationshipAttentionCalculator`** (`lib/services/relationship/relationship_attention_calculator.dart`):
  $$	ext{Score} = (0.30 	imes 	ext{Urgency} + 0.25 	imes 	ext{StateRisk} + 0.20 	imes 	ext{RecencyRisk} + 0.15 	imes 	ext{StrengthNorm} + 0.10 	imes 	ext{ContextNorm}) 	imes 100.0$$
- **`RelationshipAttentionPriorityCalculator`** (`lib/services/relationship/relationship_attention_priority_calculator.dart`):
  Precedence-ordered classifier ensuring strong contacts in jeopardy escalate to `CRITICAL` or `HIGH`, while strong relationships with zero risk never escalate to `CRITICAL`.
- **`RelationshipAttentionExplanation`** (`lib/services/relationship/relationship_attention_explanation.dart`):
  Pure static generator that produces grounded descriptions with real person names, company, lapse days, and overdue counts.
- **`RelationshipAttentionEngine`** (`lib/services/relationship/relationship_attention_engine.dart`):
  Provides sync/stream attention derivations, enforces **single-item-per-person deduplication**, sources primary actions from Phase 13H-02, and sorts deterministically:
  $$	ext{priority.rank DESC} ightarrow 	ext{attentionScore DESC} ightarrow 	ext{strength.score DESC} ightarrow 	ext{personName ASC} ightarrow 	ext{personId ASC}$$

### C. DI Wiring (`lib/core/di/recallr_dependencies.dart`)
- Registered `RelationshipAttentionCalculator`, `RelationshipAttentionPriorityCalculator`, and `RelationshipAttentionEngine` across production and mock factories.
- Added `BuildContext` extension getters (`context.relationshipAttentionEngine`, etc.).

### D. UI Componentry
- **`RelationshipAttentionCard`** (`lib/features/relationship_intelligence/widgets/relationship_attention_card.dart`):
  Polished, responsive card with name, company, priority badge, grounded explanation, state dot, recommended timing chip, and action buttons (`[ View Person ]` and `[ Create Follow-up ]`).
- **`RelationshipAttentionSection`** (`lib/features/home/widgets/relationship_attention_section.dart`):
  Home Command Center widget streaming top 3 prioritized attention items, collapsing to `SizedBox.shrink()` on empty accounts.
- **`HomeScreen`** (`lib/screens/home/home_screen.dart`):
  Wired to live `rankAttentionSync` pipeline over authenticated contacts stream.
- **`RelationshipIntelligence`** (`lib/features/person_detail/widgets/relationship_intelligence.dart`):
  Added "WHY THIS NEEDS ATTENTION" card to Person Dossier.

---

## 3. Test Suite Verification (723 / 723 Passed)

### Phase 13H-03 Dedicated Test Suite (`test/relationship_attention_intelligence_test.dart`):
- **Group 1: Attention Score Calculation & Bounds (20 Tests)** $ightarrow$ **PASS (100%)**
  - Verified empty, new, active, strong, cooling, neglected, dormant contacts, recency risk, overdue urgency, NaN/Infinity safety, 0..100 boundary clamping, and determinism.
- **Group 2: Priority & Precedence (10 Tests)** $ightarrow$ **PASS (100%)**
  - Verified Critical, High, Medium, Low thresholds, critical precedence outranking score, overdue + strong relationship escalation, and healthy relationship safeguard.
- **Group 3: Explainability & Grounded Copy (10 Tests)** $ightarrow$ **PASS (100%)**
  - Verified real person names, companies, exact lapse days, overdue counts, zero hallucinations, zero emotional assumptions, and deterministic timing mappings.
- **Group 4: Ranking & Deduplication (8 Tests)** $ightarrow$ **PASS (100%)**
  - Verified 5-tier tie-breaking hierarchy, duplicate contact collapse into single item, and reproducible ordering.
- **Group 5: Security & Multi-Tenant Isolation (5 Tests)** $ightarrow$ **PASS (100%)**
  - Verified unauthenticated fail-closed empty return, User A vs User B strict isolation, and zero secret/token leakage in serialization.
- **Group 6: UI Widgets & Integration (7 Tests)** $ightarrow$ **PASS (100%)**
  - Verified Home attention section rendering, empty account hidden state, priority badge styling, explanation text, and CTA tap callbacks.

### Full Regression Suite:
- `test/relationship_action_intelligence_test.dart` (50 tests) $ightarrow$ **PASS (100%)**
- `test/relationship_intelligence_test.dart` (50 tests) $ightarrow$ **PASS (100%)**
- `test/home_screen_test.dart` & `test/person_detail_screen_test.dart` (31 tests) $ightarrow$ **PASS (100%)**
- Full test runner across entire workspace $ightarrow$ **723 / 723 Tests Passed (100%)**
- `flutter analyze` $ightarrow$ **0 Issues Found!**
