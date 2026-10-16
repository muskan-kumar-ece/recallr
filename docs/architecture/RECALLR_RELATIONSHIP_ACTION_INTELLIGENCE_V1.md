# Phase 13H-02 — Proactive Relationship Actions & Follow-up Intelligence Engine Architecture v1

---

## 1. Executive Summary & Objective

**Phase 13H-02** establishes Recallr's **Proactive Relationship Actions & Follow-up Intelligence Engine** directly on top of the Phase 13H-01 Relationship Intelligence Foundation.

While Phase 13H-01 answers:
> **“What is the current state and strength of this relationship?”**

Phase 13H-02 answers:
> **“What should I do next about this relationship, and why?”**

The engine is **100% deterministic, explainable, grounded in authoritative Firestore signals, multi-tenant secure, idempotent, and completely independent of Gemini or LLMs for decision-making and priority scoring**.

---

## 2. Core Architectural Principles & Invariants

```text
Firebase Auth (Resolved internally)
      ↓
Real Firestore (Single Source of Truth)
      ↓
Production Repositories (People / Activity / Follow-ups)
      ↓
Relationship Intelligence Signals (Recency / Frequency / Commitments)
      ↓
Deterministic State Classifier & Strength Calculator (Phase 13H-01)
      ↓
Relationship Action Priority Calculator (Urgent / High / Medium / Low)
      ↓
Proactive Action Engine (Eligibility Rules + Idempotent Deduplication)
      ↓
Person Dossier ("Recommended Next Step") / Home Command Center ("Relationship Attention")
      ↓
Explicit Navigation & Pre-filled Follow-up Handoff
```

### Invariants:
1. **Firestore is the Single Source of Truth**: No duplicate database or secondary cache is created.
2. **Zero Mock / Demo Data**: All recommendations are derived from genuine user data.
3. **Deterministic & Idempotent**: Identical input signals always produce identical recommendations and priorities.
4. **No LLM Decision-Making**: Action eligibility, priority ranking, and timing rules are deterministic code, never LLM hallucinations.
5. **No Automatic Database Mutations**: AI recommendations do not mutate Firestore or generate phantom follow-up documents automatically. Users explicitly review and create follow-ups via button handoffs.
6. **Multi-Tenant User Isolation**: All operations resolve `FirebaseAuth.currentUser.uid` internally. Unauthenticated requests fail closed.

---

## 3. Domain Models (`lib/features/relationship_intelligence/models/relationship_action.dart`)

### `RelationshipActionType`
| Type | Label | Icon | Purpose |
| :--- | :--- | :--- | :--- |
| `reconnect` | Reconnect | `Icons.replay_rounded` | Re-engaging with cooling or neglected valuable contacts |
| `followUp` | Follow Up | `Icons.schedule_send_rounded` | General commitment or scheduled check-in |
| `completeOverdueFollowUp` | Complete Overdue Follow-up | `Icons.notification_important_rounded` | Fulfilling past-due commitments or promises |
| `reviewRelationship` | Review Relationship | `Icons.rate_review_outlined` | Nurturing strong connections before they decay |
| `reviewRecentInteraction` | Review Recent Interaction | `Icons.fact_check_outlined` | Processing context right after recent meetings |
| `captureMissingContext` | Capture Missing Context | `Icons.post_add_rounded` | Prompting for notes when interactions lack memories |

### `RelationshipActionPriority`
| Priority | Rank | Badge Label | Color Token | Description |
| :--- | :---: | :--- | :--- | :--- |
| `urgent` | **4** | `URGENT` | `RecallrColors.alertCrimson` | Overdue follow-up on strong/high-score relationship or multiple overdue commitments |
| `high` | **3** | `HIGH PRIORITY` | `RecallrColors.warmAmberGold` | Cooling/neglected contacts with rich history, or single overdue commitment |
| `medium` | **2** | `RECOMMENDED` | `RecallrColors.aiCyanHighlight` | Recent interactions (≤48h), sparse context contacts, or standard follow-ups |
| `low` | **1** | `SUGGESTION` | `RecallrColors.textSecondary` | Long-term dormant reconnect suggestions or gentle maintenance |

