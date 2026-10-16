# Recallr — Phase 02 UI Architecture v1
**System Blueprint: AI Personal Network Memory Frontend**

*Document Status:* **READY FOR FINAL LOCK**  
*Version:* `1.1.0` (Targeted Correction & Hardening Pass)  
*Target Framework:* Flutter (iOS, Android, Web) + Material 3 (Dark-First Custom Pro Theme)  
*Companion Backend:* Recallr Data & Memory Architecture v1 (LOCKED)  

---

## 1. UX Principles

Recallr is **not a CRM** and **not a bloated address book**. It is an **AI Personal Network Memory** engine.

```
       ┌─────────────────────────────────────────────────────────┐
       │                     THE RECALLR LOOP                    │
       │                                                         │
       │   [Capture]  ──>  [Understand] ──> [Remember]           │
       │      │                                  │               │
       │      ▼                                  ▼               │
       │   [Connect]  <─────────────────────── [Ask]             │
       └─────────────────────────────────────────────────────────┘
```

1. **Ambient & Frictionless (Capture First):**  
   Logging an encounter, snapping a visiting card, or recording a 15-second audio memo must take less than two taps from anywhere in the OS or application.
2. **Calm, Trustworthy Intelligence (No Chatbot Gimmicks):**  
   AI acts as an invisible, organized librarian. The UI rejects floating conversational widgets and generic sparkle animations in favor of clear provenance, high-density structured cards, and verifiable source citations.
3. **Contextual Discovery over Database Lists:**  
   Users do not manage databases of companies or files. Companies, events, and documents live as contextual hubs linked to People, accessible via search or profile exploration.
4. **Dark-First Premium Craft:**  
   Deep obsidian surfaces, crisp 1px subtle borders, refined editorial typography, and disciplined accents convey high-value professional software (inspired by Linear, Superhuman, and Apple).
5. **Zero-Latency Optimistic Feedback:**  
   Every local creation, edit, or verification updates immediately on-screen via local reactive state + native Cloud Firestore offline persistence.

---

## 2. Information Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              RECALLR INFORMATION ARCHITECTURE                           │
├──────────────────────────┬─────────────────────────────┬────────────────────────────────┤
│   PRIMARY NAVIGATION     │    CONTEXTUAL ENTITIES      │     MODAL / SHEET LAYERS       │
│      (Core Tabs)         │   (Reachable via Dossier)   │    (Transient Focus Flows)     │
├──────────────────────────┼─────────────────────────────┼────────────────────────────────┤
│ 1. Home (Command Hub)    │ • Company Dossier           │ • Global Omni-Capture Sheet    │
│ 2. People (Network A-Z)  │ • Event Dossier             │ • Business Card Camera Flow    │
│ 3. Center Capture (FAB)  │ • File Previewer            │ • Memory Verification Sheet    │
│ 4. Ask (Network Q&A)     │ • Career History Modal      │ • Add / Edit Follow-Up Modal   │
│ 5. Activity (Tasks&Logs) │ • Location Anchor           │ • Settings & Data Privacy      │
└──────────────────────────┴─────────────────────────────┴────────────────────────────────┘
```

### Navigation Tiering
* **Primary Navigation (3-4 Hubs + Center FAB):** Keeps the interface calm and thumb-friendly on mobile without CRM horizontal tab-sprawl.
* **Contextual Entities (Search & Profile Reachable):** `Company`, `Event`, and `FileAttachment` are not cluttered top-level tabs. They open as secondary dossiers when tapped within a Person Profile, Interaction summary, or Search result.
* **Modal / Sheet Layer:** Transient actions (Card scanning, Voice notes, Quick follow-up checks) slide up as glass bottom sheets, preserving background browsing context.

---

## 3. Navigation Architecture & Routing

### GoRouter Declarative Routing Hierarchy

```dart
/ (AuthGate Router)
│
├── /home                       (Tab 1: StatefulShellBranch - Command Center)
├── /people                     (Tab 2: StatefulShellBranch - Network Directory)
│   └── /:personId              (Person Dossier Stack Route)
│       ├── /company/:companyId (Contextual Company Dossier)
│       └── /event/:eventId     (Contextual Event Dossier)
├── /ask                        (Tab 3: StatefulShellBranch - Conversational Q&A)
├── /activity                   (Tab 4: StatefulShellBranch - Activity & Follow-ups Hub)
│
├── /capture                    (Modal Route: fullscreenDialog: true)
│   ├── /card-scanner           (Camera OCR Viewfinder)
│   └── /audio-recorder         (Voice Memo Recording Studio)
│
└── /settings                   (Modal Route: Data Privacy & Security)
```

### Deep Linking Scheme
* `recallr://person/:personId` — Direct navigation to contact dossier.
* `recallr://ask?q=...` — Pre-fills network Q&A query.
* `recallr://capture?mode=card|voice|text` — Instant OS shortcut capture launch.
---

