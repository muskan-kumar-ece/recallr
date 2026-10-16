# Recallr Architecture: Relationship Intelligence Engine v1

## Document Metadata
- **Author**: Staff Frontend Engineer & AI SaaS Design Architect
- **Status**: Production Verified
- **Phase**: Phase 13H-01 (Relationship Intelligence Foundation)
- **Target App**: Recallr Flutter Client (iOS / Android / Web)
- **Primary Contracts**:
  - `lib/features/relationship_intelligence/models/`
  - `lib/services/relationship/`
  - `lib/core/di/recallr_dependencies.dart`
  - `lib/features/person_detail/widgets/relationship_intelligence.dart`

---

## 1. Executive Summary & Core Principles

Recallr's **Relationship Intelligence Engine** provides deterministic, transparent, and explainable relationship signals, strength scoring, and lifecycle state classification.

### Fundamental Principle: Single Source of Truth
```text
Firebase Auth
      ↓
Real Firestore (users/{uid}/*)
      ↓
Authoritative Production Repositories (People, Activities, FollowUps, Captures, PersonDetail)
      ↓
Deterministic Relationship Intelligence Engine
      ↓
Signals Matrix → Strength Score (0..100) → Relationship State (6 Precedence Tiers)
      ↓
Person Dossier / Home / Ask Grounded Memory
```

- **Zero Secondary Persistent Storage**: Intelligence is computed deterministically from verified relationship records.
- **Zero Hallucination / Zero Gemini Dependency for Scoring**: Calculations are mathematical, bounded ($0.0 \dots 100.0$), and 100% reproducible.
- **Explainable by Design**: Every score factor and state transition generates human-readable provenance and rationale.
- **Strict Multi-Tenant Isolation**: Dynamically scoped to `FirebaseAuth.currentUser.uid`, failing closed if unauthenticated.

---

## 2. Relationship Signals Engine

The `RelationshipSignals` class aggregates raw Firestore records into structured quantitative metrics:

| Signal Name | Source Collection | Description | Type / Boundaries |
| :--- | :--- | :--- | :--- |
| `interactionCount` | `interactions`, `timeline` | Total historical encounters and touchpoints | `int` ($\ge 0$) |
| `recentInteractionDate` | `interactions`, `timeline` | Most recent meeting, call, note, or card scan date | `DateTime?` |
| `daysSinceLastInteraction` | `now.difference(recent)` | Days since latest interaction ($\ge 0$) | `int?` |
| `interactionFrequency` | `interactionCount / months` | Average monthly interactions over relationship age | `double` ($\ge 0.0$) |
| `relationshipAgeDays` | `now.difference(firstMet)` | Days elapsed since first meeting / earliest encounter | `int` ($\ge 0$) |
| `memoryCount` | `memories`, `claims` | Atomic facts, claims, and context remembered | `int` ($\ge 0$) |
| `captureCount` | `captures` | Business cards, voice notes, documents ingested | `int` ($\ge 0$) |
| `activeFollowUpCount` | `follow_ups` | Pending commitments due today or upcoming | `int` ($\ge 0$) |
| `overdueFollowUpCount` | `follow_ups` | Unfulfilled commitments past due date | `int` ($\ge 0$) |
| `completedFollowUpCount` | `follow_ups` | Completed / fulfilled commitments | `int` ($\ge 0$) |
| `recentInteractionCount` | `timeline` ($\le 30	ext{d}$) | Interactions occurring within the trailing 30 days | `int` ($\ge 0$) |

---

## 3. Deterministic Strength Calculator

Calculates a bounded score $S \in [0.0, 100.0]$ across 5 weighted dimensions:

$$	ext{Score} = 100 	imes \sum_{i=1}^{5} \left( w_i 	imes f_i(	ext{signals}) ight)$$

### 1. Recency ($w_1 = 30\%$)
- $\le 7$ days $ightarrow 1.0$ (Max recency contribution)
- $\le 30$ days $ightarrow 0.85$ (Recent interaction within past month)
- $\le 90$ days $ightarrow 0.55$ (Quarterly engagement)
- $\le 180$ days $ightarrow 0.25$ (Semi-annual engagement)
- $> 180$ days $ightarrow 0.05$ (Stale connection)
- Missing / never interacted $ightarrow 0.0$

### 2. Interaction Frequency ($w_2 = 25\%$)
- $\ge 8$ recent encounters or $\ge 4.0$ per month $ightarrow 1.0$
- $4 \dots 7$ encounters or $\ge 2.0$ per month $ightarrow 0.80$
- $2 \dots 3$ encounters or $\ge 1.0$ per month $ightarrow 0.55$
- $1$ encounter $ightarrow 0.25$
- $0$ encounters $ightarrow 0.0$

### 3. Interaction Depth ($w_3 = 20\%$)
- $\ge 10$ total lifetime interactions $ightarrow 1.0$
- $5 \dots 9$ interactions $ightarrow 0.80$
- $2 \dots 4$ interactions $ightarrow 0.50$
- $1$ interaction $ightarrow 0.30$
- $0$ interactions $ightarrow 0.0$

