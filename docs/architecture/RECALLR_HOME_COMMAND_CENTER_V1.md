# Recallr — Phase 05 Home / Memory Command Center Architecture v1

**Status:** COMPLETE & VERIFIED  
**Version:** 1.0.0  
**Phase:** 05  
**Locked Reference:** Recallr UI Architecture v1, Recallr Design System v1, Recallr App Shell & Navigation v1  

---

## 1. Executive Summary & Core Objective

Phase 05 establishes the **Home / Memory Command Center** for Recallr. Recallr Home is **not** a generic SaaS analytics dashboard, CRUD admin panel, or superficial AI template. It is the user''s personal professional-memory command center built to answer the foundational product question:

> **"What should I remember or act on right now?"**

The Home screen operationalizes the core relationship loop:
$$\text{Capture} \longrightarrow \text{Understand} \longrightarrow \text{Remember} \longrightarrow \text{Act}$$

---

## 2. Information Architecture & Hierarchy

```
┌────────────────────────────────────────────────────────────┐
│ 1. Context Header: Greeting + Sync Status Badge           │
├────────────────────────────────────────────────────────────┤
│ 2. Universal Memory Search: Ask Recallr Entry Card         │
├────────────────────────────────────────────────────────────┤
│ 3. Memory Pulse: People · Companies · Meetings · Follow-ups│
├────────────────────────────────────────────────────────────┤
│ 4. Needs Attention: Actionable Signals & Commitments       │
│    • I PROMISED: Commitments made by user                  │
│    • THEY PROMISED: Follow-ups expected from others        │
│    • MISSING CONTEXT: Scanned items requiring verification │
├────────────────────────────────────────────────────────────┤
│ 5. Key Contacts: Recently Interacted People Carousel       │
│    • Avatars + Roles + Companies + Top Capability Tags     │
├────────────────────────────────────────────────────────────┤
│ 6. Recently Remembered: Context-Rich Memory Stream         │
│    • Encounters, Company Updates, Meetings, DeepTech Notes │
├────────────────────────────────────────────────────────────┤
│ 7. Quick Capture: Home-Level Entry Affordance              │
│    • 1-Tap Trigger to Omni-Capture Bottom Sheet Flow       │
└────────────────────────────────────────────────────────────┘
```

---

## 3. Component Composition & File Structure

```
lib/
├── features/
│   └── home/
│       ├── models/
│       │   ├── home_memory_item.dart    # Domain models (Pulse, Attention, Person, Memory)
│       │   └── home_mock_data.dart      # Deterministic isolated mock dataset
│       └── widgets/
│           ├── home_header.dart         # Greeting & sync status indicator
│           ├── memory_search_card.dart  # Search & /ask entry card
│           ├── memory_pulse.dart        # Compact metrics bar & responsive grid
│           ├── attention_card.dart      # Actionable commitment signal tile
│           ├── needs_attention.dart     # Attention signals section
│           ├── recent_people.dart       # Horizontal key contacts carousel
│           ├── memory_card.dart         # Context-rich memory card
│           ├── recent_memories.dart     # Recent encounters feed
│           ├── quick_capture_tile.dart  # Home-level capture trigger
│           └── home_empty_state.dart    # First-memory onboarding state
└── screens/
    └── home/
        └── home_screen.dart             # Orchestrator & responsive layout builder
```

---

## 4. State Architecture & Lifecycle

The Home screen orchestrates five distinct system states:

| State | Trigger | Presentation | User Recovery / Action |
|---|---|---|---|
| **Loading** | `isLoading == true` | Structured `RecallrSkeleton` placeholders matching exact geometry | Shimmer animation indicates network/local sync |
| **Populated** | Default | Full 7-section Memory Command Center | Search, filter, inspect, capture, or follow up |
| **Empty Network** | `isEmpty == true` | `HomeEmptyState` (*"Your professional memory starts here"*) | Direct CTA to `Capture First Encounter` |
| **Empty Attention** | `items.isEmpty` | Section shrinks cleanly without breaking visual rhythm | Calm reassurance; no false urgency |
| **Error** | `isError == true` | Inline `RecallrErrorState` container with crimson alert border | `Retry` action invoking onRetry callback |

---

## 5. Responsive Multi-Device Architecture

Home seamlessly adapts across all viewport breakpoints without creating parallel routing systems:

### 5.1 Mobile (< 720dp)
* **Single-Column Sequential Flow:** Touch-optimized vertical rhythm with 16dp horizontal padding.
* **Key Contacts Carousel:** Smooth horizontal `ListView` with touch-friendly 220dp card widths.
* **FAB Access:** Global capture FAB remains elevated and accessible above the bottom navigation bar.

### 5.2 Tablet & Desktop (>= 720dp)
* **2-Column Command Center Composition:**
  * **Top Span:** Header, Universal Memory Search card, and 4-metric Memory Pulse.
  * **Left Column (flex 1):** Priority Attention signals + Key Contacts carousel.
  * **Right Column (flex 1):** Recent Memory context feed + Quick Capture entry tile.
* **Max-Width Constraint:** Constrained to 1040dp on ultrawide monitors to maintain optical reading line lengths.

---

## 6. Integration Contracts

* **Search $\rightarrow$ Ask Navigation:** Tapping `MemorySearchCard` executes `Navigator.pushNamed(RecallrRoutes.ask)` routing directly to Tab 2 (Grounded Memory Engine).
* **Capture Affordance:** Tapping `QuickCaptureTile` or empty state CTA invokes `RecallrBottomSheet.show(context: context, child: const CaptureModal())` without mutating shell navigation.
* **Parametric Detail Routing:**
  * Follow-ups: `/follow-up/:id`
  * People: `/person/:id`
  * Companies: `/company/:id`
  * Interactions: `/interaction/:id`
  * Files: `/file/:id`

---

## 7. Quality & Verification Record

### Automated Testing Matrix (`test/home_screen_test.dart`)

```
00:00 +0: loading C:/workflow/testapp/test/home_screen_test.dart
00:00 +0: C:/workflow/testapp/test/routing_test.dart: RecallrRoutes Tests parametric path generators format correctly
00:00 +1: C:/workflow/testapp/test/routing_test.dart: RecallrRoutes Tests primary routes match contracts
00:00 +2: C:/workflow/testapp/test/routing_test.dart: DeepLinkManager Tests ignores root and auth paths as pending deep links
00:00 +3: C:/workflow/testapp/test/routing_test.dart: DeepLinkManager Tests records and consumes parametric deep-link path correctly
00:00 +4: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders all populated sections correctly on mobile
00:02 +5: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests search card tap triggers navigation to Ask tab
00:03 +6: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests quick capture tile opens CaptureModal bottom sheet
00:03 +7: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests attention item tap triggers parametric route
00:04 +8: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests key contact item tap triggers person route
00:04 +9: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders empty state when isEmpty is true
00:04 +10: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders loading skeleton when isLoading is true
00:04 +11: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders error state with retry action
00:05 +12: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders 2-column layout on desktop viewports without overflow
00:05 +13: All tests passed!
```

### Static Analysis (`flutter analyze`)
* **Errors:** 0
* **Warnings:** 0
* **Deprecation info notices:** 9 (`withOpacity` info notices only)