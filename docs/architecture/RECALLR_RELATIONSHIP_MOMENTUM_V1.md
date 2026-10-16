# Recallr Relationship Evolution & Momentum Intelligence Architecture v1

## 1. Executive Summary

Phase 13H-05 establishes Recallr's **Relationship Evolution & Momentum Intelligence Engine**. It builds directly on top of the verified foundations of Relationship Intelligence (13H-01), Relationship Actions (13H-02), Relationship Attention (13H-03), and Network Intelligence (13H-04).

The core operational question answered by this architecture is:
> **"How is each relationship evolving over time, what is the interaction momentum and cadence, and who is accelerating, cooling, declining, or recovering?"**

```text
AUTHENTIC FIRESTORE (users/{uid}/*)
      │
      ├─ interactions / activities
      ├─ follow_ups
      ├─ people / profiles
      └─ claims / memories
      ↓
Phase 13H-01: Relationship Signals & Strength
      ↓
Phase 13H-05: Evolution & Momentum Intelligence
      ├─ Cadence Calculator (Inter-encounter interval mean & standard deviation)
      ├─ Velocity Calculator (Trailing 30d, 31–60d, 61–90d touchpoint counts & Δ)
      ├─ Evolution Classifier (Strict precedence: insufficientHistory → newlyDeveloping → recovering → strengthening → declining → cooling → stable)
      ├─ Grounded Explanations (Strict anti-psychologizing, factual dates/metrics)
      ├─ RelationshipMomentumCard (Person Dossier integration)
      └─ Network Dashboard Momentum Summary (/network)
```

---

## 2. Non-Negotiable Architectural Guardrails

1. **Firestore as Sole Source of Truth**: All momentum metrics and evolution trajectories are derived dynamically on-the-fly from authentic interaction records in `users/{uid}/activities`, `users/{uid}/interactions`, `users/{uid}/follow_ups`, and `users/{uid}/people`.
2. **Zero Secondary Storage**: No `relationship_momentum`, `evolution_history`, `cadence_metrics`, or `velocity_log` Firestore collections exist. Calculating momentum causes zero Firestore mutations (zero writes).
3. **100% Deterministic Computation**: All intervals, cadence ratios, velocity deltas, percentage changes, momentum classifications, and composite scores are computed via deterministic mathematical formulas. Zero LLM / Gemini token expenditure or non-deterministic variance for momentum intelligence.
4. **Strict Anti-Psychologizing & Privacy**: Explanations never infer emotional states, personal sentiments, or subjective intentions (e.g., zero occurrences of "losing interest", "growing distant", "drifting apart"). Explanations only cite factual numbers, inter-encounter intervals, and dates.
5. **Small-N & Temporal Truth**: When $< 2$ distinct encounter dates exist, the engine strictly returns `insufficientHistory` with clean `null` percentage changes and truthful limited-data explanations. No manufactured or assumed previous-period touchpoints are fabricated.
6. **Multi-Tenant Fail-Closed Isolation**: Unauthenticated requests fail closed, and queries resolve solely under `users/{uid}/*`. Contacts from separate user accounts or distinct person IDs never collide or leak state.
7. **Zero Runtime Mock Data**: Zero mock profiles (e.g. Priya Sharma, Arjun Mehta, Sarvam AI, RISC-V) exist in runtime production code.

---

## 3. Mathematical Momentum & Cadence Formulas

### 3.1 Cadence Analysis
Given a chronological sequence of distinct encounter dates $D = [d_1, d_2, \dots, d_n]$ ($n \ge 2$):
1. **Inter-encounter intervals**:
   $$\Delta t_i = \text{daysBetween}(d_i, d_{i+1}) \quad \forall i \in [1, n-1]$$
2. **Average Cadence**:
   $$\mu_{\text{cadence}} = \frac{1}{n-1} \sum_{i=1}^{n-1} \Delta t_i$$
3. **Cadence Ratio**:
   $$\text{Ratio} = \frac{\text{daysSinceLastInteraction}}{\mu_{\text{cadence}}}$$
   - $\text{Ratio} \le 1.25$: On-pace
   - $1.25 < \text{Ratio} \le 2.50$: Off-pace
   - $\text{Ratio} > 2.50$: Severely off-pace

