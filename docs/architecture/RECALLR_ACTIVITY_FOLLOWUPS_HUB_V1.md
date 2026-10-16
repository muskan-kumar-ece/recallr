# RECALLR — ACTIVITY & FOLLOW-UPS HUB V1
**Status**: COMPLETE & VERIFIED  
**Phase**: Phase 09  
**Version**: 1.0.0  
**Stack**: Flutter 3.47.1 · Dark-First Pro Design Tokens · Material 3 Customized  

---

## 1. Executive Summary & Philosophy

The **Activity & Follow-ups Hub** is the operational command center for Recallr. While the People Directory helps users *find* people, and the Person Profile helps users *understand* them, the Activity Hub answers the immediate professional network questions:

> **"What do I need to act on in my network right now?"**  
> **"What promises did I make, and what did others commit to me?"**  
> **"What happened recently across my encounters?"**  
> **"What AI-derived memories require my human verification?"**

### Anti-CRM & Anti-Slop Principles
1. **Not a Generic Task Manager**: We do not treat relationship commitments as arbitrary to-do lists. Commitments are tied to real people, real conversations, and conversational provenance.
2. **"I Promised" vs "They Promised"**: Symmetrical accountability. A user must easily distinguish their own promises from commitments made by founders, leads, or investors.
3. **AI Proposes · Human Verifies**: AI-extracted facts and claims are not blindly added to the graph as authoritative truth. They enter a verification queue where users confirm or dispute them with 1 tap.
4. **Calm, Transparent System Sync**: Offline-first local storage metrics and cloud sync state are displayed calmly without intrusive alerts.

---

## 2. Information Architecture

```text
PHASE 09 — ACTIVITY & FOLLOW-UPS HUB
│
├── 09.1 Activity Header
│   ├── Headline ("Activity")
│   ├── Contextual Subtitle
│   └── System Sync Badge ([SYNCED], [SYNCING], [3 PENDING])
│
├── 09.2 Follow-ups & Commitments
│   ├── Direction Segments ([I PROMISED] / [THEY PROMISED])
│   ├── Status Filter Chips (All, Due Today, Overdue, Upcoming, Completed)
│   ├── Commitment Card
│   │   ├── Direction Tag ([I OWE] / [THEY OWE])
│   │   ├── Status Badge ([DUE TODAY], [OVERDUE], [UPCOMING], [WAITING], [COMPLETED])
│   │   ├── Action Title (Tappable -> /follow-up/:id)
│   │   ├── Person & Company Link (Tappable -> /person/:id)
│   │   ├── Due Date & Creation Context Snippet
│   │   └── Optimistic Checkbox Completion Toggle
│   └── Empty State
│
├── 09.3 Memory Review & Verification Queue
│   ├── Section Header + Pending Count Badge
│   ├── Subtitle ("AI proposes. You verify. Unconfirmed claims remain unverified.")
│   ├── Memory Review Card
│   │   ├── Person & Company Link (-> /person/:id)
│   │   ├── AI-Proposed Memory Claim Box
│   │   ├── Source Provenance & Encounter Date
│   │   ├── [VERIFY] Action (Optimistically marks verified in Emerald)
│   │   └── [DISPUTE] Action (Optimistically marks disputed in Crimson)
│   └── Empty State ("All memories verified")
│
├── 09.4 Recent Interactions & Timeline Feed
│   ├── Section Header + Count Badge
│   ├── Activity Feed Card
│   │   ├── Activity Type Icon (Meeting, Call, Card OCR, File, Promise, Verified)
│   │   ├── Type Badge + Relative Timestamp (e.g. "2 hours ago")
│   │   ├── Title & Description Excerpt
│   │   ├── Person & Company Tag (Tappable)
│   │   └── Navigation (-> /interaction/:id, /person/:id, /file/:id, etc.)
│   └── Empty State
│
└── 09.5 Local Cache & Cloud Sync Status
    ├── Icon & Title ("Local Cache & Cloud Sync")
    ├── Sync Status Badge ([SYNCED], [SYNCING], [OFFLINE], [PENDING])
    ├── Cache Size & Last Synced Timestamp
    └── "Sync Now" Manual Trigger
```

---

## 3. Data Architecture & Domain Models

Located in `lib/features/activity/models/activity_models.dart`:

