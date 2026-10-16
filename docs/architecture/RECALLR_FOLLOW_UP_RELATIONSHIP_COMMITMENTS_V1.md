# Recallr Follow-up & Relationship Commitments Architecture v1

**Status**: LOCKED & VERIFIED  
**Version**: 1.0.0  
**Phase**: 10 — Follow-ups / Relationship Commitments  
**Verification**: 100% Passing (87/87 Flutter Tests Passed, `flutter analyze` 0 warnings/0 errors)

---

## 1. Core Mission & Philosophy

Recallr is an **AI Personal Professional Network Memory Engine**. The Follow-ups & Relationship Commitments module represents Recallr's **"Act" layer**, grounded in authentic relationship memory.

It directly answers:

> **"What did I promise, what did they promise, and what needs my attention across my relationships?"**

It is **NOT**:
- A generic to-do list or task manager
- A CRM sales pipeline or lead tracker
- A detached notification center or reminder utility

It operates along the core pipeline:
CAPTURE -> UNDERSTAND -> REMEMBER -> ACT

---

## 2. Commitment Types & Semantic Visual Hierarchy

| Commitment Type | Enum Key | Visual Badge | Icon | Design Token Accent | Semantic Meaning |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **I Promised** | `iPromised` | `I PROMISED` | `Icons.assignment_late_outlined` | `RecallrColors.warmAmberGold` | Commitments made by the user to a professional contact |
| **They Promised** | `theyPromised` | `THEY PROMISED` | `Icons.reply_outlined` | `RecallrColors.aiElectricViolet` | Commitments or deliverables promised to the user by a contact |
| **Follow-up** | `followUp` | `FOLLOW-UP` | `Icons.alarm_on_outlined` | `RecallrColors.aiCyanHighlight` | General relationship cadence and scheduled check-ins |
| **Waiting** | `waiting` | `WAITING` | `Icons.hourglass_top_rounded` | `RecallrColors.textSecondary` | Items blocked on external response or confirmation |
| **Overdue** | `overdue` | `OVERDUE` | `Icons.error_outline_rounded` | `RecallrColors.crimsonAlert` | Commitments past their scheduled due date needing immediate action |

---

## 3. Information Architecture & Structural Hierarchy

```
FOLLOW-UPS & RELATIONSHIP COMMITMENTS HUB
│
├── 1. Follow-up Header
│   ├── Editorial Title ("Follow-ups")
│   └── Subtitle ("What needs your attention across your relationships?")
│
├── 2. Relationship Commitments Summary Strip
│   ├── Today (Count with Warm Amber accent, interactive filter trigger)
│   ├── Upcoming (Count with AI Cyan accent, interactive filter trigger)
│   ├── Waiting (Count with AI Electric Violet accent, interactive filter trigger)
│   └── Overdue (Count with Crimson Alert accent, interactive filter trigger)
│
├── 3. Search & Category Filters
│   ├── Pill Search Field ("Search commitments & follow-ups...")
│   │   ├── Leading Search Icon & Reactive Query Matching
│   │   └── Trailing Clear Button
│   └── Horizontal Filter Chips
│       ├── All
│       ├── Due Today
│       ├── Upcoming
│       ├── Waiting
│       ├── Overdue
│       └── Completed
│
├── 4. Grouped Commitment Sections
│   ├── Group 1: NEEDS ATTENTION (Due Today, Overdue, or I Promised active items)
│   ├── Group 2: WAITING ON OTHERS (They Promised or Waiting active items)
│   ├── Group 3: UPCOMING (Upcoming scheduled follow-ups)
│   └── Group 4: COMPLETED (Completed commitments with strikethrough & timestamp)
│
├── 5. Follow-up Cards (Atomic Commitment Units)
│   ├── Commitment Badge + Due Date / Relative Timing Chip + Verification Dot
│   ├── Person Avatar Link (Initials with gradient, Name · Role @ Company)
│   ├── Commitment Title & Context Description
│   ├── Source Memory Provenance Tag ("From: Origin Encounter · Date")
│   └── Action Buttons (Optimistic Complete toggle, Open Memory CTA)
│
├── 6. Tablet & Desktop Relationship Context Inspector (>= 720dp)
│   ├── Sticky Right Column Inspector
│   ├── Person Dossier Summary Card with direct navigation
│   ├── Full Commitment Context & AI Rationale
│   ├── Origin Encounter Metadata Matrix (Timing, Origin, Location, Priority)
│   └── Action Row ("Complete", "View Full Dossier", "Source Interaction")
│
└── 7. System States
    ├── Loading State (RecallrSkeleton matched to summary & card geometry)
    ├── Error State (RecallrErrorState with retry handler)
    ├── Search-Empty State ("No follow-ups match your filters." + "Clear Search & Filters" CTA)
    └── Full-Empty State ("No follow-ups yet" + "Capture First Encounter" CTA)
```