### 4. Memory Richness ($w_4 = 15\%$)
- $\ge 6$ claims + captures $ightarrow 1.0$
- $4 \dots 5$ items $ightarrow 0.75$
- $2 \dots 3$ items $ightarrow 0.55$
- $1$ item $ightarrow 0.40$
- $0$ items $ightarrow 0.0$

### 5. Follow-up Engagement ($w_5 = 10\%$)
- Overdue commitments present $ightarrow 0.20$ (Penalized)
- Active follow-ups in progress $ightarrow 0.85$
- Completed commitments present $ightarrow 1.0$
- Baseline (no commitments) $ightarrow 0.30$

---

## 4. State Classification Precedence Matrix

The `DeterministicRelationshipStateClassifier` evaluates 6 relationship lifecycle states in strict precedence:

```text
┌─────────────────────────────────────────────────────────────┐
│ 1. DORMANT (Precedence Rank 6)                             │
│    (Age > 180d || Count > 0) && (Days == null || Days > 180)│
└──────────────────────────────┬──────────────────────────────┘
                               │ (False)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. NEGLECTED (Precedence Rank 5)                           │
│    (Count >= 3 || Memories >= 2) && (Days > 60 || Overdue)  │
└──────────────────────────────┬──────────────────────────────┘
                               │ (False)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. COOLING (Precedence Rank 4)                             │
│    Count >= 2 && (Days >= 31 && Days <= 60)                 │
└──────────────────────────────┬──────────────────────────────┘
                               │ (False)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. STRONG (Precedence Rank 3)                              │
│    Score >= 70.0 && Count >= 4 && Days <= 30                │
└──────────────────────────────┬──────────────────────────────┘
                               │ (False)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. ACTIVE (Precedence Rank 2)                              │
│    Days <= 30 && Count >= 1                                 │
└──────────────────────────────┬──────────────────────────────┘
                               │ (False)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. NEW (Precedence Rank 1)                                 │
│    Default Fallback for recently created contacts           │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Person Dossier UI Integration

In `PersonDetailScreen`, the `RelationshipIntelligence` widget renders:
1. **Dynamic State Badge**: Distinctive visual badge with semantic coloring (`#10B981` Emerald for STRONG, `#06B6D4` Cyan for ACTIVE, `#F59E0B` Amber for COOLING, `#EF4444` Crimson for NEGLECTED, `#71717A` Muted for DORMANT, `#8B5CF6` Violet for NEW).
2. **Strength Indicator**: `/100` numeric rating and qualitative level description.
3. **Transparent Explainability Bullets**: 3 bulleted key drivers (e.g. `• Recent interaction 4 days ago`, `• 8 recorded interactions`, `• 5 remembered context details and captures`).
4. **Preserved Metric Tiles**: `First Met`, `Last Interaction`, `Interactions`, `Shared Events`.

---

## 6. Dependency Injection & Service Layer

Registered in `RecallrDependencies`:
- `relationshipStrengthCalculator`: `DeterministicRelationshipStrengthCalculator`
- `relationshipStateClassifier`: `DeterministicRelationshipStateClassifier`
- `relationshipIntelligenceService`: `DeterministicRelationshipIntelligenceService`

### Service Interface:
```dart
abstract class RelationshipIntelligenceService {
  Future<PersonRelationshipIntelligence> getIntelligence(String personId, {PersonProfile? profile, DateTime? referenceDate});
  Stream<PersonRelationshipIntelligence> streamIntelligence(String personId, {DateTime? referenceDate});
  Future<List<PersonRelationshipIntelligence>> getBulkIntelligence(List<String> personIds, {DateTime? referenceDate});
}
```

---

## 7. Test Coverage Matrix

Validated via `test/relationship_intelligence_test.dart` (50 / 50 passing tests, 613 / 613 full suite pass):

1. **Signals (Tests 1–14)**: Zero interactions, single interaction, multiple timeline items, recency detection, age calculation, memory counts, capture counts, active/overdue/completed follow-ups, invalid timestamps, date deduplication.
2. **Recency (Tests 15–21)**: Same-day (0d), 7d, 30d, 90d, 180d, stale (>180d), future date clamping.
3. **Strength (Tests 22–32)**: Bounded $0 \dots 100$, empty handling, factor weights, Sarah Chen fixture, sparse profiles, deterministic reproduction, NaN safety, Infinity safety.
4. **State Classification (Tests 33–40)**: NEW, ACTIVE, STRONG, COOLING, NEGLECTED, DORMANT, exact day boundary transitions (30d, 31d, 60d, 61d, 181d), precedence hierarchy.
5. **Service Layer (Tests 41–44)**: Single profile derivation, non-existent person fallback, bulk intelligence, stream reactivity.
6. **UI Integration (Tests 45–47)**: State badge rendering, dossier integration, empty snapshot rendering.
7. **DI & Security (Tests 48–50)**: Mock DI wiring, production DI wiring, Sarah Chen golden journey verification.
