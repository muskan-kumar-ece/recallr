# RECALLR RELATIONSHIP ATTENTION INTELLIGENCE ARCHITECTURE V1
**Phase 13H-03 Implementation Specification & Architecture Reference**

---

## 1. Executive Summary & Core Objective

The **Relationship Attention Intelligence Engine** answers one central question for the Recallr user:

> **"Who in my professional network needs my attention right now, and why?"**

It builds on top of:
- **Phase 13H-01**: Relationship Intelligence Foundation (Signals, Strength 0–100, States: *New, Active, Strong, Cooling, Neglected, Dormant*).
- **Phase 13H-02**: Proactive Relationship Actions Engine (Deterministic next steps: *Complete Overdue Follow-up, Reconnect, Review Interaction, Capture Missing Context, Review Relationship*).

Phase 13H-03 transforms deterministic relationship signals and proactive actions into a **globally prioritized, explainable attention layer** that drives the **Home Command Center** and prepares Recallr for future notification and reminder intelligence without introducing any mock data, secondary databases, or LLM hallucinations.

```text
REAL FIRESTORE (users/{uid}/*)
      ↓
13H-01 Relationship Intelligence
      │
      ├── Signals (Recency, Frequency, Depth, Memories, Follow-ups)
      ├── Strength 0–100
      └── State (New, Active, Strong, Cooling, Neglected, Dormant)
             ↓
13H-02 Proactive Relationship Actions
      │
      ├── Primary Next Step (e.g., Reconnect, Complete Overdue Follow-up)
      ├── Priority (Urgent, High, Medium, Low)
      └── Action Handoff
             ↓
13H-03 Relationship Attention Intelligence
      │
      ├── Who needs attention? (Deduplicated contact list)
      ├── Attention Score 0–100 (Urgency, State Decay, Recency, Strength, Context)
      ├── Grounded Reason ("Why?") (Real contact name, interaction dates, overdue counts)
      ├── Priority Tier (CRITICAL > HIGH > MEDIUM > LOW)
      └── Recommended Timing ("Today", "Within 2–3 days", "This week", "Soon")
             ↓
      ┌─────────────────────────────┐
      ↓                             ↓
HOME COMMAND CENTER         PERSON DOSSIER
(Prioritized Feed)          ("Why this needs attention" Card)
```

---

## 2. Architectural Invariants & Guardrails

1. **Relationship Strength ≠ Attention Score**:
   - Relationship Strength measures historical depth, recency, and connection quality ($0.0 \dots 100.0$).
   - Attention Score measures current need for proactive engagement ($0.0 \dots 100.0$).
   - *Example*: A strong contact (Strength: 92) with an overdue commitment has high attention (Attention: 88). A strong contact with recent contact and no pending tasks has low attention (Attention: 22).
2. **Derived View (No Secondary Database)**:
   - Attention is computed on-the-fly from live Firestore streams. No `relationship_attention` collection or writes are created simply to evaluate attention.
   - Fail-closed security boundary: If unauthenticated or no contacts exist, attention returns empty list (`[]`), never demo cards.
3. **Deterministic & Grounded (No LLM in the Critical Loop)**:
   - All attention scores, priorities, and reasons are 100% deterministic, transparent, and mathematical.
   - Explanations strictly reference authentic dates, person names, companies, interaction counts, and follow-up states. Zero hallucinations or fabricated future intents.
4. **Single-Item-Per-Person Deduplication**:
   - Each contact appears at most **once** in the final attention rankings, paired with their highest-priority reason and primary action.
5. **Multi-Tenant User Isolation**:
   - `FirebaseAuth.instance.currentUser.uid` remains authoritative. Attention calculations never cross user account boundaries or serialize private tokens.

---

## 3. Attention Score Mathematical Formula

Attention score is a bounded floating-point value $\in [0.0, 100.0]$ computed from 5 weighted components:

$$	ext{Attention Score} = \left( 0.30 \cdot U + 0.25 \cdot S_{	ext{risk}} + 0.20 \cdot R + 0.15 \cdot K + 0.10 \cdot C ight) 	imes 100.0$$