## 4. App Shell & Adaptive Chrome

```
  MOBILE PHONE (< 600dp)            TABLET (600dp - 1024dp)         DESKTOP / WEB (> 1024dp)
┌──────────────────────────┐      ┌────┬─────────────────────┐    ┌──────────┬──────────┬──────────┐
│ AppBar (Search + Avatar) │      │ R  │ TopBar (Search)     │    │ Sidebar  │ Main     │ Dossier  │
├──────────────────────────┤      │ a  ├─────────────────────┤    │ (Nav +   │ Feed /   │ / AI     │
│                          │      │ i  │ Master-Detail Split │    │ Recents) │ Results  │ Context  │
│ Scrollable Content Area  │      │ l  │ [List | Dossier]    │    │          │          │ Panel    │
│                          │      │    │                     │    │          │          │          │
├──────────────────────────┤      │    │                     │    │          │          │          │
│ [H] [P]  ( + )  [A] [F]  │      │    │                     │    │          │          │          │
└──────────────────────────┘      └────┴─────────────────────┘    └──────────┴──────────┴──────────┘
```

1. **Dynamic SliverAppBar:**
   * Contextual titles with floating/snap scroll physics (hides on scroll down, reveals on scroll up).
   * Actions: Global Search icon, Local Sync Status badge, User Profile avatar.
2. **Center-Docked Capture FAB:**
   * Distinctive glowing button elevated above the navigation bar.
   * Single tap: Opens Omni-Capture sheet. Long-press: Starts instant audio dictation.
3. **Adaptive Form Factor:**
   * **Mobile (<600dp):** Bottom navigation with center docked FAB.
   * **Tablet (600-1024dp):** Left navigation rail + 2-pane Master-Detail view.
   * **Desktop (>1024dp):** Expanded 3-column workspace (Navigation Sidebar, Active Feed, Persistent Context Inspector).

---

## 5. Design System (Flutter Theme Specification)

### 5.1 Color Tokens (`ThemeExtension<RecallrColors>`)

```dart
class RecallrColors extends ThemeExtension<RecallrColors> {
  // Base Surfaces (Dark-First)
  static const obsidianBase    = Color(0xFF0A0A0C); // Deepest background
  static const slateSurface    = Color(0xFF131316); // Scaffold & Nav bar
  static const charcoalCard    = Color(0xFF1C1C20); // Cards & Containers
  static const glassOverlay    = Color(0xB3131316); // 70% blurred sheet surface

  // Accent & AI Tokens
  static const aiElectricViolet= Color(0xFF8B5CF6); // Primary AI accent
  static const aiCyanHighlight = Color(0xFF06B6D4); // Secondary AI gradient
  static const warmAmberGold   = Color(0xFFF59E0B); // Commitments & Promises
  static const emeraldVerified = Color(0xFF10B981); // User-verified memory claims
  static const crimsonAlert    = Color(0xFFEF4444); // Warnings & Destructive actions

  // High-Contrast Accessible Typography
  static const textPrimary     = Color(0xFFF8FAFC); // Headings & primary labels
  static const textSecondary   = Color(0xFFA1A1AA); // Metadata & subtitles
  static const textTertiary    = Color(0xFF71717A); // Placeholders & timestamps

  // 1px Restrained Borders
  static const borderSubtle    = Color(0xFF27272A); // Default card/input outline
  static const borderHighlight = Color(0xFF3F3F46); // Focused / hovered outline
}
```

### 5.2 Typography Hierarchy (Inter / Geist + JetBrains Mono)
* **Display Large:** 30px, SemiBold (w600), -1.0% tracking (Profile names).
* **Headline Medium:** 22px, SemiBold (w600), -0.5% tracking (Section titles).
* **Title Medium:** 16px, Medium (w500), 0% tracking (Card headers, interactive tiles).
* **Body Large:** 15px, Regular (w400), 1.5 line-height (Notes, dossier summaries).
* **Body Medium:** 13px, Regular (w400), 1.4 line-height (Secondary metadata).
* **Label Small:** 11px, SemiBold (w600), +1.5% tracking, All-Caps (Badges, tags).
* **Mono Metadata:** 12px, Regular (w400), JetBrains Mono (IDs, timestamps, coordinates).

