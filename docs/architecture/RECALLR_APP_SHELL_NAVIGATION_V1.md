# Recallr — Phase 04 App Shell & Navigation Implementation v1
**System Blueprint & Implementation Reference (Targeted Correction Pass)**

*Document Status:* **READY FOR FINAL REVIEW**  
*Version:* `1.1.0`  
*Target Framework:* Flutter (iOS, Android, Web) + Material 3 (Dark-First Pro Custom Theme)  
*Companion Documents:*  
- Recallr Data & Memory Architecture v1 (LOCKED)  
- Recallr UI Architecture v1 (LOCKED)  
- Recallr Design System v1 (LOCKED)  

---

## 1. Routing Architecture & Contracts

Recallr uses a centralized, parameter-safe routing engine built in `lib/core/routing/`:

```
                           Incoming Route / Intent
                                     │
                                     ▼
                          [ AppRouter Auth Guard ]
                            /               \
              (Unauthenticated)        (Authenticated)
                     │                         │
                     ▼                         ▼
             [ Set Pending DL ]        [ Execute Direct ]
                     │                         │
                     ▼                         ▼
              [ AuthScreen ]          [ RecallrAppShell ]
                     │                 ├── Tab 0: Home (/home)
              (Sign-In Success)        ├── Tab 1: People (/people)
                     │                 ├── Tab 2: Ask (/ask)
                     ▼                 └── Tab 3: Activity (/activity)
           [ Restore Deep Link ]                       │
                     │                 [ Global Shell Action ]
                     ▼                 • Center FAB -> Quick Capture
         [ Context Dossier / Target ]  • Entry Route: /capture
         • /person/:personId
         • /company/:companyId
         • /event/:eventId
         • /file/:fileId
         • /interaction/:id
         • /follow-up/:id
         • /settings
```

### 1.1 Navigation Contract: Primary Tabs vs. Global Shell Action
* **Primary Navigation (4 Persistent Tabs):**
  1. `Home` (`/home` or `/`) — Tab Index 0 (Memory Command Center & Feed)
  2. `People` (`/people`) — Tab Index 1 (Network Directory & A-Z contacts)
  3. `Ask` (`/ask`) — Tab Index 2 (Conversational Q&A & Grounded Memory Search)
  4. `Activity` (`/activity`) — Tab Index 3 (Follow-ups, Recent touchpoints, and Sync)
* **Global Shell Action (Capture):**
  * `Capture` is **not** a fifth persistent content tab. It is a modal action triggered from the elevated center FAB on Mobile, or the top action button on Tablet/Desktop.
  * **Route Contract for `/capture`:** When the app receives navigation to `/capture` (e.g. from an OS home-screen shortcut or deep-link), `AppRouter` resolves into the authenticated `RecallrAppShell` with `autoOpenCapture: true`, automatically presenting the `CaptureModal` bottom sheet on startup.

---

## 2. Authenticated Deep-Link Restoration

Deep-link preservation across the authentication boundary is implemented via `DeepLinkManager` and `_AuthenticatedRestorer`:

1. **Unauthenticated Access Interception:**  
   When an unauthenticated user opens a deep link (e.g., `/person/abc123` or `/company/stripe`), `AppRouter.onGenerateRoute` detects `FirebaseAuth.instance.currentUser == null`, stores the target path in `DeepLinkManager().setPendingPath('/person/abc123')`, and routes the user safely to `AuthScreen`.
2. **Post-Authentication Restoration:**  
   Upon successful authentication (Email/Password or Google Sign-In), `AuthGate` in `lib/main.dart` mounts `_AuthenticatedRestorer(user: user)`.
3. **Execution:**  
   `_AuthenticatedRestorer` retrieves and consumes the pending path via `DeepLinkManager().consumePendingPath()`. In a post-frame callback, it automatically pushes the intended target route (e.g. `/person/abc123`) on top of `RecallrAppShell`, seamlessly restoring the user's intent.

---

## 3. App Shell Structure & Responsive Layout

Implemented in `lib/app/app_shell.dart` using `LayoutBuilder`:

