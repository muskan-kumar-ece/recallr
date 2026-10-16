# Recallr Person / Relationship Memory Detail Architecture v1

**Status**: LOCKED & VERIFIED  
**Version**: 1.0.0  
**Phase**: 12 — Person / Relationship Memory Detail  
**Verification**: 100% Passing (123/123 Flutter Tests Passed, `flutter analyze` 0 warnings/0 errors)

---

## 1. Executive Summary & Product Mission

Recallr is an **AI Personal Professional Network Memory Engine**. The Person / Relationship Memory Detail surface (`PersonDetailScreen`) answers the central question:

> **"Everything Recallr remembers about this person."**

This is **NOT a generic CRM contact page** or address book. It is a relationship-memory intelligence surface where the user can immediately understand:
- Who this person is and their verified identity
- How and where they met (first encounter & provenance)
- What was discussed across interactions
- What structured intelligence Recallr knows (capabilities, interests, recurring topics, communication preferences)
- Previous chronological memories (meetings, calls, voice memos, card scans)
- Relationship commitments (*I Promised* vs *They Promised*)
- Connected network entities (Companies, Events, Files, Related People)
- Associated evidence (scanned cards, documents, transcripts)
- What should happen next ([Ask Recallr], [Capture Encounter])

---

## 2. Locked Information Architecture

```
PERSON MEMORY DETAIL (PersonDetailScreen)
│
├── 1. Person Header (PersonProfileHeader)
│   ├── Back Button (Returns to People directory)
│   ├── Relationship Badge (COLLABORATOR, FOUNDER, INVESTOR, ADVISOR, etc.)
│   ├── Avatar with Initials & Gradient
│   ├── Verified Identity Checkmark
│   ├── Role, Company & Geographic Location
│   └── Quick Action Bar ([Ask Recallr], [Capture])
│
├── 2. Relationship Snapshot (RelationshipIntelligence)
│   ├── First Met Fact Pill (Encounter & Date)
│   ├── Last Interaction Fact Pill
│   ├── Interactions Count & Shared Events Count
│   └── Relationship Strength Bar
│
├── 3. "Ask About {Person}" Card (AskAboutPersonCard)
│   ├── Natural Language Prompt Input Bar
│   └── Suggested Grounded Query Chips (e.g. "What did we discuss about RISC-V quantization?")
│
├── 4. Partial / Missing Context Notice (when applicable)
│   └── Honest Notice ("Recallr has this person's identity, but there isn't enough conversation history yet.") + Capture CTA
│
├── 5. Memory Summary / What Recallr Knows (AiRelationshipSummary)
│   ├── Grounded AI Relationship Summary Narrative
│   └── Key Context Takeaway Bullet Points
│
├── 6. Expertise & Capabilities (PersonContextSection)
│   └── Structured Skill & Technical Domain Badges
│
├── 7. Interaction Timeline & Recent Memories (PersonTimelineSection)
│   ├── Chronological Encounters (Meetings, Voice Memos, Visiting Card Scans)
│   ├── Encounter Key Bullets & Discussion Context
│   └── Provenance Links to Source Memories (/interaction/:id, /file/:id)
│
├── 8. Active Commitments & Follow-ups (PersonFollowUpsSection)
│   ├── "I PROMISED" (Warm Amber)
│   ├── "THEY PROMISED" (AI Electric Violet)
│   ├── "WAITING" & "COMPLETED" (Verified Emerald)
│   └── Direct Navigation to /follow-up/:id
│
├── 9. Connected Network Entities (ConnectedEntitiesSection)
│   ├── Companies (/company/:id)
│   ├── Events (/event/:id)
│   ├── Files (/file/:id)
│   └── Mutual Contacts / Related People (/person/:id)
│
└── 10. Floating / Docked Action Bar (PersonActionBar)
    └── "Capture Encounter" Button (Opens canonical Omni-Capture Hub)
```

---

## 3. Responsive Layout Strategy

- **Mobile Viewports (< 720dp)**:
  - Single-column narrative stream: Header → Relationship Snapshot → Ask Card → What Recallr Knows → Timeline → Commitments → Connected Entities → Action Bar.
- **Tablet & Desktop Viewports ($\ge 720\text{dp}$)**:
  - Max container width constrained to **1040dp**.
  - **Left Column**: Identity & Summary, Relationship Snapshot, Expertise & Capabilities, Connected Network Entities.
  - **Right Column**: Interaction Timeline, Memories & Verified Claims, Active Commitments & Follow-ups, Action Bar.
- **Zero RenderFlex Overflow**:
  - Verified across 360dp, 390dp, 430dp, 768dp, 1024dp, and 1440dp viewports.

---

## 4. State Machine & Error Handling

1. **Loading State**: `RecallrSkeleton` shimmer placeholders for header, avatar, metadata, snapshot tiles, and cards.
2. **Populated State**: Full rich relationship dossier with multi-modal memories and interactive chips.
3. **Partial / Missing Context State**: Honest guidance with `Partial Memory Dossier` banner and *Capture First Encounter* CTA.
4. **Empty Relationship Memory State**: Graceful fallback when no historical encounters exist.
5. **Error State**: `RecallrErrorState` with retry button.
6. **Not Found State**: Clean "Person Not Found" screen with *Back to People* navigation.

---

## 5. Cross-System Integration & Provenance

- **Integration with Ask (`/ask`)**:
  - Header *[Ask Recallr]* and *AskAboutPersonCard* pass contextual queries into the Grounded Memory Engine.
- **Integration with Capture (`CaptureModal`)**:
  - Header *[Capture]* button and Action Bar *[Capture Encounter]* open the canonical Omni-Capture Hub.
- **Integration with Activity (`/interaction/:id`)**:
  - Timeline items reference canonical interaction IDs (`int_101`, `int_102`, `int_103`, `int_104`) with matching activity titles and timestamps.
- **Integration with Follow-ups (`/follow-up/:id`)**:
  - Commitments reference canonical follow-up IDs (`fol_101`, `fol_102`, `fol_103`, `fol_104`, `fol_105`, `fol_106`) with direction badges.
- **Integration with Files (`/file/:id`)**:
  - Scanned business cards and spec sheets link to file evidence.

---

## 6. Verification & Test Coverage Matrix

The Phase 12 test suite (`test/person_detail_screen_test.dart`) exercises 22 distinct test specifications:
1. Identity rendering (avatar, name, role, company, location, verified checkmark)
2. Relationship snapshot (first met, last interaction, total interactions, strength)
3. Memory summary (AI relationship summary, key takeaways)
4. Expertise & capabilities chips
5. Recent memory & interaction timeline
6. Active commitments (I Promised & They Promised)
7. Memories & context claims (evidence items)
8. Connected entities (Companies, Events, Files, Related People)
9. Prompt suggestion chip navigation to `/ask`
10. Header Ask Recallr button navigation to `/ask`
11. Header Capture button opens `CaptureModal`
12. Action Bar Capture Encounter opens `CaptureModal`
13. Follow-up item tap navigation to `/follow-up/:id`
14. Interaction timeline tap navigation to `/interaction/:id`
15. Connected entity tap navigation to target route
16. Loading state renders skeleton loaders
17. Error state renders error message and retry button
18. Not-found state renders not found message and back button
19. Partial profile renders missing context notice and Capture CTA
20. Empty profile renders without crashing
21. Desktop viewport renders 2-column layout without overflow
22. Responsive layouts render across 360dp, 390dp, 430dp, 768dp, 1024dp, 1440dp without overflow