### 3.2 Interaction Velocity
Using a sliding 90-day window relative to reference date $t_{\text{ref}}$:
- **Recent Period** ($[t_{\text{ref}} - 30\text{d}, t_{\text{ref}}]$): Count $C_{\text{recent}}$
- **Previous Period** ($[t_{\text{ref}} - 60\text{d}, t_{\text{ref}} - 31\text{d}]$): Count $C_{\text{previous}}$
- **Prior Period** ($[t_{\text{ref}} - 90\text{d}, t_{\text{ref}} - 61\text{d}]$): Count $C_{\text{prior}}$
- **Velocity Delta**: $\Delta v = C_{\text{recent}} - C_{\text{previous}}$
- **Percentage Change**:
  $$\% \Delta = \begin{cases} \text{null} & \text{if } C_{\text{recent}} = 0 \text{ and } C_{\text{previous}} = 0 \\ +100.0\% & \text{if } C_{\text{recent}} > 0 \text{ and } C_{\text{previous}} = 0 \\ \frac{C_{\text{recent}} - C_{\text{previous}}}{C_{\text{previous}}} \times 100.0 & \text{if } C_{\text{previous}} > 0 \end{cases}$$

---

## 4. Deterministic Precedence Rules

Classification follows strict deterministic waterfall precedence:

| Precedence | Direction | Deterministic Condition |
|---|---|---|
| **1** | `insufficientHistory` | Total historical encounters $< 2$, or all encounters on the same calendar day. |
| **2** | `newlyDeveloping` | Relationship age $\le 60\text{d}$, first met within $60\text{d}$, and $C_{\text{recent}} \ge 2$. |
| **3** | `recovering` | Days since interaction $\le 30\text{d}$, $C_{\text{recent}} \ge 1$, and $C_{\text{previous}} = 0$ with $C_{\text{prior}} \ge 1$ (or historical count $\ge 3$). |
| **4** | `strengthening` | $\Delta v > 0$, $C_{\text{recent}} \ge 2$, and days since interaction $\le 30\text{d}$. |
| **5** | `declining` | Days since interaction $> 60\text{d}$, or $\text{Ratio} > 2.50$, or overdue follow-ups $\ge 2$. |
| **6** | `cooling` | Days since interaction $\in [31\text{d}, 60\text{d}]$, or $\Delta v < 0$ with $C_{\text{previous}} \ge 2$, or $1.50 \le \text{Ratio} \le 2.50$. |
| **7** | `stable` | Default baseline when cadence is maintained ($\text{Ratio} < 1.50$) and velocity is non-negative. |

---

## 5. UI Architecture & Dossier Integration

### 5.1 RelationshipMomentumCard
Located in `lib/features/relationship_intelligence/widgets/relationship_momentum_card.dart`, rendering:
- Direction Badge with semantic color tokens (`emeraldVerified`, `aiViolet`, `aiCyanHighlight`, `warmAmberGold`, `alertCrimson`, `slateSurface`).
- Velocity comparison chip ($C_{\text{recent}}$ vs $C_{\text{previous}}$ with signed percentage change).
- Average Cadence indicator (e.g. `~14 days avg`).
- Grounded explanation bullet points and cadence alert banners.

### 5.2 Person Dossier Embedding
Embedded directly into `lib/features/person_detail/widgets/relationship_intelligence.dart` below the strength and signal cards and above the action recommendations.

### 5.3 Network Dashboard Summary
Section `_buildEvolutionMomentumSummary` embedded inside `lib/screens/network/network_dashboard_screen.dart`, providing a breakdown of accelerating vs cooling vs recovering relationships across the user's active network.

---

## 6. Dependency Injection Wiring

`RecallrDependencies` is updated with full lifecycle management:
- `cadenceCalculator`: `RelationshipCadenceCalculator`
- `velocityCalculator`: `RelationshipVelocityCalculator`
- `evolutionClassifier`: `RelationshipEvolutionClassifier`
- `relationshipMomentumEngine`: `RelationshipMomentumEngine`
- `relationshipMomentumService`: `RelationshipMomentumService`

---

## 7. Verification & Test Coverage Summary

- **Static Analysis**: `flutter analyze` → **0 issues** across entire repository.
- **Dedicated 13H-05 Test Suite**: `test/relationship_evolution_momentum_test.dart` → **78 / 78 tests passing (100%)**.
- **Relationship Intelligence Suites**: 332 tests across 6 dedicated test files → **100% passing**.
- **Full Project Regression**: `flutter test` → **873 / 873 tests passing (100%)**.
- **Runtime Mock Scan**: `git grep -n -E "Priya Sharma|Arjun Mehta|Sarvam AI|RISC-V" lib/` → **0 matches (0 leaks)**.
