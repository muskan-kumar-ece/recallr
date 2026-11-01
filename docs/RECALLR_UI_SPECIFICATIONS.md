# Recallr — UI & Flow Redesign Specification v1.0

## 1. Executive Overview & Visual Identity
Recallr is a personal relationship intelligence and memory companion for professionals. This document captures the complete specifications, layout structures, user interaction flows, and design blueprints based on the hand-crafted references and architecture reviews.

### Design Language & System Tokens
- **Theme Paradigm:** Dark-first Pro Theme (`obsidianBase: #09090B`, `slateSurface: #18181B`, `charcoalCard: #202024`).
- **Typography:** Inter, high-contrast, editorial hierarchy.
- **Accents:** Electric Violet (`#8B5CF6`), Emerald Verified (`#10B981`), Warm Amber (`#F59E0B`), Cyan Highlight (`#06B6D4`), Crimson Alert (`#F87171`).
- **Borders & Radii:** 1px subtle borders (`#27272A`), rounded cards (12–16px), pills for tags and status indicators.

---

## 2. Page-by-Page Layout & Functional Blueprints

### A. Home Screen (Command Center)
- **Top Bar:** 
  - Left: Hamburger menu / Drawer toggle
  - Right: QR scanner shortcut (`Icons.qr_code_scanner_rounded`) & Profile avatar shortcut
  - Wordmark is simplified or contextualized to keep maximum screen real estate.
- **Welcome Hero Card (Dark Navy/Indigo Tint `#1E1B4B`):**
  - Pill / Label: `YOUR PERSONAL MEMORY`
  - Headline: `Welcome back!` + Psychology / Brain icon
  - Subtitle: `Your relationships, always remembered.`
  - Inner Focus Card: `Remember what matters.` — `People, conversations and important moments — all in one place.`
  - Dots indicator (5 carousel positions) + Next Arrow action.
- **Latest Things Section:**
  - Header: `Latest things` with `This week ↗` action link.
  - 2×2 Category Preview Grid:
    1. **People:** Blue-purple tint (`#1E1E3F`), `Icons.people_outline_rounded`, "Recent connections"
    2. **Memories:** Emerald tint (`#0F2520`), `Icons.auto_awesome_rounded`, "Things worth remembering"
    3. **Activity:** Warm amber tint (`#2A1F0A`), `Icons.calendar_today_outlined`, "Recent interactions"
    4. **Connections:** Pink tint (`#2A0F1A`), `Icons.hub_outlined`, "Your growing network"
- **Stay Connected Section:**
  - 2-Column Action Cards:
    1. **Notifications:** Bell icon, `Important updates and reminders.`, `View alerts` button.
    2. **Follow-ups:** Calendar check icon, `Keep promises and reconnect.`, `View follow-ups` button.

---

### B. Quick Add (Central Omnipresent Action)
- **Presentation:** Bottom Sheet modal with top drag pill (`DRAG TO EXPAND OR COLLAPSE`) and top-right Dismiss button.
- **Header:** `Quick Add` — `What would you like to remember?`
- **Primary Actions (People & Connections):**
  1. `Scan Recallr QR code` (Gold icon bg, `Icons.qr_code_scanner_rounded`) — Connect with a person
  2. `Add person manually` (Purple icon bg, `Icons.person_add_outlined`) — Enter details yourself
  3. `Add through AI` (Emerald icon bg, `Icons.auto_awesome_rounded`) — Describe a person or interaction
- **Secondary Capture Grid (`CAPTURE NOTES, MEMORIES & MORE`):**
  - 2×3 Grid of quick actions:
    1. Quick note (`Icons.edit_note_rounded`)
    2. Voice memo (`Icons.mic_rounded`)
    3. Create follow-up (`Icons.event_outlined`)
    4. Business card (`Icons.contact_page_outlined`)
    5. Capture photo (`Icons.camera_alt_outlined`)
    6. Add document (`Icons.upload_file_outlined`)

---

### C. People & Directory Hub
- **Screen View 1: Categories Overview (`← Categories`):**
  - Subtitle: `Organize your people and relationships.`
  - Search icon & Add circle shortcut in top bar.
  - 2×2 Category Cards:
    1. **Friends:** Purple icon badge, `Icons.people_outline_rounded`, person counter.
    2. **Work:** Emerald icon badge, `Icons.work_outline_rounded`, person counter.
    3. **College:** Blue icon badge, `Icons.school_outlined`, person counter.
    4. **Family:** Pink icon badge, `Icons.favorite_outline_rounded`, person counter.
  - Expand Action: `Show more categories` expandable dropdown.
  - Quick Link: `Add people` row (`Manually, with AI, via QR, or by scanning a business card.`).
