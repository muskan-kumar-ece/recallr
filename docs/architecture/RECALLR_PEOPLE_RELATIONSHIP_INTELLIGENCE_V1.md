# Recallr — Phase 06 People / Relationship Intelligence Architecture v1

**Status:** COMPLETE & VERIFIED  
**Version:** 1.0.0  
**Phase:** 06  
**Locked Reference:** Recallr UI Architecture v1, Recallr Design System v1, Recallr App Shell & Navigation v1, Recallr Home Command Center v1  

---

## 1. Executive Summary & Core Objective

Phase 06 establishes the **People / Relationship Intelligence** experience for Recallr. Recallr is **not** a traditional address book, contacts list, or enterprise CRM. A person in Recallr is represented as:

$$\text{Person} + \text{Professional Identity} + \text{Encounters} + \text{Conversations} + \text{Context} + \text{Capabilities} + \text{Follow-ups} + \text{Relationship History}$$

The People directory answers the core relationship question:

> **"Who do I know, what do I remember about them, and what should I do next?"**

---

## 2. Information Architecture & Hierarchy

```
┌────────────────────────────────────────────────────────────┐
│ 1. People Header: Title + Context + Network Count Badge    │
├────────────────────────────────────────────────────────────┤
│ 2. Relationship-Oriented Search: Skills, Companies, Events │
├────────────────────────────────────────────────────────────┤
│ 3. Restrained Filter Bar: All · Recent · Follow-ups · AI · │
│    Founders · DeepTech & Hardware                          │
├────────────────────────────────────────────────────────────┤
│ 4. Recently Interacted Section (Default View Carousel)     │
│    • Avatars + Roles + Companies + Last Interaction Date   │
├────────────────────────────────────────────────────────────┤
│ 5. Relationship-Aware Person Cards Grid / List             │
│    • Initials Avatar + Full Name + Role @ Company          │
│    • Location/Event Tag + Context Snippet                  │
│    • Actionable Follow-up Banner (I PROMISED / Due Date)   │
│    • Top Capability Tags + Interaction Count Badge         │
└────────────────────────────────────────────────────────────┘
```

---

## 3. Component Composition & File Structure

```
lib/
├── features/
│   └── people/
│       ├── models/
│       │   ├── person_item.dart        # Domain models (PersonItem, PeopleFilterOption, RelationshipContextType)
│       │   └── people_mock_data.dart   # Deterministic isolated mock dataset (8 rich professional profiles)
│       └── widgets/
│           ├── people_header.dart      # Title & network count badge
│           ├── people_search.dart      # Relationship search field
│           ├── people_filters.dart     # Horizontal chip filter bar
│           ├── recently_interacted.dart# Key contacts horizontal carousel
│           ├── person_card.dart        # Relationship-aware person card
│           └── people_empty_state.dart # Global empty & search-empty state handler
└── screens/
    └── people/
        └── people_screen.dart          # Stateful directory orchestrator & responsive grid builder
```

---

## 4. State Architecture & Lifecycle

The People directory manages five distinct runtime states:

| State | Trigger | Presentation | User Recovery / Action |
|---|---|---|---|
| **Loading** | `isLoading == true` | Structured `RecallrSkeleton` placeholders with exact card geometry | Shimmer animation indicates network/local sync |
| **Populated** | Default | Full People directory with Search, Filters, and Recently Interacted section | Instant query filtering, 1-tap route to dossier |
| **Search Empty** | Query/filter yields 0 matches | Reassuring `PeopleEmptyState(isSearch: true)` | *"Clear Search & Filters"* CTA resets search & filter |
| **Global Empty** | `isEmpty == true` | Onboarding `PeopleEmptyState(isSearch: false)` | *"Capture First Person"* CTA invokes `CaptureModal` |
| **Error** | `isError == true` | Inline `RecallrErrorState` container with crimson alert border | *"Retry"* action invoking onRetry callback |

---

## 5. Responsive Multi-Device Architecture

People screen seamlessly adapts across all viewport breakpoints using `LayoutBuilder`:

### 5.1 Mobile (< 720dp)
* **Single-Column Sequential Flow:** Vertically optimized card stream with 16dp horizontal padding.
* **Recently Interacted Carousel:** Horizontal swipeable cards (220dp width) sitting cleanly above directory.
* **Touch Targets:** All interactive cards, filters, and clear buttons strictly $\ge 48\text{dp}$.

### 5.2 Tablet & Desktop ($\ge 720\text{dp}$)
* **2-Column Responsive Card Grid:** Balanced master directory distributing person cards into two columns.
* **Max-Width Constraint:** Constrained to 1040dp on ultrawide displays to preserve readability and optical line length.

---

## 6. Integration Contracts

* **Parametric Person Routing:** Tapping any person card or recently interacted card executes `Navigator.pushNamed(context, '/person/:id')` (e.g. `/person/per_301`).
* **Capture Affordance:** Tapping `Capture First Person` on the global empty state invokes `RecallrBottomSheet.show(context: context, child: const CaptureModal())` directly without mutating shell navigation.
* **Search & Filter Pipeline:** Client-side real-time filtering matches name, company, role, location, context snippets, and capability tags with zero latency.

---

## 7. Quality & Verification Record

### Automated Testing Matrix (`test/people_screen_test.dart` + `test/home_screen_test.dart` + `test/routing_test.dart`)

```
00:00 +0: loading C:/workflow/testapp/test/home_screen_test.dart
00:00 +0: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders all populated sections correctly on mobile
00:00 +1: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders all populated sections correctly on mobile
00:00 +2: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders all populated sections correctly on mobile
00:00 +3: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders all populated sections correctly on mobile
00:00 +4: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders all populated sections correctly on mobile
00:02 +5: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests renders populated directory correctly on mobile
00:02 +6: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests search card tap triggers navigation to Ask tab
00:02 +7: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests person card tap navigates to /person/:id
00:03 +8: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests person card tap navigates to /person/:id
00:03 +9: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests attention item tap triggers parametric route
00:04 +10: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests search query filters people correctly
00:04 +11: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests search query filters people correctly
00:04 +12: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders empty state when isEmpty is true
00:04 +13: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests filter selection filters people correctly
00:04 +14: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests filter selection filters people correctly
00:04 +15: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests filter selection filters people correctly
00:05 +16: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders 2-column layout on desktop viewports without overflow
00:05 +17: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests renders search-empty state when query matches no one
00:06 +18: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests renders empty onboarding state with Capture CTA when isEmpty is true
00:06 +19: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests renders loading skeleton when isLoading is true
00:06 +20: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests renders error state with retry action
00:06 +21: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests renders 2-column layout on desktop viewports without overflow
00:07 +22: All tests passed!
```

### Static Analysis (`flutter analyze`)
* **Errors:** 0
* **Warnings:** 0
* **Deprecation info notices:** 9 (`withOpacity` info notices only)