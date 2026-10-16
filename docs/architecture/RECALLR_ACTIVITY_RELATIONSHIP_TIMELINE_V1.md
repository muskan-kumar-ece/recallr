# Recallr Activity / Relationship Timeline Architecture v1

**Status**: LOCKED & VERIFIED  
**Version**: 1.0.0  
**Phase**: 09 — Activity / Relationship Timeline  
**Verification**: 100% Passing (64/64 Flutter Tests Passed, `flutter analyze` 0 warnings/0 errors)

---

## 1. Core Mission & Philosophy

Recallr is an **AI Personal Professional Network Memory Engine**. The Activity screen represents Recallr's **chronological memory layer**, directly answering:

> **"What happened across my professional network?"**

It is **NOT**:
- A generic task manager or to-do list
- A CRM activity dashboard or sales pipeline
- A notification center or alert stream
- A generic SaaS analytics page

It operates along the core pipeline:
CAPTURE -> UNDERSTAND -> REMEMBER -> TIMELINE -> RELATIONSHIP CONTEXT -> ACTION

---

## 2. Information Architecture & Structural Hierarchy

The Activity screen follows a focused, information-dense, editorial layout:

```
ACTIVITY / RELATIONSHIP TIMELINE
│
├── 1. Activity Header
│   ├── Editorial Title ("Activity")
│   └── Subtitle ("Your professional memory, in chronological context.")
│
├── 2. Search & Category Filters
│   ├── Pill Search Field ("Search your activity...")
│   │   ├── Leading Search Icon & Reactive Text Filtering
│   │   └── Trailing Clear Button (Interactive close icon)
│   └── Horizontal Filter Chips
│       ├── All
│       ├── People
│       ├── Meetings
│       ├── Calls
│       ├── Notes
│       ├── Captures
│       ├── Files
│       └── Follow-ups
│
├── 3. Chronological Timeline Stream
│   ├── Group 1: TODAY
│   ├── Group 2: YESTERDAY
│   ├── Group 3: THIS WEEK
│   └── Group 4: EARLIER
│
├── 4. Activity Cards (Atomic Memory Units)
│   ├── Activity Type Icon & Badge (Meeting, Encounter, Call, Note, Capture, File, Follow-up, Company Update)
│   ├── Commitment Indicator / Due Date Badge (e.g., "DUE TODAY", "OVERDUE")
│   ├── Verification Status Indicator (Verified Emerald checkmark)
│   ├── Relative/Absolute Timestamp (JetBrains Mono / System Monospace)
│   ├── Linked Person & Company Header with Gradient Avatar
│   ├── Title & Context Summary (High-contrast typography)
│   ├── Metadata Chips (Location pin, Network relationship status)
│   └── Primary Action CTA Button (e.g., "View Memory", "View Person", "Open Follow-up", "View File", "View Company")
│
├── 5. Tablet & Desktop Relationship Context Inspector (>= 720dp)
│   ├── Sticky Right Column Inspector
│   ├── Person Profile Context Card (Avatar, Name, Role @ Company)
│   ├── Full Encounter Summary & AI Context
│   ├── Encounter Metadata Matrix (Timestamp, Location, Status, Commitments)
│   └── Multi-Action CTA Buttons ("View Dossier", "Open Memory")
│
└── 6. System States
    ├── Loading State (RecallrSkeleton matched to timeline geometry)
    ├── Error State (RecallrErrorState with retry handler)
    ├── Search-Empty State ("No activity matches this search." + "Clear Search & Filters" CTA)
    └── Full-Empty State ("Your professional timeline is still quiet." + "Capture First Encounter" CTA)
```

---

## 3. Activity Type Classification & Semantic Styling

