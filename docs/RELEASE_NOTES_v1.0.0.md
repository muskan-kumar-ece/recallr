# Recallr v1.0.0 — Production Release (Android)

Welcome to the first official production release of **Recallr**! 

Recallr is an intelligent personal relationship and encounter intelligence application built with Flutter and powered by Firebase and Google Gemini AI.

---

## 📱 Download & Install

Choose the APK corresponding to your device:

| File | Size | Architecture | Description |
| :--- | :--- | :--- | :--- |
| **`app-arm64-v8a-release.apk`** *(Recommended)* | ~33.8 MB | ARM 64-bit | Optimized for modern smartphones (Samsung, Google Pixel, OnePlus, Xiaomi, etc.) |
| **`app-release.apk`** | ~86.9 MB | Universal | Works on all Android devices (contains all CPU architectures) |
| **`app-armeabi-v7a-release.apk`** | ~27.4 MB | ARM 32-bit | For older Android devices |

### 🛠️ Installation Instructions
1. Download either **`app-arm64-v8a-release.apk`** or **`app-release.apk`** directly to your phone.
2. When prompted by your mobile browser (e.g., Chrome):
   - Tap **Open** or find it in your **Files / Downloads** app.
   - If Android prompts *"For your security, your phone is not allowed to install unknown apps from this source"*, tap **Settings** and toggle **"Allow from this source"**.
3. Tap **Install** and launch Recallr!

---

## ✨ Features & Architecture Highlights

- **🧠 AI Grounded Memory & Ask System**: Query your network and recall encounters with contextual grounding via secure Cloud Functions backend proxy (`generateGroundedAnswer`).
- **📇 Omni-Capture Suite**:
  - OCR Business Card Scanning powered by Google ML Kit.
  - Device audio voice note recording with waveform visual feedback.
  - Manual contact and interaction logging.
- **🌐 Relationship & Network Intelligence**:
  - Entity resolution linking captures to people and organizations.
  - Interaction history, recency scoring, and follow-up reminders.
- **🔒 Production Hardened**:
  - Application ID: `com.recallr.app`
  - Signed with official release keystore (`recallr-release-key`).
  - Google Sign-In & Email Authentication integrated with SHA-1 registered OAuth credentials.
  - Full R8 ProGuard bytecode shrinking and resource optimization enabled.
  - Zero client-side API key leaks (all Gemini AI requests proxied through trusted Firebase Functions).
