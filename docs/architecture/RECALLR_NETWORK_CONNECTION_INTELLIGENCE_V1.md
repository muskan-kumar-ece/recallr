# RECALLR RELATIONSHIP PATTERNS & NETWORK CONNECTIONS INTELLIGENCE ARCHITECTURE (V1)
**Phase**: 13H-06 — Relationship Patterns & Network Connections Intelligence
**Document Version**: 1.0.0
**Date**: August 30, 2026
**Status**: Production Verified & Fully Tested

---

## 1. Executive Summary & Objective

The **Recallr Relationship Patterns & Network Connections Intelligence Engine** sits on top of the validated **13H-01 → 13H-05 Relationship Intelligence Stack**. It transforms the authentic Firestore relationship graph into an in-memory, deterministic, and explainable network-pattern layer to answer:

> *"What patterns exist across my professional relationships, who is connected to whom, where are my strongest relationship clusters, and where are the gaps in my network?"*

### Core Architectural Pillars
1. **Firestore Remains the Only Source of Truth**: Evaluates only authentic entities in `users/{uid}/people`, `users/{uid}/activities`, `users/{uid}/captures`, and memory claims. No secondary graph database or new collections (`network_graph`, `relationship_clusters`, `network_connections`) are introduced.
2. **Zero Firestore Writes During Evaluation**: Derivation is strictly in-memory and read-only.
3. **Zero Gemini/LLM Dependency for Factual Graph Structure**: Graph topology, edge existence, cluster boundaries, bridge roles, and network gaps are 100% deterministic mathematical calculations.
4. **Zero Mock/Demo Data in Production (`lib/`)**: Unauthenticated or empty accounts yield genuine empty states.
5. **Canonical Pair Normalization**: Edges are indexed canonically with $\min(personAId, personBId)$ and $\max(personAId, personBId)$ to prevent duplicate directed edges.
6. **Small-N Protection Rules**: 
   - $N=0$ or $N=1$: No clusters ($0$).
   - $N=2$: Emerging cluster (`RelationshipClusterType.emerging`, strength $\le 50$).
   - $N \ge 3$: Established company or project cluster (`RelationshipClusterType.company` / `project`).

---

## 2. In-Memory Graph Data Models

### 2.1 `NetworkConnection`
Represents a deterministic undirected connection edge between two distinct contacts backed by explicit stored evidence.
- **Pair Ordering**: Canonical $A < B$.
- **Edge ID**: `conn_${personAId}_${personBId}`.
- **Evidence Types**: `sharedCompany`, `sharedInteraction`, `sharedProject`, `sharedCapture`, `sharedContext`.
- **Score**: Bounded $0.0 .. 100.0$ computed from weighted evidence components.

### 2.2 `RelationshipCluster`
A cohesive group of contacts sharing an authentic organizational, project, or domain context.
- **Cluster Types**: `company`, `project`, `emerging`.
- **Slug IDs**: Deterministic slugs such as `cluster_company_cyberdyne` or `cluster_project_nebula`.
- **Metrics**: Member count, average strength ($0..100$), average attention score ($0..100$), interaction count, composite cluster strength ($0..100$).

### 2.3 `NetworkPattern`
A detected network-level insight or structural relationship dynamic.
- **Pattern Types**: `strongCluster`, `emergingCluster`, `coolingCluster`, `companyConcentration`, `relationshipBridge`, `isolatedContact`, `networkGap`, `balancedNetwork`.
- **Severity Tiers**: `critical` (5), `high` (4), `medium` (3), `low` (2), `info` (1).
- **Deterministic Sort Order**: `severity DESC` $\rightarrow$ `impactScore DESC` $\rightarrow$ `id ASC`.
- **Explainability**: Strict citation of underlying evidence person IDs and connection IDs.

### 2.4 `NetworkGraph`
An in-memory representation with nodes sorted by `personId ASC` and connections by `edgeId ASC`.
- Node metadata: relationship strength, relationship state, momentum direction.
- Graph helper methods: `isIsolated(personId)`, `neighborIdsFor(personId)`, `connectionsFor(personId)`.

### 2.5 `NetworkConnectionIntelligence`
The top-level aggregate domain model containing:
- `networkDensity`: $\frac{2 \times E}{N \times (N - 1)}$ (bounded $0.0 .. 1.0$).
- `crossCompanyConnectivity`: Percentage of inter-company connections ($0.0 .. 100.0$).
- `concentrationScore`: Maximum company share percentage ($0.0 .. 100.0$).
- `bridgeContacts`: List of contact IDs acting as bridges across $2+$ distinct clusters.
- `connectedPeople` vs `isolatedPeople`.

