# Recallr — Phase 08 Ask / Grounded Memory Engine Architecture v1

**Status:** COMPLETE & VERIFIED  
**Version:** 1.0.0  
**Phase:** 08  
**Locked Reference:** Recallr UI Architecture v1, Recallr Design System v1, Recallr App Shell & Navigation v1, Recallr Home Command Center v1, Recallr People Intelligence v1, Recallr Person Detail v1  

---

## 1. Executive Summary & Core Objective

Phase 08 implements the **Ask / Grounded Memory Engine** experience for Recallr. Recallr is **not** a generic chatbot or conversational gimmick. It is an **AI Personal Network Memory Engine** designed to answer:

> **"What do I already know about my professional network?"**

The Ask surface allows users to interrogate their entire network memory in plain English—querying past discussions, promises, capabilities, encounter locations, and connected organizations—with verified source citations and zero hallucination.

---

## 2. Information Architecture & Hierarchy

```
┌────────────────────────────────────────────────────────────┐
│ 08.1 Ask Header                                            │
│ • Title ("Ask Recallr") + Context ("Search your memory..") │
│ • Status Badge: [GROUNDED MEMORY]                          │
├────────────────────────────────────────────────────────────┤
│ 08.2 Universal Memory Query Card                           │
│ • Multi-line natural language input with prompt hint       │
│ • Action row: Voice trigger · Clear button · "Ask Memory"  │
├────────────────────────────────────────────────────────────┤
│ 08.3 Query Results Flow                                    │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ Grounded Answer Card                                   │ │
│ │ • Grounding Badge: [98% CONFIDENCE]                    │ │
│ │ • Metadata: "Grounded in 3 verified memories"          │ │
│ │ • Synthesized answer markdown/text                     │ │
│ │ • Follow-up suggestion prompt chips                    │ │
│ ├────────────────────────────────────────────────────────┤ │
│ │ Referenced People Section                              │ │
│ │ • Tappable person cards routing to /person/:id         │ │
│ ├────────────────────────────────────────────────────────┤ │
│ │ Sources & Memory Provenance Section                    │ │
│ │ • Type badge · Date · [VERIFIED] status                │ │
│ │ • Person/Company/Location provenance                   │ │
│ │ • Quoted memory excerpt                                │ │
│ │ • Tappable links to /interaction/:id, /file/:id, etc.  │ │
│ └────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────┘
```

---

## 3. Component Hierarchy & File Structure

```
lib/
├── features/
│   └── ask/
│       ├── models/
│       │   ├── ask_models.dart         # Domain models (AskQuery, GroundedAnswer, MemorySource, PersonReference, GroundingMetadata)
│       │   └── ask_mock_data.dart      # Deterministic isolated mock retrieval engine
│       └── widgets/
│           ├── ask_header.dart         # Header with title and grounded badge
│           ├── memory_query_card.dart  # Universal query card with voice and submit actions
│           ├── suggested_questions.dart# Suggested queries with quick-trigger chips
│           ├── recent_queries.dart     # History chips of past questions
│           ├── grounded_answer_card.dart# Synthesized answer with confidence & grounding metadata
│           ├── related_people_section.dart# Referenced people cards linking to /person/:id
│           ├── memory_sources_section.dart# Provenance citations with excerpts and [VERIFIED] badges
│           ├── ask_no_results_state.dart# Low-confidence / ungrounded query recovery state
│           └── query_loading_state.dart# Shimmer retrieval and AI reasoning skeletons
└── screens/
    └── ask/
        └── ask_screen.dart             # Stateful Ask orchestrator & responsive multi-column layout
```

---

## 4. State Architecture & Lifecycle

The Ask surface manages five distinct lifecycle states:

