# Recallr v1.4.0 — New Visual Identity, Omni-Capture, Grounded Memory & Multi-Platform Release

## 📦 Downloads & Platform Binaries

### Android Release APKs
| File | Size | Architecture | Description |
| :--- | :--- | :--- | :--- |
| [**app-arm64-v8a-release.apk**](https://github.com/muskan-kumar-ece/recallr/releases/download/v1.4.0/app-arm64-v8a-release.apk) *(Recommended)* | ~34.8 MB | ARM 64-bit | Optimized for modern smartphones (Samsung, Google Pixel, OnePlus, Xiaomi, etc.) |
| [**app-release.apk**](https://github.com/muskan-kumar-ece/recallr/releases/download/v1.4.0/app-release.apk) | ~88.8 MB | Universal | Works on all Android devices (contains all CPU architectures: arm64-v8a, armeabi-v7a, x86_64) |
| [**app-armeabi-v7a-release.apk**](https://github.com/muskan-kumar-ece/recallr/releases/download/v1.4.0/app-armeabi-v7a-release.apk) | ~28.5 MB | ARM 32-bit | Optimized for older Android devices and legacy architectures |
| [**app-x86_64-release.apk**](https://github.com/muskan-kumar-ece/recallr/releases/download/v1.4.0/app-x86_64-release.apk) | ~36.8 MB | x86 64-bit | For Android Emulators, ChromeOS, and Intel/AMD-based hardware |

---

### 🌐 Web Release (Hosted & Standalone)
| Distribution | Access | Description |
| :--- | :--- | :--- |
| **Live Web App** | [**https://recallr-b0bcc.web.app**](https://recallr-b0bcc.web.app) | Production web version with App Check, Razorpay UPI/Card payments, and responsive navigation |
| **Standalone Web Bundle** | [**recallr-web-release.zip**](https://github.com/muskan-kumar-ece/recallr/releases/download/v1.4.0/recallr-web-release.zip) (~13.6 MB) | Pre-compiled static release bundle ready for deployment on Firebase Hosting, Netlify, or Vercel |

---

### 🍏 iOS Deployment
| Target | Status & Instructions |
| :--- | :--- |
| **TestFlight / App Store** | Automated build workflow in `.github/workflows/ci_cd.yml` (`build_ios_release`) runs on macOS runners to compile unsigned IPA and release archives. |
| **Local macOS Build** | Run `flutter build ipa --release --export-options-plist=ios/ExportOptions.plist` with your Apple Developer Team ID. |

---

## 🚀 What's New in Recallr v1.4.0

### 🎨 1. Full UI/UX Redesign & Obsidian Visual Identity
- **Dark-First Aesthetics**: High-contrast obsidian dark palette (`#0D0D11` base, `#16161A` charcoal cards, `#9079FB` electric violet, `#22D3EE` cyan highlight).
- **Home Dashboard v2**: Dynamic welcome carousel, 2×2 Latest Things navigation grid (People, Memories, Activity, Connections), and Stay Connected action hubs.
- **Relationship Attention Hub**: Priority card surfacing active relationship cadences and recommended reconnection timing.
- **Enhanced Contrast & Accessibility**: Slate 400 typography tokens ensuring full WCAG AA readability in daylight and dark environments.

### ⚡ 2. Omni-Capture Hub & Entity Resolution
- **5 Input Modalities**: Quick Note, Visiting Card Scanner, Voice Memo, Photo Capture, and Document attachments.
- **Structured Review Flow**: AI extraction of takeaways, category tags, and automatic duplicate detection.
- **Instant Entity Resolution**: Real-time linking to existing dossiers (`✨ Matched to Priya Sharma`) with live Firestore reactivity.

### 🧠 3. Grounded Memory & Search (Ask AI)
- **Grounded Memory Claims**: Answers cite verified Firestore records with zero hallucinated context.
- **Citations & References**: Inline citation count badges, Referenced People cards, and expandable evidence sources.
- **Pre-Canned Inquiries**: One-tap prompts (`⚡ Who did I meet recently?`, `🤝 What did I promise?`).

### 📇 4. QR Identity & Digital Visiting Card
- **QR Bio Modal**: Dual-tab bottom sheet with shareable contact QR, copyable identity link, and simulated camera scanner.
- **Digital Visiting Card**: Interactive preview card with verified member badge, NFC icon, and instant vCard 3.0 export.

### 📊 5. Chronological Activity & Network Intelligence
- **Activity Timeline**: Dedicated filter chips (Notes, Meetings, Calls, People), search, note sharing, and encounter deletion with undo.
- **Network Health Dashboard**: Relationship health score (85/100), distribution tiers (Strong, Active, New, Cooling), and momentum telemetry.
- **Follow-ups & Commitments**: Tracking schedules, completion status, and encounter linking.

### 💳 6. Subscription Tiers & Razorpay Gateway
- **Interactive Quota Management**: Real-time AI credit and cloud storage capacity gauges.
- **Multi-Currency Pricing**: INR (₹) and USD ($) live currency toggle with instant recalculation.
- **Credit Top-Up Packs**: Micro (+25 queries) and Power (+100 queries) packs with Razorpay checkout integration.

---

## 🧪 Verification & Quality
- **1,248 / 1,248 Automated Tests Passing (100% Pass Rate)**.
- **E2E Browser Audit**: All 13 flows, sheets, modals, and buttons verified via Chrome DevTools.
- **Zero Static Analysis Errors**: Clean `flutter analyze` across all production targets.