---

## 3. Mathematical & Algorithmic Foundations

### 3.1 Connection Score Formulation
$$Score = \min\left(100.0, W_{\text{company}} + W_{\text{interaction}} + W_{\text{project}} + W_{\text{volume}} + W_{\text{strength}}\right)$$
Where:
- $W_{\text{company}} = 30.0$ (if shared company is present and valid).
- $W_{\text{interaction}} = 30.0$ (if shared activity/meeting or mutual entity reference exists).
- $W_{\text{project}} = 20.0$ (if shared project or memory claim exists).
- $W_{\text{volume}} = \min(10.0, \text{evidenceCount} \times 3.33)$.
- $W_{\text{strength}} = \frac{\text{avgStrength}}{100.0} \times 10.0$.

### 3.2 Cluster Strength Formulation
$$ClusterStrength = \text{clamp}\left(0.40 \times S_{\text{size}} + 0.35 \times \text{avgStrength} + 0.25 \times S_{\text{interactions}}, 0.0, 100.0\right)$$
Where $S_{\text{size}} = \min(100.0, \text{memberCount} \times 20.0)$ and $S_{\text{interactions}} = \min(100.0, \text{interactionCount} \times 5.0)$.

### 3.3 Small-N & Division-by-Zero Guards
- For $N < 2$, `networkDensity` is locked to $0.0$.
- For total connections $= 0$, `crossCompanyConnectivity` is locked to $0.0$.
- For total nodes $= 0$, `concentrationScore` is locked to $0.0$.

---

## 4. UI Components & Presentation Layer

1. **`NetworkConnectionsSummary`**:
   - High-contrast 4-metric grid (Total Connections, Network Density %, Relationship Clusters, Isolated Contacts).
   - Glassmorphic card design matching Recallr Charcoal/Slate design tokens with zero rendering overflow.

2. **`NetworkClustersSection`**:
   - Color-coded cluster badges (`aiElectricViolet` for company, `aiCyanHighlight` for project, `warmAmberGold` for emerging).
   - Member count, total interaction tally, and composite cluster strength score.

3. **`NetworkPatternsSection`**:
   - Severity pills (`CRITICAL`, `HIGH`, `MEDIUM`, `LOW`, `INFO`).
   - Grounded explanations citing exact integer metrics with concrete recommended actions.

4. **`NetworkDashboardScreen` Integration**:
   - Filter pills (`All`, `Clusters`, `Cooling`, `Bridges`) enabling granular exploration of network topology.
   - Dual support for synchronous injection via `initialConnectionData` and reactive streaming via `RecallrDependencies`.

5. **`PersonDetailScreen` Relationship Dossier**:
   - **Connected Through** section presenting shared company/interaction evidence and connection strength.
   - **NETWORK BRIDGE** badge with explanation when a contact spans multiple clusters.
   - Truthful isolated message when no stored connections exist.

---

## 5. Verification Matrix & Test Summary

| Test Group | Focus Area | Tests | Pass Rate |
|---|---|---|---|
| **Group 1** | Connection Detection & Multi-Evidence | 13 | 100% |
| **Group 2** | Connection Strength & Math Bounds | 10 | 100% |
| **Group 3** | Cluster Detection & Small-N Rules | 10 | 100% |
| **Group 4** | Graph Integrity & Topology | 8 | 100% |
| **Group 5** | Network Math & Density Safety | 8 | 100% |
| **Group 6** | Pattern Detection & Precedence | 12 | 100% |
| **Group 7** | Grounded Explanations & Privacy | 8 | 100% |
| **Group 8** | Multi-Tenant Security & Serialization | 8 | 100% |
| **Group 9** | UI Widgets & Screen Integration | 10 | 100% |
| **Group 10** | Composition, DI Wiring & Golden Journey | 7 | 100% |
| **Total Phase 13H-06 Tests** | Dedicated Test Suite | **94** | **100%** |
| **Total Project Test Suite** | Full Project (`flutter test`) | **967** | **100%** |

### Static Analysis
- `flutter analyze`: **0 errors, 0 warnings, 0 lints**.
- Mock leak audit: **0 mock leaks detected in `lib/`**.