### Component Breakdown

| Component | Weight | Input Signal / Metric | Normalized Range ($0.0 \dots 1.0$) |
| :--- | :--- | :--- | :--- |
| **Urgency Risk ($U$)** | **30%** | Overdue & active follow-ups | $\ge 2$ overdue: $1.0$<br>$1$ overdue: $0.70$<br>$\ge 1$ active: $0.35$<br>None: $0.0$ |
| **Relationship State Risk ($S_{	ext{risk}}$)** | **25%** | Relationship lifecycle state | `neglected`: $1.0$<br>`dormant`: $0.80$<br>`cooling`: $0.65$<br>`active`: $0.25$<br>`strong`: $0.15$<br>`newRelationship`: $0.10$ |
| **Recency Risk ($R$)** | **20%** | Days since last interaction | $>180	ext{d}$: $1.0$<br>$91–180	ext{d}$: $0.85$<br>$61–90	ext{d}$: $0.65$<br>$31–60	ext{d}$: $0.45$<br>$8–30	ext{d}$: $0.20$<br>$\le 7	ext{d}$: $0.0$ |
| **Relationship Importance ($K$)** | **15%** | Relationship strength score | $rac{	ext{strength.score}}{100.0}$ (higher value relationships risk greater loss from neglect) |
| **Context Richness ($C$)** | **10%** | Total interactions & memories | $\min\left(1.0, rac{	ext{interactions} + 	ext{memories}}{10.0}ight)$ |

---

## 4. Priority Precedence & Classification Rules

Priorities are evaluated using strict precedence logic to guarantee that high-value relationships in jeopardy are prioritized over routine maintenance:

```text
CRITICAL (Rank 4)
  ├── Attention Score >= 85.0 AND (hasOverdueFollowUp OR state == neglected)
  └── Overdue follow-up count >= 2 on active/strong contact
  
HIGH (Rank 3)
  ├── Attention Score >= 70.0
  ├── hasOverdueFollowUp == true
  ├── state == neglected AND (interactionCount >= 2 OR memoryCount >= 1)
  └── state == cooling AND interactionCount >= 2
  
MEDIUM (Rank 2)
  ├── Attention Score >= 40.0
  ├── state == cooling
  ├── activeFollowUpCount > 0
  └── interactionCount >= 2
  
LOW (Rank 1)
  └── Attention Score < 40.0 (Routine maintenance & new contacts)
```

> **Invariant**: A strong, healthy relationship with recent interaction and no overdue follow-ups will **never** escalate to `CRITICAL` or `HIGH` priority, preserving user focus for genuine relationship risks.

---

## 5. Grounded Explainability & Timing Engine

The `RelationshipAttentionExplanation` module produces human-readable, grounded context without generative hallucinations:

```dart
// Examples of Grounded Attention Reasons:
- 'Overdue Commitment': 'You have 2 overdue follow-ups with Sarah Chen.'
- 'Cooling Relationship': 'Your connection with David Kim is cooling. Last interaction was 48 days ago.'
- 'Neglected Connection': 'Meaningful relationship with 8 interactions has had no contact for 120 days.'
- 'Context Gap': 'You have 4 interactions with Elena, but no captured context notes.'
```

### Recommended Timing Rules
- `CRITICAL`: **"Today"**
- `HIGH`: **"Within 2–3 days"** (or **"This week"** for cooling contacts)
- `MEDIUM`: **"This week"**
- `LOW`: **"Soon"**

---

## 6. Deterministic Tie-Breaking & Deduplication Hierarchy

When multiple contacts qualify for relationship attention, the ranking engine orders them deterministically using a 5-tier comparator:

```text
1. priority.rank DESC           (CRITICAL > HIGH > MEDIUM > LOW)
2. attentionScore DESC          (e.g., 88.5 > 74.0)
3. relationshipStrength.score DESC (e.g., 90.0 > 65.0)
4. personName ASC               (e.g., "Alice" < "Bob")
5. personId ASC                 (Stable unique identifier)
```