```
  MOBILE (< 600dp)                  TABLET (600dp - 1024dp)         DESKTOP / WEB (> 1024dp)
┌──────────────────────────┐      ┌────┬─────────────────────┐    ┌──────────┬──────────────────────┐
│ Dynamic AppBar           │      │    │ Dynamic AppBar      │    │ Sidebar  │ Dynamic AppBar       │
├──────────────────────────┤      │ R  ├─────────────────────┤    │ (Quick   ├──────────────────────┤
│                          │      │ a  │ IndexedStack Body   │    │ Capture  │ IndexedStack Body    │
│ IndexedStack Content     │      │ i  │ (Home / People /    │    │ Button + │ (Home / People /     │
│ (Home / People / Ask /   │      │ l  │  Ask / Activity)    │    │ Nav      │  Ask / Activity)     │
│  Activity)               │      │    │                     │    │ Links)   │                      │
├──────────────────────────┤      │    │                     │    │          │                      │
│ [H] [P]  ( + )  [A] [F]  │      │    │                     │    │          │                      │
└──────────────────────────┘      └────┴─────────────────────┘    └──────────┴──────────────────────┘
```

1. **Dynamic Top AppBar:**
   * Contextual section title (`Home`, `People`, `Ask`, `Activity`).
   * Universal search shortcut button (switches directly to the `Ask` tab).
   * Real-time sync status indicator dot (`RecallrBadge(isDot: true, variant: verified)`).
   * User profile avatar with dropdown menu showing user email and Sign Out action.
2. **Tab State Preservation (`IndexedStack`):**
   * The 4 core tabs remain resident in memory during navigation, preserving scroll positions, inputs, and active filters across tab switching and device rotation.
3. **Responsive Breakpoints:**
   * **Mobile (<600dp):** Custom bottom navigation bar with 4 tabs and a center-docked Floating Capture FAB with subtle AI glow.
   * **Tablet (600dp - 1024dp):** Left `NavigationRail` with persistent destinations and top Capture button.
   * **Desktop / Web (>1024dp):** Expanded `NavigationRail` with labels and prominent Quick Capture button.

---

## 4. Route Catalogue & Resolution Matrix

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              RECALLR ROUTE CATALOGUE                                   │
├───────────────┬──────────────────────────┬───────────┬─────────────────────────────────┤
│ Route Path    │ Target Screen            │ Type      │ Behavior / Contract             │
├───────────────┼──────────────────────────┼───────────┼─────────────────────────────────┤
│ `/`           │ `RecallrAppShell(tab: 0)`│ Tab 0     │ Default landing (Home)          │
│ `/auth`       │ `AuthScreen`             │ Public    │ Login / registration gate       │
│ `/home`       │ `RecallrAppShell(tab: 0)`│ Tab 0     │ Command Center & Feed           │
│ `/people`     │ `RecallrAppShell(tab: 1)`│ Tab 1     │ Network Directory & A-Z search  │
│ `/ask`        │ `RecallrAppShell(tab: 2)`│ Tab 2     │ Grounded Q&A & Memory Search    │
│ `/activity`   │ `RecallrAppShell(tab: 3)`│ Tab 3     │ Commitments & Activity Stream   │
│ `/capture`    │ `RecallrAppShell(action)`│ Action    │ Resolves shell & opens modal    │
│ `/settings`   │ `DetailPlaceholderScreen`│ Context   │ Settings & preferences deep link│
│ `/person/:id` │ `DetailPlaceholderScreen`│ Parametric│ Contact dossier deep link       │
│ `/company/:id`│ `DetailPlaceholderScreen`│ Parametric│ Company dossier deep link       │
│ `/event/:id`  │ `DetailPlaceholderScreen`│ Parametric│ Event dossier deep link         │
│ `/file/:id`   │ `DetailPlaceholderScreen`│ Parametric│ File preview deep link          │
│ `/interaction`│ `DetailPlaceholderScreen`│ Parametric│ Touchpoint deep link            │
│ `/follow-up`  │ `DetailPlaceholderScreen`│ Parametric│ Commitment deep link            │
│ (Any unknown) │ `NotFoundScreen`         │ Fallback  │ 404 screen with "Go Home" action│
└───────────────┴──────────────────────────┴───────────┴─────────────────────────────────┘
```

---

## 5. Architecture Decisions (ADR)

### ADR-01: 4 Primary Tabs + Global Modal Capture Action
* **Decision:** Primary navigation strictly contains Home, People, Ask, and Activity. Capture is modeled as a shell action triggered via FAB or `/capture` route.
* **Rationale:** Preserves the anti-CRM principle by avoiding tab-sprawl while ensuring instant 1-tap capture is accessible from every surface.

### ADR-02: Native Declarative Deep-Link & Auth Restoration
* **Decision:** Implement `DeepLinkManager` with `_AuthenticatedRestorer` in `lib/main.dart` and `AppRouter.onGenerateRoute`.
* **Rationale:** Provides zero-dependency deep-link restoration and parameter parsing across authentication boundaries without breaking Firebase initialization.

---

### APP SHELL + NAVIGATION STATUS
`READY FOR FINAL REVIEW`