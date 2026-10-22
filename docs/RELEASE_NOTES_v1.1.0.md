# Recallr v1.1.0 — UI/UX Redesign & Usability Release (Android)

Welcome to **Recallr v1.1.0**!

This release delivers a complete UI/UX redesign and mobile usability overhaul, transforming Recallr into a calm, focused personal memory and relationship intelligence assistant:
$$\text{CAPTURE} \longrightarrow \text{UNDERSTAND} \longrightarrow \text{REMEMBER} \longrightarrow \text{ASK} \longrightarrow \text{CONNECT}$$

---

## 📱 Download & Install

Choose the APK corresponding to your device:

| File | Architecture | Description |
| :--- | :--- | :--- |
| **`app-arm64-v8a-release.apk`** *(Recommended)* | ARM 64-bit | Optimized for modern smartphones (Samsung, Google Pixel, OnePlus, Xiaomi, etc.) |
| **`app-release.apk`** | Universal | Works on all Android devices (contains all CPU architectures) |
| **`app-armeabi-v7a-release.apk`** | ARM 32-bit | For older Android devices |
| **`app-x86_64-release.apk`** | x86_64 | For Android emulators and Chromebooks |

### 🛠️ Installation Instructions
1. Download either **`app-arm64-v8a-release.apk`** or **`app-release.apk`** directly to your phone.
2. When prompted by your mobile browser (e.g., Chrome):
   - Tap **Open** or find it in your **Files / Downloads** app.
   - If Android prompts *"For your security, your phone is not allowed to install unknown apps from this source"*, tap **Settings** and toggle **"Allow from this source"**.
3. Tap **Install** and launch Recallr!

---

## ✨ What's New in v1.1.0

### 🎨 Brand Identity & App Header
- **Official Recallr Brand Logo**: Added the custom violet/cyan node icon accompanied by the official "Recallr" wordmark into the main application bar.
- **Refined Color Palette & Typography**: Applied subtle charcoal elevation, contrast borders, and responsive font tokens.

### 📱 Mobile Usability & Input Accessibility
- **Ask Query Composer Unblocked**: Resolved the mobile layout collision where the center-docked Floating Action Button (FAB) hovered directly over the Ask composer input and submit button.
- **Dynamic Keyboard Awareness**: The FAB and center notch dynamically retract when the Ask tab is active or whenever the software keyboard is open, ensuring 100% unobstructed typing and viewing space.

### 📸 Photo & Document OCR Contact Extraction
- **Automatic Entity Extraction**: Capturing photos or document scans now runs on-device Google ML Kit text recognition paired with `OcrEntityExtractor` to automatically detect:
  - Full Name, Role / Title, Company Name, and Physical Location
  - Contact details (Phone, Email, Website)
  - Key meeting notes and bullet points
- **Resilient Multi-Modal Persistence**: Contacts and capture records are cleanly written to the active scoped People Directory and Firestore captures even if cloud media storage is unconfigured or temporarily offline.

### 🎛️ Ergonomic Capture Options Layout
- **Responsive Method Grid**: Replaced cramped vertical lists with an ergonomically spaced responsive layout (multi-column on tablets, balanced 10dp spacing on mobile).
- **Accessible Touch Targets**: All capture method cards enforce a minimum `56.0dp` touch height with distinct accent badge highlights and tactile ink-ripple feedback.

### 🧘 Calm Home Screen Architecture
- **Prioritized Daily Workflow**:
  1. Greeting & date context
  2. One-tap Ask Memory query bar
  3. Quick Capture buttons (Voice, Card, Photo/Doc, Note)
  4. Needs Attention section (guarded — displayed only when genuine actionable items exist)
  5. Recent Key Contacts & Memories
  6. Compact Memory Pulse status strip
  7. Network Intelligence exploratory card

### 🛡️ Quality & Verification
- **Zero Analysis Issues**: Passes `dart analyze lib/ test/` with 0 warnings or errors.
- **100% Test Coverage Stability**: **1,175 / 1,175** automated tests passing across navigation, OCR capture, grounded AI retrieval, Firestore security rules, and relationship intelligence.