---

## 7. UI Integration & Visual System

### 1. Home Command Center (`RelationshipAttentionSection`)
- Displays the **Top 3** prioritized attention items directly above Recent Memories.
- Renders `RelationshipAttentionCard` with:
  - Person name & company badge.
  - Priority badge (`CRITICAL` Crimson `#EF4444`, `HIGH` Amber `#F59E0B`, `MEDIUM` AI Cyan `#06B6D4`, `LOW` Muted `#A1A1AA`).
  - Grounded reason title and narrative description.
  - Lifecycle state dot & Recommended Timing chip (`Today`, `Within 2–3 days`, `This week`).
  - Action buttons: `[ View Person ]` $ightarrow$ navigates to Dossier; `[ Create Follow-up ]` or `[ Complete Follow-up ]` $ightarrow$ navigates to Follow-up flow.
- Automatically collapses to `SizedBox.shrink()` on empty accounts.

### 2. Person Dossier (`RelationshipIntelligence` Widget)
- Adds a **"WHY THIS NEEDS ATTENTION"** card at the top of the dossier when attention signals are present.
- Highlights priority, reason explanations, and recommended timeframe.

---

## 8. Test Suite Verification Summary (60 Tests)

The entire Phase 13H-03 engine is covered by 60 unit, integration, and widget tests in `test/relationship_attention_intelligence_test.dart`:

| Group | Description | Test Count | Status |
| :--- | :--- | :--- | :--- |
| **Group 1** | Score Calculation & Boundary Verifications (0..100 bounds, NaN/Inf safety, formulas) | 20 | **PASS (100%)** |
| **Group 2** | Priority & Precedence (Critical, High, Medium, Low, precedence rules) | 10 | **PASS (100%)** |
| **Group 3** | Explainability & Grounded Copy (Real names, dates, overdue counts, zero hallucinations) | 10 | **PASS (100%)** |
| **Group 4** | Ranking & Deduplication (5-tier tie-breaking, single item per person, determinism) | 8 | **PASS (100%)** |
| **Group 5** | Security & Multi-Tenant Isolation (Fail-closed empty state, User isolation, serialization) | 5 | **PASS (100%)** |
| **Group 6** | UI Widgets & Integration (Home section, Person dossier, priority badges, CTA taps) | 7 | **PASS (100%)** |
| **Total** | **Comprehensive Attention Intelligence Suite** | **60** | **PASS (100%)** |

---

## 9. Deliverables & File Index

| File Path | Role / Content |
| :--- | :--- |
| `lib/features/relationship_intelligence/models/relationship_attention.dart` | Domain models (`RelationshipAttention`, `RelationshipAttentionPriority`, `RelationshipAttentionReason`). |
| `lib/features/relationship_intelligence/models/models.dart` | Barrel export. |
| `lib/services/relationship/relationship_attention_calculator.dart` | Weighted 0..100 mathematical score calculator. |
| `lib/services/relationship/relationship_attention_priority_calculator.dart` | Precedence-ordered priority classifier. |
| `lib/services/relationship/relationship_attention_explanation.dart` | Pure static grounded reason and timing generator. |
| `lib/services/relationship/relationship_attention_engine.dart` | Unified ranking, deduplication, and pipeline engine. |
| `lib/core/di/recallr_dependencies.dart` | DI container registration for attention services. |
| `lib/features/relationship_intelligence/widgets/relationship_attention_card.dart` | Reusable attention card widget with responsive layouts. |
| `lib/features/home/widgets/relationship_attention_section.dart` | Home Command Center section widget. |
| `lib/screens/home/home_screen.dart` | Streaming attention integration into Home screen. |
| `lib/features/person_detail/widgets/relationship_intelligence.dart` | "WHY THIS NEEDS ATTENTION" card in Person Dossier. |
| `lib/screens/person/person_detail_screen.dart` | Person Detail attention integration. |
| `test/relationship_attention_intelligence_test.dart` | 60 comprehensive unit and widget tests. |
