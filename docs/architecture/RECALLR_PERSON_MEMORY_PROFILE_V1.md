# Recallr — Phase 07 Person Memory Profile Architecture v1

**Status:** COMPLETE & VERIFIED  
**Version:** 1.0.0  
**Phase:** 07  
**Locked Reference:** Recallr UI Architecture v1, Recallr Design System v1, Recallr App Shell & Navigation v1, Recallr Home Command Center v1, Recallr People Intelligence v1  

---

## 1. Executive Summary & Core Objective

Phase 07 implements the **Person Detail / Relationship Memory Profile** (`/person/:id`) for Recallr. While Phase 06 allowed the user to **find** people in their network, Phase 07 lets them **understand a person deeply**.

When a user navigates to `/person/:id`, Recallr answers:

> **"Who is this person, what do I remember about them, how did we meet, what have we discussed, and what should I do next?"**

This experience is designed as a **grounded personal memory profile**, not a contact card, address book entry, or generic CRM dashboard.

---

## 2. Information Architecture & Hierarchy

```
┌────────────────────────────────────────────────────────────┐
│ 07.1 Profile Header                                        │
│ • Large Initials Avatar (RecallrAvatar)                    │
│ • Name + Role · Company + Location                         │
│ • Relationship Badge (COLLABORATOR / FOUNDER / etc.)       │
├────────────────────────────────────────────────────────────┤
│ 07.9 "Ask about {Name}" Contextual AI Card                 │
│ • Prompt Query Trigger Bar -> Grounded Memory Engine (/ask)│
│ • Contextual Prompt Suggestion Chips                       │
├────────────────────────────────────────────────────────────┤
│ 07.2 AI Relationship Summary                               │
│ • Briefing Narrative on who they are & how you know them   │
│ • Key Context Takeaways with AI Cyan markers               │
├────────────────────────────────────────────────────────────┤
│ 07.3 Relationship Intelligence Metrics                     │
│ • First Met · Last Interaction · Total Encounters          │
├────────────────────────────────────────────────────────────┤
│ 07.7 Active Commitments & Follow-ups                       │
│ • Directional Badge: [I PROMISED] / [THEY PROMISED]        │
│ • Commitment text + Countdown / Due Date                   │
├────────────────────────────────────────────────────────────┤
│ 07.4 Important Context & Capabilities                      │
│ • Expertise & Domain Skill Badges                          │
├────────────────────────────────────────────────────────────┤
│ 07.5 Interaction Timeline                                  │
│ • Chronological stream: Meetings, Voice Notes, Card Scans  │
│ • Subtitles, Dates, Key Discussion Takeaway Bullets        │
├────────────────────────────────────────────────────────────┤
│ 07.6 Key Memories & Verified Claims                        │
│ • Atomic claims with [VERIFIED] badges & source provenance │
├────────────────────────────────────────────────────────────┤
│ 07.8 Connected Network Entities                            │
│ • Organization (/company/:id) · Events (/event/:id)        │
│ • Attached Files (/file/:id) · Mutuals (/person/:id)       │
├────────────────────────────────────────────────────────────┤
│ 07.9 Person Actions                                        │
│ • Quick "Capture Encounter" CTA -> CaptureModal Sheet      │
└────────────────────────────────────────────────────────────┘
```

---

## 3. Component Hierarchy & File Structure

```
lib/
├── features/
│   └── person_detail/
│       ├── models/
│       │   ├── person_profile_model.dart     # Domain models (TimelineItem, MemoryItem, FollowUpItem, ConnectedEntity, PersonProfile)
│       │   └── person_profile_mock_data.dart # Isolated deterministic mock dataset (Priya Sharma, Vivek Raghavan, Dr. K.S. Rao, etc.)
│       └── widgets/
│           ├── person_profile_header.dart    # Avatar, title, role, company, location, badges
│           ├── ai_relationship_summary.dart  # Grounded contextual briefing container
│           ├── relationship_intelligence.dart# First met, last met, total interactions metrics
│           ├── ask_about_person_card.dart    # Contextual memory Q&A prompt bar & suggestions
│           ├── person_context_section.dart   # Expertise and capabilities badges
│           ├── person_timeline_section.dart  # Chronological stream of encounters & captures
│           ├── person_memories_section.dart  # Atomic memory claims with provenance
│           ├── person_follow_ups_section.dart# Pending commitments with direction badges
│           ├── connected_entities_section.dart# Connected Company, Events, Files, Mutuals
│           └── person_action_bar.dart        # Quick capture encounter action trigger
└── screens/
    └── person/
        └── person_detail_screen.dart         # Dossier orchestrator & responsive multi-column layout
```

---

## 4. State Architecture & Lifecycle

The Person Detail screen manages four lifecycle states:

| State | Condition | Presentation | User Recovery / Action |
|---|---|---|---|
| **Loading** | `isLoading == true` | `RecallrSkeleton` placeholders with exact header and section geometry | Calm shimmer indicator |
| **Populated** | Default | Complete 360-degree memory profile with responsive 2-column distribution | Instant interaction, memory navigation |
| **Missing Person (404)** | `_profile == null` | Person not found icon and message | *"Back to People"* CTA returns to directory |
| **Error** | `isError == true` | `RecallrErrorState` alert container | *"Retry"* action invoking reload callback |

---

## 5. Responsive Multi-Device Composition