| State | Condition | Presentation | User Recovery / Next Step |
|---|---|---|---|
| **Initial** | `!_hasQueried` | Header + Memory Query Card + Suggested Inquiries + Recent Questions | Tap suggestion or type query |
| **Loading** | `_isLoading == true` | `QueryLoadingState` with memory search indicators and skeleton placeholders | Shimmer indicator during retrieval |
| **Populated** | `_currentAnswer != null` | Grounded Answer Card + Referenced People + Sources & Provenance | 1-tap navigation to dossiers, follow-up query chips |
| **No Results** | `_currentAnswer == null` | `AskNoResultsState` with helpful memory guidance | Tap suggestion chips to explore remembered topics |
| **Error** | `_isError == true` | `RecallrErrorState` alert container | *"Retry"* action re-executes query |

---

## 5. Grounding & Provenance Model

Recallr enforces a strict provenance contract:
- Every answer is accompanied by **grounding metadata** (e.g. *"Grounded in 3 verified memories across 2 encounters"*).
- Every claim displays its **provenance source**:
  - `sourceType` (Meeting Note, Visiting Card, Active Commitment, Discussion Excerpt)
  - `personName` & `company`
  - `eventOrLocation` (e.g. *"Hyderabad Tech Summit · HICC Novotel"*)
  - `date` (e.g. *"Yesterday · 4:30 PM"*)
  - `excerpt` in quotation styling
  - `isVerified` badge (`[VERIFIED]`)
  - Target route linking directly to `/interaction/:id`, `/file/:id`, or `/follow-up/:id`.

---

## 6. Responsive Multi-Device Architecture

### 6.1 Mobile (< 720dp)
* **Single-Column Narrative Flow:** Vertically stacked flow (Header -> Query Card -> Answer Card -> Referenced People -> Provenance Sources).
* **Thumb-Friendly Touch Targets:** All query cards, prompt chips, and citation links adhere strictly to $\ge 48\text{dp}$.

### 6.2 Tablet & Desktop ($\ge 720\text{dp}$)
* **2-Column Balanced Memory Layout:**
  - **Top Area:** Header + Memory Query Card spanning full width.
  - **Left Column (flex 1):** Grounded Answer Card + Referenced People Section.
  - **Right Column (flex 1):** Sources & Memory Provenance citations.
* **Max-Width Constraint:** Constrained to 1040dp on ultrawide displays to preserve optical scanability.

---

## 7. Navigation & Cross-Surface Integration

1. **Home → Ask:**
   - Tapping `MemorySearchCard` on Home switches directly to Tab 2 (`/ask`).
2. **Person Detail → Ask:**
   - Tapping prompt suggestion chips on `AskAboutPersonCard` inside `/person/:id` routes to `RecallrRoutes.ask` (`/ask`) with the query argument, which auto-executes the search upon opening.
3. **Ask → Person Detail:**
   - Tapping any referenced person inside Ask answer routes directly to `/person/:id`.
4. **Deep-Link Restoration & Auth Protection:**
   - `/ask` route is fully guarded and unauthenticated deep links are preserved post-login via `DeepLinkManager`.

---

## 8. Verification Record

### Automated Tests (`test/ask_screen_test.dart` + `test/person_detail_screen_test.dart` + `test/people_screen_test.dart` + `test/home_screen_test.dart` + `test/routing_test.dart`)

```
00:00 +0: loading C:/workflow/testapp/test/ask_screen_test.dart
00:00 +0: C:/workflow/testapp/test/ask_screen_test.dart: AskScreen Phase 07 Tests 1. Ask landing screen renders header, composer, suggestions, and recents
...
00:08 +44: All tests passed!
```

### Static Analysis (`flutter analyze`)
* **Errors:** 0
* **Warnings:** 0
* **Issues:** 0 (Clean analysis across all 44 test targets and app modules)

---

### 9. Future RAG Integration Boundary

The presentation layer is 100% decoupled from the retrieval mechanism via `AskQuery`, `GroundedAnswer`, `MemorySource`, and `GroundingMetadata`. When vector embedding indexing and Gemini grounding APIs are connected in future backend phases, only the repository layer under `lib/features/ask/` needs to be swapped for live Firestore/Vector services without modifying any UI components or routing.