### 5.3 Spacing, Borders & Radius Scale
* **Base Grid:** 4px / 8px. Touch targets strictly >= 48x48dp.
* **Radii:**
  * `radiusSm`: 4dp (Status dots, tags)
  * `radiusMd`: 8dp (Buttons, text inputs)
  * `radiusLg`: 16dp (Cards, dialogs, bottom sheets)
  * `radiusPill`: 999dp (Search bar, FAB, avatars, badges)
---

## 6. Screen Catalogue & Hierarchy

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                 RECALLR SCREEN CATALOGUE                                │
├─────┬────────────────────────────────┬──────┬───────────────────┬───────────────────────┤
│ ID  │ Screen Name                    │ Tier │ Entry Point       │ Key Interaction       │
├─────┼────────────────────────────────┼──────┼───────────────────┼───────────────────────┤
│ S01 │ Home / Memory Command Center   │ P0   │ App Launch / Tab1 │ Feed, capture & recents│
│ S02 │ People Directory               │ P0   │ Tab 2             │ A-Z / Recency search  │
│ S03 │ Person Dossier                 │ P0   │ People / Feed     │ Full context view     │
│ S04 │ Omni-Capture Sheet             │ P0   │ Center FAB        │ Multi-modal chooser   │
│ S05 │ Business Card OCR Viewfinder   │ P0   │ Capture Hub       │ Camera & OCR pipeline │
│ S06 │ Interaction Log Sheet          │ P0   │ Capture / Profile │ Meeting notes & recap │
│ S07 │ Activity & Follow-ups Hub      │ P0   │ Tab 4 / Home      │ Tasks, logs & review  │
│ S08 │ Ask Your Network Conversational│ P0   │ Tab 3             │ Grounded memory Q&A   │
│ S09 │ Universal Search Overlay       │ P0   │ Top Bar Icon      │ Instant multi-entity  │
│ S10 │ Company Context Dossier        │ P1   │ Person Dossier    │ Org contacts & history│
│ S11 │ Event Context Dossier          │ P1   │ Person Dossier    │ Expo attendees list   │
│ S12 │ Files & Attachments Vault      │ P1   │ Dossier / Search  │ Cards & PDF previews  │
│ S13 │ Memory Claim Verification Flow │ P1   │ Activity Tab      │ Swipe verify/dispute  │
│ S14 │ User Profile & Sync Manager    │ P1   │ Top Bar Avatar    │ Cache & sync stats    │
│ S15 │ Settings, Privacy & Security   │ P1   │ Profile           │ AI zero-training/kill │
│ S16 │ Network Visual Graph Explorer  │ P2   │ Dossier (Future)  │ Interactive node view │
└─────┴────────────────────────────────┴──────┴───────────────────┴───────────────────────┘
```

---

## 7. Core Screen Architecture & UX Workflows

### 7.1 Home / Command Center [P0]
* **Purpose:** The user's everyday relationship command center, immediately practical without requiring advanced AI.
* **Layout Hierarchy:**
  1. *Ask Your Network Entry*: Hero search/query bar ("Who did I meet in Hyderabad?", "Search people, companies, notes...").
  2. *Quick Capture Action Bar*: 1-tap direct shortcuts for Business Card Scan, Audio Note, and Quick Meeting Note.
  3. *Actionable Follow-ups*: Priority pending promises and commitments due soon with 1-tap resolution.
  4. *Recent People*: Horizontal carousel of newly captured or recently contacted individuals.
  5. *Recent Interactions*: Feed of recent meetings, calls, and encounters with time-locked context.
  6. *AI Memory Briefing & Insights (Progressive Enhancement)*: Appears dynamically when AI pipeline generates morning briefings or highlights unverified memory claims.

### 7.2 Person Profile / Dossier [P0]
* **Purpose:** The central 360-degree memory dossier for a contact.
* **Structure:**
  * **Header**: Avatar, full name, current role @ company, last contacted indicator.
  * **Quick Actions**: Log Meeting, Call, Email, Share Dossier.
  * **Top Capabilities**: Verified skills and domain specialties (`topCapabilities` chips).
  * **Active Commitments**: Open promises ("I Promised" / "They Promised").
  * **Interaction Timeline**: Chronological meeting cards with participant company contexts locked at meeting time.
  * **Verified Memory Claims**: Atomic claims with provenance snippets and verification badges.
  * **Attached Documents**: Visiting card thumbnails, quotes, and pitch decks.
  * **Career Progression [P1]**: Chronological employment history across companies.

### 7.3 Omni-Capture Flow [P0]
* **Trigger:** Center FAB tap or lock-screen widget.
* **Modes:**
  * 📸 **Scan Visiting Card**: Launches camera viewfinder with auto edge detection; routes through an agnostic **OCR pipeline** (provider selection open) to extract contact details; presents side-by-side verification sheet.
  * 🎙️ **Voice Memo**: Pulsing audio recording modal; transcribes speech; auto-extracts attendees, commitments, and capability claims.
  * ✍️ **Quick Note**: Focused markdown editor with auto-suggest for names and companies.

### 7.4 Activity & Follow-ups Hub [P0]
* **Purpose:** Comprehensive operational view of network commitments, historical activities, and data integrity.
* **Core Tabs / Sections:**
  1. *Follow-ups & Commitments*: Segmented into "I Promised" (my tasks) and "They Promised" (pending deliverables), sorted by due date.
  2. *Recent Interactions Feed*: Chronological activity log across all contacts and events.
  3. *Memory Review & Verification*: Queue of newly extracted AI claims awaiting user verification or dispute.
  4. *Sync & Local Status*: Real-time indicator of offline changes pending synchronization with Cloud Firestore.

### 7.5 "Ask Your Network" Grounded Q&A [P0]
* **Purpose:** Natural-language network memory interrogation.
* **Experience:**
  * Persistent query bar: *"Who does multi-layer PCB fabrication in Hyderabad?"*
  * Grounded AI Answer Card: Direct answer synthesized exclusively from verified claims.
  * Interactive Person Citation Chips: Tapping `[Rajesh Sharma]` slides up the contact dossier.
  * Provenance Drawer: Expandable sheet showing the exact meeting note or card snippet supporting the answer.
  * Abstention State: *"I cannot find any PCB manufacturers in Hyderabad in your network memory."*

---

## 8. Component & Interaction Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              RECALLR COMPONENT CATALOGUE                                │
├──────────────────────────┬─────────────────────────────┬────────────────────────────────┤
│       ENTITY CARDS       │        AI & COGNITIVE       │       CONTROLS & INPUTS        │
├──────────────────────────┼─────────────────────────────┼────────────────────────────────┤
│ • PersonCard             │ • MemoryClaimCard           │ • GlobalCaptureFab (Glowing)   │
│ • CompanyCard            │ • AIAnswerCard              │ • SmartSearchBar               │
│ • InteractionCard        │ • ConfidenceIndicator       │ • DirectionBadge (I/They Owe)  │
│ • FollowUpCard           │ • VerificationBadge         │ • StatusDotIndicator           │
│ • FileAttachmentCard     │ • ProvenanceExcerptSheet    │ • FilterChipGroup              │
└──────────────────────────┴─────────────────────────────┴────────────────────────────────┘
```

