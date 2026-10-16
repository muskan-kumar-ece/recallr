# Recallr Omni-Capture Hub Architecture v1

**Status**: LOCKED & VERIFIED  
**Version**: 1.0.0  
**Phase**: 11 — Capture / Omni-Capture Hub  
**Verification**: 100% Passing (109/109 Flutter Tests Passed, `flutter analyze` 0 warnings/0 errors)

---

## 1. Executive Summary & Product Mission

Recallr is an **AI Personal Professional Network Memory Engine**. The Omni-Capture Hub serves as the foundational **"Capture" layer** through which all professional encounters, physical visiting cards, voice memos, quick notes, whiteboard photos, and shared documents enter Recallr's memory system.

The core question it solves:

> **"What happened, who was involved, and what context should Recallr remember?"**

It operates as the first stage of Recallr's 5-stage loop:
CAPTURE -> UNDERSTAND -> REMEMBER -> ASK -> ACT

---

## 2. Capture Modalities & Semantic Hierarchy

| Capture Mode | Enum Key | Visual Icon | Design Token Accent | Input Mechanism | Extraction Output |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Business Card** | `businessCard` | `Icons.badge_outlined` | `RecallrColors.warmAmberGold` | Viewfinder scanner preview & optical text recognition | Name, title, company, email, phone, investment focus |
| **Voice Memo** | `voice` | `Icons.mic_none_rounded` | `RecallrColors.aiElectricViolet` | Pulse microphone recorder with live timer & waveforms | Transcribed conversation takeaways, commitments & timing |
| **Quick Note** | `note` | `Icons.edit_note_rounded` | `RecallrColors.aiCyanHighlight` | Rapid multi-line note form with entity association inputs | Structured meeting notes, takeaways & person context |
| **Capture Photo** | `photo` | `Icons.camera_alt_outlined` | `RecallrColors.aiCyanHighlight` | Visual artifact selector (whiteboard, slide, badge, diagram) | Attached image preview & extracted architectural context |
| **Add Document** | `document` | `Icons.attach_file_rounded` | `RecallrColors.warmAmberGold` | File upload selector (PDF, spec sheet, deck, quote) | Indexed document reference & company association |

---

## 3. Information Architecture & State Machine

```
OMNI-CAPTURE HUB (CaptureModal)
│
├── 1. Dynamic Header (CaptureHeader)
│   ├── Dynamic Title (Mode-aware or "Omni-Capture Hub")
│   ├── Subtitle ("Add encounters, visiting cards, and conversations to your professional memory")
│   ├── Back Button (Returns from active capture mode to idle method grid)
│   └── Close Button (Dismisses modal bottom sheet)
│
├── 2. Mode Selector & Stream (CaptureState.idle)
│   ├── CaptureMethodGrid (5 Multi-modal method cards)
│   └── Recent Captures Stream (CaptureRecentList / CaptureEmptyState)
│
├── 3. Active Capture Views (CaptureState.capturing / recording)
│   ├── BusinessCardCaptureView (Viewfinder reticle & corner guides)
│   ├── VoiceCaptureView (Pulse mic, recording timer, waveforms & stop control)
│   ├── QuickNoteCaptureView (Title, note body, and entity association matrix)
│   └── PhotoDocCaptureView (Image / file preview and context association)
│
├── 4. Processing View (CaptureState.processing / saving)
│   └── CaptureProcessingView (AI shimmer skeleton & status progress)
│
├── 5. Structured Review View (CaptureState.review)
│   └── CaptureReviewView ("WHAT RECALLR WILL REMEMBER", key takeaways, contact matrix, Edit & Save actions)
│
├── 6. Success View (CaptureState.saved)
│   └── CaptureSuccessView (Verified emerald checkmark, associated entity badges, "View Memory", "Done")
│
└── 7. Error View (CaptureState.error)
    └── CaptureErrorView (RecallrErrorState with retry & cancel recovery)
```

---

## 4. Context Association & Entity Grounding

Every captured artifact is linked directly to professional network entities:
- **Person Association**: Name, title, and person ID (links to `/person/:id`).
- **Company Association**: Organization and company ID (links to `/company/:id`).
- **Event / Encounter Association**: Summit, conference, or meeting context (e.g. *TiE Global Summit*, *Hyderabad Tech Summit*).
- **Location Association**: Meeting venue and geographic location (e.g. *HICC, Hyderabad*, *Indiranagar, Bengaluru*).
- **Date & Timing**: Capture timestamp and relative freshness.

---

## 5. Clean Architectural Separation (Capture vs Future AI)

Phase 11 strictly adheres to the intelligence boundary:
- **Capture Layer**: Pure UI/UX, input forms, state transitions, domain models, and deterministic mock engine (`CaptureEngine`).
- **Future Intelligence Layer (Phase 12+)**: Pluggable backend for OCR API, speech-to-text transcription, LLM entity synthesis, and vector embedding indexing.

---

## 6. Verification & Test Coverage Matrix

The Phase 11 test suite (`test/capture_screen_test.dart`) validates all core user flows:
1. **Capture Hub Rendering**: Header, method grid, and recent captures render cleanly.
2. **5 Capture Methods**: Business Card, Voice Memo, Quick Note, Capture Photo, and Add Document cards render.
3. **Business Card Scanner**: Opens viewfinder preview with corner guides and scan trigger.
4. **Voice Memo Recorder**: Opens mic recording interface with live timer and controls.
5. **Quick Note Form**: Opens title, note body, and entity association inputs.
6. **Photo Mode**: Opens image preview and context input fields.
7. **Document Mode**: Opens file upload preview and entity tags.
8. **Extraction & Review**: Simulates OCR extraction and displays structured memory preview.
9. **Voice Processing**: Recording finish triggers transcription synthesis to review.
10. **Custom Note Processing**: Custom title and person inputs propagate to review.
11. **Save Action & Success View**: Commits to permanent memory and displays verified confirmation.
12. **View Memory Navigation**: Navigates to target entity route (`/interaction/:id` or `/person/:id`).
13. **Empty Recent Captures**: Displays empty state message when no captures exist.
14. **Error Recovery**: Displays error message with retry and cancel recovery actions.
15. **Back Navigation**: Back button returns from active mode to method grid.
16. **Recent Capture Navigation**: Tapping recent item navigates to entity route.
17. **Home Capture Entry**: Tapping *Capture an Encounter* on Home opens canonical modal.
18. **People Empty State Capture**: Tapping *Capture First Person* on People opens modal.
19. **Ask Empty State Capture**: Tapping *Capture First Encounter* on Ask opens modal.
20. **Activity Empty State Capture**: Tapping *Capture First Encounter* on Activity opens modal.
21. **Follow-ups Empty State Capture**: Tapping *Capture First Encounter* on Follow-ups opens modal.
22. **Responsive Layouts & Zero Overflow**: Verified across 360dp, 390dp, 430dp, 768dp, 1024dp, 1440dp.