# Phase 13G-01 Runtime Source Audit Report
## Comprehensive Investigation into Production Mock Data Leakage

---

## 1. Executive Summary

During browser testing of Recallr v1.0.0, the running application displayed realistic professional-network data (e.g., **Priya Sharma**, **Sarvam AI**, **Arjun Mehta**, **Nexus Venture Partners**, **RISC-V discussion**, **Hyderabad Tech Summit**, **42 People**, **18 Companies**, **89 Interactions**, **3 Follow-ups**).

This audit rigorously traced the entire runtime execution path from UI widgets, through controllers and dependency injection, down to Firestore repositories and mock files.

### Key Finding:
1. **Firestore backend integration is real and fail-closed**: Production Firestore repositories (`FirestorePeopleRepository`, `FirestoreActivityRepository`, etc.) are correctly implemented, authenticated, and point to `users/{uid}/*` subcollections in Firebase project `recaller-cabf8`.
2. **Firestore does NOT contain seeded demo data**: The Firebase project has 0 seeded mock documents.
3. **The mock data originates from 6 UI-level hardcodings and synchronous initial-state fallbacks**:
   - **`HomeScreen`** is not wired to repositories at all; it hardcodes `HomeMockData.pulseStats`, `HomeMockData.attentionItems`, `HomeMockData.recentPeople`, and `HomeMockData.recentMemories`.
   - **`PeopleScreen`** initializes state to `PeopleMockData.people` and `PeopleMockData.recentlyInteracted`, and fails to clear `_recentlyInteracted` when Firestore returns an empty stream.
   - **`ActivityScreen`** initializes `_allActivities` to `ActivityMockData.mockActivities`.
   - **`FollowUpsScreen`** initializes `_allFollowUps` to `FollowUpMockData.mockFollowUps`.
   - **`PersonDetailScreen`** initializes `_profile` to `PersonProfileMockData.getProfile(personId)` which falls back to Priya Sharma (`per_301`) for any unknown ID.
   - **`AskScreen`** renders `MockMemoryEngine.suggestedQuestions` / `recentQuestions` and falls back to `MockMemoryEngine.ask()` in its `catch (_)` block.
   - **`CaptureModal`** initializes `_recentCaptures` to `widget.engine.getRecentCaptures()`.

---

## 2. Runtime Data Architecture