### 5.1 Mobile (< 720dp)
* **Single-Column Narrative Flow:** Vertically stacked sections following a natural reading hierarchy (Header -> Ask -> Summary -> Intelligence -> Follow-ups -> Timeline -> Memories -> Entities -> Actions).
* **Touch Targets:** All interactive chips, timeline items, follow-ups, and action buttons adhere strictly to $\ge 48\text{dp}$.

### 5.2 Tablet & Desktop ($\ge 720\text{dp}$)
* **2-Column Balanced Dossier:**
  - **Top Banner:** Header + "Ask about {Person}" card spanning full width.
  - **Left Column (flex 1):** AI Summary + Relationship Intelligence + Active Commitments + Connected Entities.
  - **Right Column (flex 1):** Interaction Timeline + Key Memories + Capabilities + Person Actions.
* **Max-Width Constraint:** Constrained to 1040dp on ultrawide displays to preserve optimal typographical line lengths.

---

## 6. Key Integration Contracts

1. **"Ask about this person" Integration:**
   - Tapping the prompt search bar or any suggestion chip routes directly to `RecallrRoutes.ask` (`/ask`) with the query string passed as arguments, seamlessly connecting Person Memory to the Grounded Memory Engine without creating a parallel AI interface.
2. **Parametric Routing Contract:**
   - Mounted in `AppRouter` under parametric route `case 'person': return _buildRoute(PersonDetailScreen(personId: entityId), settings);`.
   - Cross-entity links inside dossier route to `/company/:id`, `/event/:id`, `/file/:id`, and `/follow-up/:id`.
3. **Capture Integration:**
   - Tapping *"Capture Encounter"* triggers `RecallrBottomSheet.show(context: context, child: const CaptureModal())` directly without breaking navigation context.

---

## 7. Verification Record

### Automated Tests (`test/person_detail_screen_test.dart` + `test/people_screen_test.dart` + `test/home_screen_test.dart` + `test/routing_test.dart`)

```
00:00 +0: loading C:/workflow/testapp/test/home_screen_test.dart
00:00 +0: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders all populated sections correctly on mobile
00:00 +1: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders all populated sections correctly on mobile
00:00 +2: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders all populated sections correctly on mobile
00:00 +3: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders all populated sections correctly on mobile
00:00 +4: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders all populated sections correctly on mobile
00:02 +5: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests renders populated directory correctly on mobile
00:03 +6: C:/workflow/testapp/test/person_detail_screen_test.dart: PersonDetailScreen Phase 07 Tests renders all memory profile sections correctly on mobile
00:03 +7: C:/workflow/testapp/test/person_detail_screen_test.dart: PersonDetailScreen Phase 07 Tests renders all memory profile sections correctly on mobile
00:03 +8: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests person card tap navigates to /person/:id
00:03 +9: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests person card tap navigates to /person/:id
00:03 +10: C:/workflow/testapp/test/person_detail_screen_test.dart: PersonDetailScreen Phase 07 Tests prompt chip in Ask About Person card navigates to /ask
00:04 +11: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests attention item tap triggers parametric route
00:04 +12: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests search query filters people correctly
00:04 +13: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests search query filters people correctly
00:04 +14: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests search query filters people correctly
00:04 +15: C:/workflow/testapp/test/person_detail_screen_test.dart: PersonDetailScreen Phase 07 Tests connected entity tap navigates to target route
00:04 +16: C:/workflow/testapp/test/person_detail_screen_test.dart: PersonDetailScreen Phase 07 Tests connected entity tap navigates to target route
00:05 +17: C:/workflow/testapp/test/person_detail_screen_test.dart: PersonDetailScreen Phase 07 Tests connected entity tap navigates to target route
00:05 +18: C:/workflow/testapp/test/person_detail_screen_test.dart: PersonDetailScreen Phase 07 Tests connected entity tap navigates to target route
00:05 +19: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests filter selection filters people correctly
00:05 +20: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders 2-column layout on desktop viewports without overflow
00:05 +21: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders 2-column layout on desktop viewports without overflow
00:06 +22: C:/workflow/testapp/test/home_screen_test.dart: HomeScreen Phase 05 Tests renders 2-column layout on desktop viewports without overflow
00:06 +23: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests renders search-empty state when query matches no one
00:06 +24: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests renders search-empty state when query matches no one
00:06 +25: C:/workflow/testapp/test/person_detail_screen_test.dart: PersonDetailScreen Phase 07 Tests renders 2-column layout on desktop viewports without overflow
00:06 +26: C:/workflow/testapp/test/person_detail_screen_test.dart: PersonDetailScreen Phase 07 Tests renders 2-column layout on desktop viewports without overflow
00:06 +27: C:/workflow/testapp/test/person_detail_screen_test.dart: PersonDetailScreen Phase 07 Tests renders 2-column layout on desktop viewports without overflow
00:06 +28: C:/workflow/testapp/test/person_detail_screen_test.dart: PersonDetailScreen Phase 07 Tests renders 2-column layout on desktop viewports without overflow
00:07 +29: C:/workflow/testapp/test/people_screen_test.dart: PeopleScreen Phase 06 Tests renders 2-column layout on desktop viewports without overflow
00:07 +30: All tests passed!
```

### Static Analysis (`flutter analyze`)
* **Errors:** 0
* **Warnings:** 0
* **Deprecation info notices:** 9 (`withOpacity` info notices only)