- **Screen View 2: Category Details & Directory:**
  - Top Bar: `← {CategoryName}` with count + search & overflow menu.
  - Search input: `Search people in {CategoryName}...`
  - Sort header: `All people` (count) with `↕ Recently added` sort dropdown.
  - 2-Column Responsive Card Grid:
    - 56px colored initials avatar
    - Name (bold)
    - Role / Relationship tag
    - Organization / Company tag with building icon
    - Last interaction timestamp with clock icon

---

### D. Person Profile Dossier
- **Header Section:**
  - Breadcrumb: `PERSON PROFILE`
  - Headline: Person's Name with Edit pencil & overflow `...` menu
  - Large Profile Avatar (80px)
  - Role · Category headline
  - Quick action contact icons: Phone, Email, Chat
  - Action link: `+ Add contact details`
- **About Section:**
  - Header: `About {FirstName}` with edit icon
  - Bio container or placeholder (`No notes added yet.`)
- **Memories & Interactions Section:**
  - Section Header with `+` action button
  - Horizontal filter chips: `Notes`, `Voice memos`, `Photos`
  - Interaction preview card: `Recent interaction` with date, summary, and context
- **Follow-ups Section:**
  - Section Header with `+` action button
  - Actionable commitment cards with due time and completion toggle
- **External & Navigation Rows:**
  - `Meeting location` (Pin icon, navigates to map/places)
  - `Schedule a meeting` (Calendar icon, integrates with calendar)
  - `Contact via WhatsApp` (WhatsApp icon, direct messaging link)

---

### E. Ask with AI (Conversational Intelligence Engine)
- **Top Bar:** Back button, `Ask with AI` title, `Your personal memory assistant` subtitle, menu action.
- **Conversational Memory Canvas:**
  - User Query Bubble (Right-aligned or prominent pill): e.g. `"Tell me about Muskan."`
  - AI Grounded Response Bubble:
    - AI Star Avatar (`#8B5CF6`)
    - Header: `Here's what I found in your memory.`
    - Summary text synthesized from personal memory records
  - Entity Resolution / Person Card:
    - Person identifier, category badge, supporting memory count
    - Action button: `View profile behavior`
  - Proactive Action Suggestion Card (`SUGGESTED ACTION`):
    - Suggestion: `Add this person to a category?`
    - Action buttons: `Review category` | `Dismiss`
- **Bottom Persistent Input Bar:**
  - Attachment icon (paperclip)
  - Rounded text input: `Ask your memory...`
  - Send action button (Violet circle with upward arrow)

---

### F. Settings & Preferences
- **Header:** `Settings` — `Manage your account, personal information and reminders.`
- **Identity Mini-Card:** Avatar, Display Name, Email, and `ACTIVE` subscription badge.
- **Five Core Management Sections:**
  1. **Notification Management:** Reminders, follow-ups, and notification preferences.
  2. **Account:** Sign-in method, security, and account management.
  3. **Personal Information:** Name, photo, contact details, and personal bio.
  4. **Your QR Code & Bio:** View and share your Recallr identity.
  5. **Digital Visiting Card:** Design and manage your shareable professional card.
- **Utility Rows:**
  - Subscription & Cloud Storage management (AI Credits counter & plan upgrade).
  - App preferences (Offline cache & AI grounding sensitivity).
  - Sign Out action button.

---

## 3. Global Navigation Shell Architecture
- **5-Slot Bottom Navigation Bar:**
  1. `Home` (`Icons.home_outlined` / `Icons.home_rounded`)
  2. `People` (`Icons.people_outline_rounded` / `Icons.people_rounded`)
  3. **`Quick Add` (Central elevated Violet circular button `+`)** — Triggers the Quick Add Bottom Sheet without navigating away from the active tab.
  4. `Search` / `Ask` (`Icons.search_rounded` / `Icons.saved_search_rounded`)
  5. `More` / `Settings` (`Icons.grid_view_outlined` / `Icons.grid_view_rounded`)

---

## 4. UI/UX Gap Analysis & Missing Screens Identified
Based on a rigorous audit against the provided references, the following sub-flows and screens are needed to complete the user journey:

1. **Digital Visiting Card Designer:**
   - A dedicated card editor screen allowing users to customize their shareable contact card (theme color, job title, social handles, QR code preview).
2. **QR Code Generator & Scanner Screen:**
   - Fullscreen scanner with camera viewport and flashlight toggle, plus a tab to show "My Personal QR Code" for instant in-person networking.
3. **Category Management & Custom Category Creator:**
   - Modal or screen to add custom categories (e.g., "Investors", "Mentors", "Clients") with custom color and icon selectors.
4. **Interactive Memory Detail / Lightbox:**
   - Tapping on a voice memo, photo note, or document should open a detailed viewer with waveform player, full image preview, and OCR transcript.
5. **Follow-Up Creation Sheet:**
   - Dedicated date/time picker, recurring frequency selector, and person-linking autocomplete for scheduled follow-ups.