```
[Flutter App Startup]
         â†“
[FirebaseBootstrap.initialize()]
         â†“
[RecallrDependencies.production()]
  â€¢ FirestorePeopleRepository (users/{uid}/people)
  â€¢ FirestoreActivityRepository (users/{uid}/activities)
  â€¢ FirestoreFollowUpRepository (users/{uid}/follow_ups)
  â€¢ FirestoreCaptureRepository (users/{uid}/captures)
  â€¢ FirestorePersonDetailRepository (users/{uid}/people/{id})
  â€¢ FirestoreMemoryRetrievalRepository (users/{uid}/*)
  â€¢ GeminiGroundedAnswerGenerator
         â†“
[RecallrScope(dependencies: deps)]
         â†“
[MaterialApp -> AuthGate -> RecallrAppShell]
         â†“
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ Screen                     â”‚ Data Source at Runtime                               â”‚ Defect Mechanism                                â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚ 1. HomeScreen              â”‚ HomeMockData (Static Dart Constants)                 â”‚ No repository connection in UI                  â”‚
â”‚ 2. PeopleScreen            â”‚ PeopleMockData (Initial state & recent check)        â”‚ Synchronous fallback & empty check omission     â”‚
â”‚ 3. ActivityScreen          â”‚ ActivityMockData (Initial state before stream)       â”‚ Synchronous initial assignment in initState     â”‚
â”‚ 4. FollowUpsScreen         â”‚ FollowUpMockData (Initial state before stream)       â”‚ Synchronous initial assignment in initState     â”‚
â”‚ 5. PersonDetailScreen      â”‚ PersonProfileMockData (Initial state & fallback)     â”‚ getProfile() fallback to Priya Sharma           â”‚
â”‚ 6. AskScreen               â”‚ MockMemoryEngine (Suggested questions & catch block) â”‚ Catch block delegates to MockMemoryEngine       â”‚
â”‚ 7. CaptureModal            â”‚ CaptureMockData (Initial state via CaptureEngine)    â”‚ CaptureEngine defaults to mock recent captures  â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

---

## 3. Authentication State

- **Provider**: Firebase Authentication (Email/Password + Google Sign-In)
- **Status**: **VERIFIED FUNCTIONAL**
- **Session Resolution**: All production Firestore repositories resolve `FirebaseAuth.instance.currentUser` dynamically on each call. If `currentUser == null`, they throw `RecallrDataException.unauthenticated()`.
- **Tenant Isolation**: Fully enforced under `users/{uid}/*`.

---

## 4. Firestore Runtime Path

- **Active Project ID**: `recaller-cabf8`
- **Subcollections**:
  - `users/{uid}/people`
  - `users/{uid}/activities`
  - `users/{uid}/follow_ups`
  - `users/{uid}/captures`
  - `users/{uid}/claims`
  - `users/{uid}/interactions`
- **Firestore Query Behavior**: When queried for a newly authenticated user with no data, Firestore returns 0 documents (`snapshot.docs == []`).
- **Does Firestore contain demo records?**: **NO**. The demo records are not in Firestore.

---

## 5. Dependency Injection Path

In `lib/main.dart`:
```dart
final result = await FirebaseBootstrap.initialize();
runApp(RecallerApp(dependencies: result.dependencies));
```
In `FirebaseBootstrap.initialize()` (lines 179-184 of `lib/core/bootstrap/firebase_bootstrap.dart`):
```dart
final deps = dependenciesOverride ??
    RecallrDependencies.production(
      crashReportingService: crashReporting,
      telemetryService: telemetry,
    );
```
`RecallrDependencies.production()` correctly instantiates:
- `peopleRepository: FirestorePeopleRepository()`
- `personDetailRepository: FirestorePersonDetailRepository()`
- `activityRepository: FirestoreActivityRepository()`
- `followUpRepository: FirestoreFollowUpRepository()`
- `captureRepository: FirestoreCaptureRepository()`
- `memoryRetrievalRepository: FirestoreMemoryRetrievalRepository()`

`RecallrDependencies.mock()` is **NOT** invoked by `FirebaseBootstrap` during production runtime.
However, because `RecallrDependencies.setInstance(deps)` is never called, the static fallback `RecallrDependencies.instance` defaults to `RecallrDependencies.mock()` if a widget looks outside of `RecallrScope`.

---

## 6. Mock Data Sources Breakdown

### A. Home Dashboard (`lib/features/home/models/home_mock_data.dart`)
- **Origin**: Static class `HomeMockData`
- **Referenced in**: `lib/screens/home/home_screen.dart`
- **Specific Lines**:
  - `HomeMockData.pulseStats` (Line 157)
  - `HomeMockData.attentionItems` (Lines 163, 187)
  - `HomeMockData.recentPeople` (Lines 167, 189)
  - `HomeMockData.recentMemories` (Lines 171, 200)

### B. People Directory (`lib/features/people/models/people_mock_data.dart`)
- **Origin**: `PeopleMockData.people` and `PeopleMockData.recentlyInteracted`
- **Referenced in**: `lib/screens/people/people_screen.dart`
- **Specific Lines**:
  - Line 52: `List<PersonItem> _recentlyInteracted = PeopleMockData.recentlyInteracted;`
  - Line 64: `_allPeople = widget.initialPeople ?? PeopleMockData.people;`
  - Line 111: `if (mounted && recent.isNotEmpty) { setState(() { _recentlyInteracted = recent; }); }` (Fails to update when `recent` is empty).

### C. Relationship Timeline (`lib/features/activity/models/activity_mock_data.dart`)
- **Origin**: `ActivityMockData.mockActivities`
- **Referenced in**: `lib/screens/activity/activity_screen.dart`
- **Specific Line**: Line 132 (`_allActivities = List.from(ActivityMockData.mockActivities);`)

### D. Follow-ups Hub (`lib/features/follow_ups/models/follow_up_mock_data.dart`)
- **Origin**: `FollowUpMockData.mockFollowUps`
- **Referenced in**: `lib/screens/follow_ups/follow_ups_screen.dart`
- **Specific Line**: Line 139 (`_allFollowUps = List.from(FollowUpMockData.mockFollowUps);`)

### E. Person Dossier (`lib/features/person_detail/models/person_profile_mock_data.dart`)
- **Origin**: `PersonProfileMockData.getProfile(personId)`
- **Referenced in**: `lib/screens/person/person_detail_screen.dart`
- **Specific Lines**:
  - Line 60: `_profile = widget.initialProfile ?? PersonProfileMockData.getProfile(widget.personId);`
  - `person_profile_mock_data.dart` Line 512: `return _profiles['per_301'];` (Defaults to Priya Sharma).

### F. Ask Grounded Memory (`lib/features/ask/models/ask_mock_data.dart`)
- **Origin**: `MockMemoryEngine`
- **Referenced in**: `lib/screens/ask/ask_screen.dart`
- **Specific Lines**:
  - Line 51: `final List<String> _recentQuestions = List.from(MockMemoryEngine.recentQuestions);`
  - Line 53: `final MockMemoryEngine _engine = const MockMemoryEngine();`
  - Line 169: `result = await _engine.ask(cleanQuestion);` (Inside catch block)
  - Line 270: `suggestions: MockMemoryEngine.suggestedQuestions`

### G. Omni-Capture Hub (`lib/features/capture/models/capture_mock_data.dart`)
- **Origin**: `CaptureMockData.initialRecentCaptures`
- **Referenced in**: `lib/screens/capture/capture_modal.dart`
- **Specific Line**: Line 129 (`_recentCaptures = widget.isEmpty ? [] : widget.engine.getRecentCaptures();`)

---

## 7. Known Demo Records & Exact Source Trace

| Data Item | Exact Source File & Line | Trace to UI Screen |
|:---|:---|:---|
| **Priya Sharma** (Microsoft) | `lib/features/home/models/home_mock_data.dart:51`, `lib/features/people/models/people_mock_data.dart:10`, `lib/features/person_detail/models/person_profile_mock_data.dart:13` | `HomeScreen` (Recent People & Recent Memories), `PeopleScreen` (Initial list & Recently Interacted), `PersonDetailScreen` (per_301 & fallback), `AskScreen` (Suggested questions) |
| **Arjun Mehta** (Nexus Venture) | `lib/features/home/models/home_mock_data.dart:71`, `lib/features/people/models/people_mock_data.dart:42`, `lib/features/person_detail/models/person_profile_mock_data.dart:253` | `HomeScreen` (Needs Attention & Recent People), `PeopleScreen`, `ActivityScreen`, `FollowUpsScreen` |
| **Sarvam AI** (Vivek Raghavan) | `lib/features/home/models/home_mock_data.dart:63, 107`, `lib/features/people/models/people_mock_data.dart:26` | `HomeScreen` (Recent Memories & Recent People), `PeopleScreen`, `CaptureModal` |
| **42 People** | `lib/features/home/models/home_mock_data.dart:9` | `HomeScreen` $\rightarrow$ `MemoryPulse(stats: HomeMockData.pulseStats)` $\rightarrow$ `pulseStats.peopleCount` |
| **18 Companies** | `lib/features/home/models/home_mock_data.dart:10` | `HomeScreen` $\rightarrow$ `MemoryPulse(stats: HomeMockData.pulseStats)` $\rightarrow$ `pulseStats.companiesCount` |
| **89 Interactions** | `lib/features/home/models/home_mock_data.dart:11` | `HomeScreen` $\rightarrow$ `MemoryPulse(stats: HomeMockData.pulseStats)` $\rightarrow$ `pulseStats.interactionsCount` |
| **3 Follow-ups** | `lib/features/home/models/home_mock_data.dart:12` | `HomeScreen` $\rightarrow$ `MemoryPulse(stats: HomeMockData.pulseStats)` $\rightarrow$ `pulseStats.followUpsCount` |
| **Hyderabad Tech Summit** | `lib/features/home/models/home_mock_data.dart:97`, `lib/features/capture/models/capture_mock_data.dart:19` | `HomeScreen` (Recent Memories), `CaptureModal` (Recent Captures), `PersonDetailScreen` (Priya Sharma timeline) |
| **RISC-V discussion** | `lib/features/capture/models/capture_mock_data.dart:11`, `lib/features/home/models/home_mock_data.dart:98` | `CaptureModal` (cap_1), `HomeScreen` (rec_1), `AskScreen` (MockMemoryEngine.ask) |

---

## 8. Environment Behavior

- **`APP_ENV=development`**: `allowMockFallback: true`, `enableAppCheck: false`.
- **`APP_ENV=staging`**: `allowMockFallback: false`, `enableAppCheck: true`.
- **`APP_ENV=production`**: `allowMockFallback: false`, `enableAppCheck: true`.
- **Finding**: While `EnvironmentConfig.production` sets `allowMockFallback: false`, the screen widgets had direct compile-time references to `HomeMockData`, `PeopleMockData`, `ActivityMockData`, `FollowUpMockData`, and `PersonProfileMockData` which bypassed environment configuration checks.

---

## 9. Production Runtime Risk Analysis

1. **Brand / Data Confusion**: Users see fictitious people, companies, and commitments that do not belong to their network.
2. **False Empty State Masking**: Empty Firestore collections do not show empty states on `HomeScreen` because `HomeScreen` does not query Firestore.
3. **Data Desynchronization**: Actions performed on the home screen navigate to hardcoded mock IDs (`per_301`, `fol_101`, `int_103`) instead of real Firestore documents.

---

## 10. Recommended Remediation (Phase 13G-01-B Plan)

1. **Connect `HomeScreen` to Real Firestore Repositories**:
   - Create a `HomeAggregateService` or stream counts directly from `peopleRepository.streamPeople()`, `activityRepository.streamActivities()`, `followUpRepository.streamFollowUps()`.
   - Compute `MemoryPulseStats` dynamically from live Firestore streams.
   - Stream `RecentPeopleSection`, `NeedsAttentionSection`, and `RecentMemoriesSection` from live Firestore subcollections.
   - Render `HomeEmptyState` when Firestore has 0 records.
2. **Clean Initial States in Screens**:
   - `PeopleScreen`: Initialize `_allPeople = []` and `_recentlyInteracted = []`. On stream emit, update `_recentlyInteracted` even if empty.
   - `ActivityScreen`: Initialize `_allActivities = []`.
   - `FollowUpsScreen`: Initialize `_allFollowUps = []`.
   - `PersonDetailScreen`: Remove `PersonProfileMockData.getProfile` fallback; display loading or `PersonNotFound` when document doesn't exist.
   - `AskScreen`: Clear `_recentQuestions` to `[]`, remove `MockMemoryEngine.ask()` catch fallback, and provide dynamic empty suggestions.
   - `CaptureModal`: Initialize `_recentCaptures = []` and stream from `CaptureRepository`.
3. **Set Global DI Instance**:
   - In `FirebaseBootstrap.initialize()`, call `RecallrDependencies.setInstance(deps)` so any detached context inherits the production container.
4. **Preserve Test Fixtures**:
   - Keep mock files in `lib/data/mock/` and `lib/features/*/models/*_mock_data.dart` exclusively for unit tests that pass them explicitly as test arguments, but sever all production UI screen imports.

---

## 11. Files Requiring Changes in Next Phase (Phase 13G-01-B)

1. `lib/screens/home/home_screen.dart` (Wire to live repositories, calculate pulse stats, stream recent items, render empty state)
2. `lib/screens/people/people_screen.dart` (Default initial lists to empty, update recent on empty)
3. `lib/screens/activity/activity_screen.dart` (Default `_allActivities` to empty)
4. `lib/screens/follow_ups/follow_ups_screen.dart` (Default `_allFollowUps` to empty)
5. `lib/screens/person/person_detail_screen.dart` (Remove `PersonProfileMockData.getProfile` fallback)
6. `lib/screens/ask/ask_screen.dart` (Remove `MockMemoryEngine` fallback in catch block, dynamic suggestions)
7. `lib/screens/capture/capture_modal.dart` (Default `_recentCaptures` to empty)
8. `lib/core/bootstrap/firebase_bootstrap.dart` (Call `RecallrDependencies.setInstance(deps)`)

---

## 12. Files That Must NOT Be Changed

1. `firestore.rules` (Fully hardened)
2. `storage.rules` (Fully hardened)
3. `lib/data/firestore/*` (All 7 Firestore repositories are clean and correct)
4. `lib/services/ai/*` (Gemini grounding and deterministic fallback are verified)
5. `lib/auth/*` (AuthService and AuthGate are verified)
6. `test/*` (Preserve all 36 test suites)