### `RelationshipActionStatus`
* `suggested`: Active recommendation ready for user review.
* `dismissed`: Dismissed by the user.
* `snoozed`: Temporarily postponed.
* `completed`: Fulfilled by user action.

### `RelationshipAction` Properties
* `id`: Unique identifier (`action_${personId}_${type.name}_${triggerKey}`).
* `personId`: Target contact ID.
* `personName`: Target contact name.
* `type`: `RelationshipActionType`.
* `priority`: `RelationshipActionPriority`.
* `status`: `RelationshipActionStatus`.
* `title`: Concise human-readable action title.
* `description`: Grounded context explanation.
* `reason`: Explainable evidence reason based on actual stored signals.
* `recommendedAt`: Recommended timing window (`Today`, `Within 2–3 days`, `This week`, `Soon`).
* `targetRoute`: Navigation route path (e.g. `/person/:id`).
* `sourceSignals`: List of contributing signal strings.
* `relationshipState`: Associated `RelationshipState`.
* `relationshipScore`: Snapshot relationship strength score (0.0–100.0).
* `deduplicationKey`: Idempotent deduplication key.
* `generatedAt`: Generation timestamp.

---

## 4. Deterministic Priority Calculation (`lib/services/relationship/relationship_action_priority_calculator.dart`)

```dart
class DeterministicRelationshipActionPriorityCalculator implements RelationshipActionPriorityCalculator {
  @override
  RelationshipActionPriority calculate({
    required PersonRelationshipIntelligence intelligence,
    required RelationshipActionType type,
  }) {
    final signals = intelligence.signals;
    final state = intelligence.state;
    final score = intelligence.strength.score;

    switch (type) {
      case RelationshipActionType.completeOverdueFollowUp:
        // Strong relationship or multiple overdue -> Urgent
        if (state == RelationshipState.strong || score >= 70.0 || signals.overdueFollowUpCount > 1) {
          return RelationshipActionPriority.urgent;
        }
        return RelationshipActionPriority.high;

      case RelationshipActionType.reconnect:
        if (state == RelationshipState.neglected && (signals.interactionCount >= 3 || signals.memoryCount >= 2)) {
          return RelationshipActionPriority.high;
        }
        if (state == RelationshipState.cooling && score >= 65.0) {
          return RelationshipActionPriority.high;
        }
        if (state == RelationshipState.cooling) {
          return RelationshipActionPriority.medium;
        }
        return RelationshipActionPriority.low;

      case RelationshipActionType.reviewRecentInteraction:
        return RelationshipActionPriority.medium;

      case RelationshipActionType.captureMissingContext:
        return RelationshipActionPriority.medium;

      case RelationshipActionType.reviewRelationship:
        return RelationshipActionPriority.medium;

      case RelationshipActionType.followUp:
        if (signals.hasOverdueFollowUp) return RelationshipActionPriority.high;
        return RelationshipActionPriority.medium;
    }
  }
}
```

---

## 5. Proactive Action Engine (`lib/services/relationship/relationship_action_engine.dart`)

### Eligibility Rules:
1. **Rule 1: Overdue Commitments (`completeOverdueFollowUp`)**
   * *Trigger*: `signals.hasOverdueFollowUp == true`.
   * *Key*: `'action_${profile.id}_completeOverdueFollowUp_overdue_${signals.overdueFollowUpCount}'`

2. **Rule 2: Relationship Reconnection (`reconnect`)**
   * *Trigger*: (`state == COOLING` || `state == NEGLECTED`) && has history (`interactionCount >= 2` || (`interactionCount >= 1` && `memoryCount >= 1`)).
   * *Guard*: Never triggers for brand new contacts with 0 history.
   * *Key*: `'action_${profile.id}_reconnect_${state.name}'`

3. **Rule 3: Recent Interaction Review (`reviewRecentInteraction`)**
   * *Trigger*: `daysSinceLastInteraction != null && daysSinceLastInteraction <= 2 && interactionCount >= 1`.
   * *Key*: `'action_${profile.id}_reviewRecentInteraction_${signals.daysSinceLastInteraction}'`

4. **Rule 4: Missing Context Capture (`captureMissingContext`)**
   * *Trigger*: `interactionCount >= 3 && (memoryCount + captureCount) == 0`.
   * *Key*: `'action_${profile.id}_captureMissingContext_sparse'`

