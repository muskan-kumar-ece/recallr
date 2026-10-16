# Recallr Network Intelligence Architecture v1

## 1. Executive Summary

Phase 13H-04 establishes Recallr's **Network Intelligence & Relationship Dashboard**. It elevates individual relationship intelligence (13H-01), proactive action recommendations (13H-02), and prioritized attention layers (13H-03) to a comprehensive, network-level operational overview.

The core question answered by this architecture is:
> **"How healthy is my professional network, what is changing, and where should I focus?"**

```text
REAL FIRESTORE
      ↓
users/{uid}/*
  ├── people
  ├── interactions / activities
  ├── follow_ups
  ├── claims / memories
  └── captures
      ↓
13H-01 Relationship Intelligence (Strength, State, Signals)
      ↓
13H-02 Relationship Actions (Proactive Recommendations)
      ↓
13H-03 Relationship Attention (Ranked Priority & Explainability)
      ↓
13H-04 Network Intelligence (Health, Trends, Insights, Dashboard)
      │
      ├── Network Health Score (0–100) & Level
      ├── Small-N Statistical Confidence Tiering
      ├── Temporal Momentum & Reliability Trends
      ├── Grounded Actionable Network Insights (Max 5)
      └── Responsive Dashboard UI (/network)
```

---

## 2. Non-Negotiable Architectural Guardrails

1. **Firestore as the Sole Source of Truth**: All network intelligence is dynamically derived on the fly from the user's authentic data (`users/{uid}/*`).
2. **Zero Secondary Storage**: No `network_health`, `network_metrics`, `network_insights`, or `network_scores` collections exist. Opening or calculating network intelligence causes zero Firestore mutations.
3. **100% Deterministic Calculations**: Scoring, metrics, temporal trends, and insights use deterministic mathematics. Zero LLM / Gemini token expenditure or non-deterministic variance for numerical intelligence.
4. **Small-N Statistical Safety**: Small networks never claim false statistical certainty. Networks of $N=0$ return zero score with limited confidence; $N=1\dots2$ maintain limited confidence; $N=3\dots9$ have moderate confidence; $N\ge10$ achieve high confidence.
5. **Fail-Closed Multi-Tenant Isolation**: Calculations resolve exclusively through `FirebaseAuth.instance.currentUser?.uid`. Unauthenticated contexts fail closed and render genuine empty states.
6. **Zero Runtime Mock Data**: No synthetic demo data exists in production runtime code.

---

## 3. Mathematical Health Scoring Formula

Network health is computed using a weighted composite formula:

$$\text{Health Score} = \left(0.35 \times \text{StateHealth} + 0.20 \times \text{RecencyHealth} + 0.15 \times \text{FollowUpReliability} + 0.15 \times \text{AttentionRisk} + 0.15 \times \text{RelationshipCoverage}\right) \times 100.0$$

### Component Definitions:
1. **Relationship State Health (35%)**:
   $$\text{StateHealth} = \frac{\sum \text{StateWeight}(p)}{N}$$
   - Strong: $1.00$
   - Active: $0.85$
   - New: $0.65$
   - Cooling: $0.45$
   - Neglected: $0.25$
   - Dormant: $0.10$
2. **Recent Interaction Health (20%)**:
   $$\text{RecencyHealth} = \min\left(1.0, \frac{\text{RecentInteractions}(< 30\text{d})}{N}\right)$$
3. **Follow-Up Reliability (15%)**:
   - Neutral baseline of $0.85$ when 0 follow-ups exist (no penalty for clean accounts).
   - Otherwise: $\left(\frac{\text{Completed}}{\text{Completed} + \text{Overdue}} - (\text{Overdue} \times 0.25)\right)$, clamped $[0.0, 1.0]$.
4. **Attention Risk (15%)**:
   $$\text{AttentionRisk} = \max\left(0.0, 1.0 - \frac{0.40 \times N_{\text{crit}} + 0.20 \times N_{\text{high}} + 0.10 \times N_{\text{med}}}{N}\right)$$
5. **Relationship Coverage (15%)**:
   $$\text{RelationshipCoverage} = \frac{N_{\text{with context}}}{N}$$

### Classification Tiers:
- **Excellent** ($85.0 \dots 100.0$): Emerald (`#10B981`)
- **Healthy** ($70.0 \dots 84.9$): Cyan (`#06B6D4`)
- **Developing** ($50.0 \dots 69.9$): Amber (`#F59E0B`)
- **At Risk** ($30.0 \dots 49.9$): Amber (`#F59E0B`)
- **Critical** ($0.0 \dots 29.9$): Crimson (`#EF4444`)

---

## 4. Temporal Trend Engine

Compares trailing 30-day temporal windows against preceding 30-day periods:
- **Interaction Momentum**: Compares interaction counts in the last 30 days vs 31–60 days ago.
- **Commitment Reliability**: Tracks completion rate vs overdue count.
- **Cooling Rate**: Identifies relationships actively transitioning to cooling or neglected states.
- **Data Integrity**: Returns `NetworkTrend.insufficientData()` when temporal history is insufficient.

---

## 5. Grounded Network Insights Engine

Generates at most **5** actionable, grounded observations sorted deterministically by:
$$\text{Severity Rank (DESC)} \rightarrow \text{Metric Value (DESC)} \rightarrow \text{Insight ID (ASC)}$$

Observations cover:
- Overdue relationship commitments
- High-priority relationship attention triggers
- Cooling relationship warnings
- Neglected connection flags
- Active core ratio highlights
- Context coverage gaps

---

## 6. Verification & Test Coverage

- Unit & Widget Tests: **72 / 72 tests passed (100%)** (`test/network_intelligence_test.dart`).
- Full Project Regression: **795 / 795 tests passed (100%)**.
- Static Analysis: `flutter analyze` $\rightarrow$ **0 issues found**.
- Runtime Mock Scan: **Zero leaks in production code**.