---

## 4. Responsive Layout Architecture

- **Mobile Viewport (`< 720dp`)**: Single-column vertical flow with balanced touch targets:
  - Metric summary cards (2x2 responsive grid on compact screens).
  - Search bar + horizontal scrollable filter chips.
  - Categorized grouped commitment sections with full-width cards.
  - Optimistic in-place completion toggle with instant visual feedback.

- **Tablet & Desktop Viewport (`>= 720dp`)**: 2-Column balanced layout:
  - **Left Column (`flex: 6`)**: Summary strip, search field, category filter chips, and categorized commitment groups. Selecting any card highlights the active item (`_selectedFollowUpId`).
  - **Right Column (`flex: 4`)**: Sticky **Relationship Context Inspector** (`FollowUpDetailContext`), displaying full relationship memory, person dossier shortcuts, origin encounter excerpts, and multi-action buttons.

---

## 5. Verification & Test Coverage Matrix

The Phase 10 test suite (`test/follow_ups_screen_test.dart`) covers all 23 dedicated unit and widget test cases:

1. **Populated Follow-ups Rendering**: Verifies grouped commitment sections and cards render accurately.
2. **Summary Metrics Strip**: Verifies counts for Today, Upcoming, Waiting, and Overdue.
3. **Filter Chips Rendering**: Verifies all 6 filter category chips render.
4. **Search Query Filtering**: Verifies keyword search across titles, contexts, person names, companies, and badges.
5. **I PROMISED Badges**: Verifies `I PROMISED` commitments render with correct visual styling.
6. **THEY PROMISED Badges**: Verifies `THEY PROMISED` commitments render with correct visual styling.
7. **OVERDUE Badges**: Verifies `OVERDUE` commitments render with crimson alert styling.
8. **WAITING Badges**: Verifies `WAITING` commitments render with waiting styling.
9. **COMPLETED Items**: Verifies completed items render in the completed group.
10. **Person Navigation**: Verifies tapping person name on card navigates to `/person/:id`.
11. **Source Memory Navigation**: Verifies tapping *Open Memory* navigates to source interaction.
12. **Context Inspector Source Navigation**: Verifies tapping *Source Interaction* from inspector navigates to `/interaction/:id`.
13. **Optimistic Completion Toggle**: Verifies tapping *Complete* toggles completion state and updates styling.
14. **Full Empty State**: Verifies empty state when there are no follow-ups.
15. **Search-Empty State**: Verifies search-empty state and *"Clear Search & Filters"* recovery button.
16. **Loading State**: Verifies skeleton loading placeholders.
17. **Error State**: Verifies `RecallrErrorState` rendering and retry execution.
18. **Capture CTA in Empty State**: Verifies *"Capture First Encounter"* triggers quick capture callback.
19. **Mobile Layout**: Verifies single-column layout without overflow on mobile viewports (< 720dp).
20. **Tablet Layout**: Verifies 2-column balanced layout with context inspector on tablet viewports (768dp).
21. **Desktop Layout**: Verifies 2-column layout with inspector on desktop viewports (1024dp, 1440dp).
22. **Viewport Responsiveness**: Verifies 0 RenderFlex overflow across 360dp, 390dp, 430dp, 768dp, 1024dp, 1440dp.
23. **Summary Metric Tap Filtering**: Verifies tapping a metric card activates the corresponding filter.

---

## 6. Architectural Safety Checks & System Integrity

- **4-Tab Navigation Unchanged**: Persistent tabs (`Home`, `People`, `Ask`, `Activity`) remain intact.
- **Global Capture Intact**: Quick capture is accessible via global floating action and bottom sheet.
- **Parametric Routing Preserved**: `/follow-up/:id` routes directly into `FollowUpsScreen(initialFollowUpId: id)`.
- **Zero Duplicate Architecture**: Strict reuse of `RecallrColors`, `RecallrTypography`, `RecallrSpacing`, `RecallrRadii`, `RecallrCard`, `RecallrBadge`, `RecallrAvatar`, `RecallrButton`, `RecallrSkeleton`, and `RecallrErrorState`.