5. **Rule 5: Strong Connection Nurturing (`reviewRelationship`)**
   * *Trigger*: `state == STRONG && daysSinceLastInteraction >= 15 && daysSinceLastInteraction <= 30 && activeFollowUpCount == 0 && !hasOverdueFollowUp`.
   * *Key*: `'action_${profile.id}_reviewRelationship_maintenance'`

### Strict Ordering & Top Action Selection:
Actions are sorted by `priority.rank` descending ($4 > 3 > 2 > 1$), then by `relationshipScore` descending. `getPrimaryAction(profile, intelligence)` returns the top eligible action.

---

## 6. Grounded Explainability & Timing (`lib/services/relationship/relationship_action_explanation.dart`)

| Action Type | Grounded Title Format | Grounded Context Description Format | Recommended Timing |
| :--- | :--- | :--- | :--- |
| `completeOverdueFollowUp` | `Complete overdue follow-up with {Name}` | `You have {N} overdue commitment(s) with {Name} that need immediate attention.` | `Today` |
| `reconnect` | `Reconnect with {Name}` | `It's been {N} days since your last interaction with {Name}. Reach out to keep connection active.` | `Within this week` / `This week` |
| `reviewRecentInteraction` | `Review recent interaction with {Name}` | `You interacted with {Name} {today/N days ago}. Capture key takeaways or follow-ups.` | `Today` / `Within 2–3 days` |
| `captureMissingContext` | `Capture context for {Name}` | `You have {N} interactions with {Name} but no saved memories or notes. Add key context.` | `Soon` |
| `reviewRelationship` | `Nurture relationship with {Name}` | `Strong relationship with {Name} has had no check-ins for {N} days. Keep in touch.` | `This week` |

---

## 7. UI Integrations & User Flows

### A. Person Detail Dossier ("RECOMMENDED NEXT STEP" Card)
* Located directly inside `RelationshipIntelligence` under the Relationship Strength bar.
* Features priority color accent, type icon, priority badge, clear grounded explanation, recommended timing badge, and full-width `[ Create Follow-up ]` button.
* Tapping `[ Create Follow-up ]` navigates to `/follow-ups` with pre-filled route arguments (`personId`, `personName`, `context`).

### B. Home Command Center ("Relationship Attention" Section)
* Located in `HomeScreen` above needs attention and recent sections.
* Features header with action counter, priority badges, contact names, titles, descriptions, and adaptive button layouts.
* Responsive `LayoutBuilder` (<340px column stacking vs >=340px row alignment) prevents any RenderFlex overflows on mobile, tablet, or desktop.
* Tapping `[ View Person ]` navigates to `/person/:id`.
* Tapping `[ Create Follow-up ]` opens follow-up creator with pre-filled contact context.

---

## 8. Verification & Test Suite Summary

The dedicated test suite `test/relationship_action_intelligence_test.dart` contains **50 comprehensive unit and widget tests** covering:
1. **Domain Models & Serialization**: Round-trip fidelity, copyWith immutability, rank comparisons.
2. **Deterministic Priority Calculator**: All edge cases, priority thresholds, overdue count escalation.
3. **Explainability Generator**: Grounded copy without hallucination, plural handling, relative timing formatting.
4. **Action Engine Rules**: 5 eligibility rules, brand new contact suppression, deduplication reproducibility, priority sorting.
5. **UI Widget Integrations**: Rendering in `RelationshipIntelligence`, `RelationshipAttentionSection`, tap callbacks, responsive viewports.
6. **Integration Pipelines**: End-to-end signal -> strength -> state -> action engine derivations.

### Global Test Suite Run Results:
* `flutter test test/relationship_action_intelligence_test.dart`: **50 / 50 PASSED (100%)**
* `flutter test test/relationship_intelligence_test.dart`: **50 / 50 PASSED (100%)**
* `flutter test test/person_detail_screen_test.dart`: **22 / 22 PASSED (100%)**
* `flutter test test/home_screen_test.dart`: **9 / 9 PASSED (100%)**
* `flutter test`: **663 / 663 PASSED (100%) across all test files**
* `flutter analyze`: **0 issues found!**