| Activity Type | Icon | Accent Color | Primary Action CTA | Target Route |
| :--- | :--- | :--- | :--- | :--- |
| **`meeting`** | `Icons.visibility_outlined` | `RecallrColors.aiElectricViolet` | *"View Memory"* | `/interaction/:id` |
| **`encounter`** | `Icons.person_outline_rounded` | `RecallrColors.aiCyanHighlight` | *"View Person"* | `/person/:id` |
| **`call`** | `Icons.phone_outlined` | `RecallrColors.aiCyanHighlight` | *"View Memory"* | `/interaction/:id` |
| **`note`** | `Icons.article_outlined` | `RecallrColors.textSecondary` | *"View Memory"* | `/interaction/:id` |
| **`capture`** | `Icons.badge_outlined` | `RecallrColors.warmAmberGold` | *"View Person"* | `/person/:id` |
| **`file`** | `Icons.attach_file_rounded` | `RecallrColors.aiCyanHighlight` | *"View File"* | `/file/:id` |
| **`followUp`** | `Icons.task_alt_rounded` | `RecallrColors.warmAmberGold` | *"Open Follow-up"* | `/follow-up/:id` |
| **`companyUpdate`** | `Icons.business_outlined` | `RecallrColors.aiElectricViolet` | *"View Company"* | `/company/:id` |

---

## 4. Responsive Layout Architecture

- **Mobile Viewport (`< 720dp`)**: Single-column vertical scroll with balanced insets (`RecallrSpacing.pagePadding`).
  - Search bar + horizontal category filter chips.
  - Chronological grouped timeline with full-width cards.
  - Tapping a card or its action button navigates directly to the target route (`/person/:id`, `/interaction/:id`, etc.).

- **Tablet & Desktop Viewport (`>= 720dp`)**: 2-Column balanced layout:
  - **Left Column (`flex: 6`)**: Search bar, filter chips, chronological grouped timeline. Tapping any card updates the active selection (`_selectedActivityId`).
  - **Right Column (`flex: 4`)**: Sticky **Relationship Context Inspector** (`ActivityDetailContext`), displaying rich relationship intelligence, encounter metadata matrix, and direct access to full dossiers.

---

## 5. Verification & Test Coverage Matrix

The Phase 09 test suite (`test/activity_screen_test.dart`) covers all 20 required unit and widget scenarios:

1. **Populated Timeline Rendering**: Verifies chronological grouping headers (`TODAY`, `YESTERDAY`, `THIS WEEK`, `EARLIER`) and activity cards.
2. **Editorial Header**: Verifies headline ("Activity") and subtitle ("Your professional memory, in chronological context.").
3. **Pill Search Bar**: Verifies text field placeholder and visual hierarchy.
4. **Category Filter Chips**: Verifies all 8 filter categories are rendered.
5. **Category Filtering**: Verifies selecting *Meetings* isolates meetings and hides files/notes.
6. **Search Query Filtering**: Verifies keyword search across titles, summaries, person names, companies, and locations.
7. **Search-Empty State**: Verifies empty state when no activities match query and verifies *"Clear Search & Filters"* button.
8. **Complete Empty State**: Verifies empty state when the entire activity stream is empty.
9. **Capture CTA in Empty State**: Verifies *"Capture First Encounter"* triggers quick capture modal.
10. **Loading State**: Verifies skeleton loading placeholders.
11. **Error State**: Verifies `RecallrErrorState` rendering and retry execution.
12. **Person Navigation**: Verifies tapping person encounters/cards navigates to `/person/:id`.
13. **Follow-Up Navigation**: Verifies tapping follow-up action buttons navigates to `/follow-up/:id`.
14. **Interaction Navigation**: Verifies tapping interaction action buttons navigates to `/interaction/:id`.
15. **File Navigation**: Verifies tapping file action buttons navigates to `/file/:id`.
16. **Company Navigation**: Verifies tapping company action buttons navigates to `/company/:id`.
17. **Viewport Responsiveness**: Verifies 0 overflow across 360dp, 390dp, 430dp, 768dp, 1024dp, 1440dp.
18. **Desktop Inspector Rendering**: Verifies relationship context inspector on wide viewports.
19. **Desktop Selection State**: Verifies tapping activity cards updates the inspector selection.
20. **Search Clear Icon**: Verifies reactive search bar clear button.