```dart
/// Direction of follow-up commitment
enum FollowUpDirection { iPromised, theyPromised }

/// Status of follow-up commitment
enum FollowUpStatus { overdue, dueToday, upcoming, waiting, completed }

/// Activity Follow-up Model
class ActivityFollowUp {
  final String id;
  final String personId;
  final String personName;
  final String? personRole;
  final String? company;
  final FollowUpDirection direction;
  final String title;
  final String dueDate;
  final FollowUpStatus status;
  final String createdDate;
  final String? relatedInteractionId;
  final String? provenance;
  final bool isCompleted;
  final String? targetRoute;
}

/// Chronological Interaction Type
enum ActivityType {
  meeting, call, message, businessCard, note,
  fileAttached, followUpCreated, memoryVerified, memoryDisputed,
}

/// Activity Interaction Model
class ActivityInteraction {
  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final String? personId;
  final String? personName;
  final String? company;
  final String timestamp;
  final String targetRoute;
  final String? badgeText;
}

/// Memory Review State
enum MemoryReviewState { pending, verified, disputed }

/// Memory Review Claim Model
class MemoryReviewItem {
  final String id;
  final String personId;
  final String personName;
  final String company;
  final String claim;
  final String sourceType;
  final String sourceDate;
  final String provenance;
  final String? confidence;
  final MemoryReviewState state;
  final String? targetRoute;
}

/// Cloud Sync Status Model
class ActivitySyncStatus {
  final SyncMode mode;
  final String title;
  final String description;
  final String lastSyncedTime;
  final int pendingCount;
  final String cacheSize;
}
```

---

## 4. UI Component Architecture

Located in `lib/features/activity/widgets/`:

| Component | Responsibility |
|---|---|
| `ActivityHeader` | Editorial sans-serif header with title, subtitle, and dynamic system sync badge. |
| `FollowUpsSection` | Segmented controller (`[I PROMISED]` vs `[THEY PROMISED]`), filter chips, and animated follow-ups list. |
| `FollowUpCard` | High-clarity commitment card with status badge, direction indicator, person link, due date, and completion checkbox. |
| `MemoryReviewSection` | Queue container for AI-extracted memory claims awaiting user verification. |
| `MemoryReviewCard` | AI memory claim card with quote box, source provenance, and interactive `[VERIFY]` / `[DISPUTE]` buttons. |
| `RecentInteractionsFeed`| Chronological timeline feed of meetings, calls, scanned business cards, and attachments. |
| `ActivityFeedCard` | Timeline card with type-specific color accents, timestamps, descriptions, and parametric deep-linking. |
| `SyncStatusCard` | System storage and cloud sync status card with cache size, timestamp, and manual "Sync Now" action. |

---

## 5. Responsive Layout Strategy

- **Mobile Phones (< 720dp)**:
  - Single-column continuous scrolling flow.
  - Pull-to-refresh (`RefreshIndicator`) triggering cloud sync.
  - Hierarchy: Header $\rightarrow$ Sync Card $\rightarrow$ Follow-ups Section $\rightarrow$ Memory Review Queue $\rightarrow$ Recent Interactions Feed.
- **Tablets & Desktop ($\ge 720\text{dp}$)**:
  - Constrained centered container (max width: `1040dp`).
  - Balanced 2-column command center layout:
    - **Left Column (flex: 1)**: Follow-ups & Commitments + Memory Review & Verification Queue.
    - **Right Column (flex: 1)**: Local Cache & Cloud Sync Status + Chronological Recent Interactions Feed.
  - Zero horizontal overflow across all tested breakpoints: 360dp, 390dp, 430dp, 768dp, 1024dp, 1440dp.

---

## 6. Verification & Test Suite

Tested in `test/activity_screen_test.dart`:
1. `Header renders title and sync status badge` — **PASSED**
2. `I PROMISED segment renders with commitments` — **PASSED**
3. `THEY PROMISED segment switch displays others promises` — **PASSED**
4. `Due-today follow-up renders with DUE TODAY badge` — **PASSED**
5. `Overdue follow-up renders with OVERDUE badge` — **PASSED**
6. `Upcoming follow-up renders with UPCOMING badge` — **PASSED**
7. `Follow-up card tap navigates to target route` — **PASSED**
8. `Person name tap in follow-up navigates to /person/:id` — **PASSED**
9. `Follow-up completion checkbox toggles status optimistically` — **PASSED**
10. `Recent interaction feed renders activity items` — **PASSED**
11. `Interaction item tap navigates to target route` — **PASSED**
12. `Memory review queue renders pending claims` — **PASSED**
13. `Verify button marks claim as verified optimistically` — **PASSED**
14. `Dispute button marks claim as disputed optimistically` — **PASSED**
15. `Status filter chips filter follow-ups list` — **PASSED**
16. `Empty follow-up state renders when empty` — **PASSED**
17. `Empty memory review section state renders when items empty` — **PASSED**
18. `Loading state renders skeleton placeholders` — **PASSED**
19. `Error state renders with message and retry callback` — **PASSED**
20. `Sync status card renders metrics and triggers sync action` — **PASSED**
21. `Responsive layouts render across all breakpoints without overflow` — **PASSED**

**Full Test Suite Results**: `65 / 65 tests passed (100%)`  
**Flutter Analyze**: `0 errors · 0 warnings · 0 issues`