### Fluid Interaction Patterns
* **Swipe to Resolve:** Swiping a `FollowUpCard` right executes instant completion with a green tick animation; swiping left snoozes for 3 days.
* **Haptic Affirmation:** `HapticFeedback.mediumImpact()` fires on memory verification and card capture.
* **5-Second Undo Toasts:** Non-blocking floating snackbars on destructive actions (e.g. deleting an interaction).
* **Inline Claim Expansion:** Tapping an unverified claim expands inline to show the verbatim source sentence without leaving the screen.
---

## 9. Responsive & Accessibility Architecture

### 9.1 Breakpoint Strategy
* **Compact (<600dp):** Single-column vertical scroll, bottom navigation bar, full-width cards.
* **Medium (600dp - 1024dp):** Master-Detail view (35% contact list on left, 65% dossier on right), left navigation rail.
* **Expanded (>1024dp):** 3-column layout (Sidebar navigation, active feed, persistent context inspector).

### 9.2 WCAG 2.1 AA Compliance
* **Touch Targets:** Strictly >= 48x48dp for all interactive elements.
* **Color Contrast:** Body text >= 4.5:1 against dark backgrounds (`textPrimary: #F8FAFC` on `obsidianBase: #0A0A0C` yields 17.5:1).
* **Dynamic Type Scaling:** Responsive layouts support up to **200%** system text enlargement via `Wrap` and flex constraints without clipping.
* **Screen Reader Semantics:** Explicit `Semantics` annotations for all claim cards, follow-up checkboxes, and camera triggers.
* **Reduced Motion:** Observes `MediaQuery.disableAnimations`, replacing scale/particle effects with subtle instant opacity transitions.
* **Desktop Shortcuts:** `Cmd/Ctrl+K` (Universal Search), `Cmd/Ctrl+N` (Quick Capture), `Esc` (Dismiss Sheets).

---

## 10. System States (Loading, Error, Empty, Offline)

1. **Skeleton Loaders:** Content-accurate shimmering placeholders matching the exact typography height and card padding to eliminate layout shifts.
2. **Contextual Empty States:** Clean dark vector illustrations with clear guidance (e.g., *"No follow-ups pending — you're completely caught up with your network"*).
3. **Graceful Error Recovery:** Inline red-accented warning cards with a single-tap **Retry** button; zero intrusive popups for background sync failures.
4. **Unobtrusive Offline Banner:** A slim 24dp top bar indicator (*"Working offline — all changes saved locally"*) with auto-dismiss on reconnection, operating seamlessly via local reactive state + native Cloud Firestore offline persistence.

---

## 11. Implementation Phasing Matrix

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                               PHASED IMPLEMENTATION ROADMAP                             │
├──────────────────────────┬─────────────────────────────┬────────────────────────────────┤
│       P0: CORE V1        │        P1: NEXT V1.X        │       P2: FUTURE PHASES        │
├──────────────────────────┼─────────────────────────────┼────────────────────────────────┤
│ • Home Command Center    │ • Contextual Company Dossier│ • Interactive Network Graph    │
│ • People Directory (A-Z) │ • Contextual Event Dossier  │ • Autonomous Outreach Suggester│
│ • Person Dossier (Full)  │ • Files Vault View          │ • Multilingual Memory Engine   │
│ • Omni-Capture Sheet     │ • Career History Timeline   │ • On-Device Vector Embeddings  │
│ • Card Scan (OCR Pipeline│ • Memory Verification Stack │ • Proactive Meeting Prep AI    │
│ • Interaction Log Sheet  │ • Account Sync Manager      │                                │
│ • Activity Hub           │ • Settings & Data Privacy   │                                │
│ • Ask Your Network Q&A   │                             │                                │
│ • Universal Search Bar   │                             │                                │
└──────────────────────────┴─────────────────────────────┴────────────────────────────────┘
```

---

## 12. Architectural Decision Records (ADR)

### ADR-01: 4-Pillar Primary Navigation vs. CRM Multi-Tab Bar
* **Decision:** Restrict primary bottom navigation to 4 hubs: Home, People, Ask, and Activity (plus center Capture FAB).
* **Rationale:** Prevents CRM-style horizontal bloat and keeps user focus locked on the fundamental loop: Capture, Remember, Ask.

### ADR-02: Contextual Entities vs. Standalone Tab Lists
* **Decision:** Demote Companies, Events, and Files from primary tabs into contextual dossiers accessible via People profiles and Universal Search.
* **Rationale:** In personal networking, companies and files only matter in context to the person you met. Standalone lists encourage passive database management rather than active recall.

### ADR-03: Dark-First Pro Aesthetic vs. Material 3 Pastel Defaults
* **Decision:** Implement a custom dark-first design system utilizing Obsidian (`#0A0A0C`), Charcoal (`#1C1C20`), and crisp 1px borders.
* **Rationale:** Delivers a high-density, calm, pro-grade software feel (akin to Linear/Superhuman) while avoiding generic pastel Material 3 template cliches.

### ADR-04: Grounded Q&A with Verifiable Provenance vs. Conversational Chatbot
* **Decision:** Design "Ask Your Network" with structured citation cards and provenance drawers rather than a floating chat bubble.
* **Rationale:** Builds deep user trust, minimizes hallucination, and anchors all AI answers in verified user memory.

### ADR-05: Platform-Agnostic OCR Pipeline
* **Decision:** Treat business card OCR as a modular, provider-agnostic pipeline in Phase 02 UI architecture rather than mandating a specific on-device engine.
* **Rationale:** Allows flexible benchmarking of local vs cloud OCR providers during Phase 03 implementation.

### ADR-06: Robust Home P0 with AI as Progressive Enhancement
* **Decision:** Ensure Home functions as an immediate utility hub (Ask bar, Quick capture, Recent people, Recent interactions, Follow-ups) even before AI memory briefing models execute.
* **Rationale:** Delivers instant value on Day 1 without blocking core user utility on async AI inferences.

---

### ARCHITECTURE STATUS
`READY FOR FINAL LOCK`