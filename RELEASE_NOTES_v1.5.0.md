## Recallr v1.5.0 — Card Network, Categories, Public Digital Cards & Multi-Platform Release

### 📦 Downloads & Platform Binaries

#### Android Release APKs
| File | Size | Architecture | Description |
| :--- | :--- | :--- | :--- |
| [**app-arm64-v8a-release.apk**](https://github.com/muskan-kumar-ece/recallr/releases/download/v1.5.0/app-arm64-v8a-release.apk) *(Recommended)* | ~33.8 MB | ARM 64-bit | Optimized for modern smartphones (Samsung, Google Pixel, OnePlus, Xiaomi, etc.) |
| [**app-release.apk**](https://github.com/muskan-kumar-ece/recallr/releases/download/v1.5.0/app-release.apk) | ~86.9 MB | Universal | Works on all Android devices (contains all CPU architectures) |
| [**app-armeabi-v7a-release.apk**](https://github.com/muskan-kumar-ece/recallr/releases/download/v1.5.0/app-armeabi-v7a-release.apk) | ~27.4 MB | ARM 32-bit | For older Android devices |
| [**app-x86_64-release.apk**](https://github.com/muskan-kumar-ece/recallr/releases/download/v1.5.0/app-x86_64-release.apk) | ~36.8 MB | x86 64-bit | For Android Emulators & ChromeOS |

#### 🌐 Web Release (Hosted & Standalone)
| File | Size | Architecture | Description |
| :--- | :--- | :--- | :--- |
| [**recallr-web-release.zip**](https://github.com/muskan-kumar-ece/recallr/releases/download/v1.5.0/recallr-web-release.zip) | ~14.3 MB | Web Static Bundle | Pre-compiled static HTML5 / CanvasKit release bundle ready for deployment (Nginx, S3, Cloudflare) |
| [**Live Web App**](https://recallr-b0bcc.web.app) | Cloud PWA | Universal Web | Production instance with App Check, Razorpay checkout, and real-time synchronization |

#### 🍏 iOS Deployment
| Target | Architecture | Distribution | Description |
| :--- | :--- | :--- | :--- |
| **TestFlight / App Store** | ARM64 | Apple Developer Program | Automated CI/CD workflow compiles release IPA archives in `.github/workflows/ci_cd.yml` (`build_ios_release`). |
| **Local Archive** | ARM64 | Xcode | Direct compilation via `flutter build ipa --release` |

---

### 🌟 What's New in v1.5.0

#### 1. Sovereign Card Network & Public Digital Identity Cards
- **Self-Sovereign Digital Cards**: Design and manage personal visiting cards with custom accent themes, layout preferences, and fine-grained field-level visibility controls (name, title, company, bio, phone, email, WhatsApp, LinkedIn, website).
- **Public Card Hosting**: Secure server-rendered contact views on the web (`/#/card/:id`) accessible without login, equipped with single-click "Save Contact (.vcf)" and "Connect on Recallr" hooks.
- **Cryptographic Access Control**: Dedicated Firestore security rules restrict public cards to published contact projections while preventing unauthorized modifications.

#### 2. Frictionless QR Code Exchange & Camera Scanner
- **Instant Peer-to-Peer Networking**: Generate high-contrast, scalable QR codes (`qr_flutter`) containing serialized card blueprints for instant in-person networking.
- **Embedded Hardware Scanner**: Fast, native camera barcode scanner (`mobile_scanner`) with Android SDK 35 compatibility for importing contacts directly into your personal memory network in milliseconds.

#### 3. Dynamic Category Taxonomies & Multi-Facet Filtering
- **Custom Categorization**: Organize contacts and relationships across custom multi-color taxonomies (*Investors*, *Advisors*, *Portfolio Founders*, *Key Hires*).
- **Unified Filter System**: Effortlessly filter contacts and memories by category chips with instant client-side reactivity and Firestore persistence.

#### 4. Web UI Freshness & Cache Invalidation Hardening
- **Zero-Stale Web Caching**: Explicit `Cache-Control: no-cache, no-store, must-revalidate, max-age=0` directives for HTML, manifest, bootstrap, and service worker scripts in `firebase.json`.
- **Automatic ServiceWorker Revalidation**: Client-side registration hooks that automatically query and install newest app builds on every page reload without requiring users to clear browser caches.

#### 5. Upgraded Serverless Architecture
- **Node.js 22 LTS Runtime**: Cloud Functions upgraded to Google Cloud's latest Node.js 22 2nd Gen runtime for lower latency, cold-start reduction, and long-term support.
- **Multi-Platform Split-per-ABI Builds**: Optimized Android binaries achieving up to **68% smaller download sizes** for users on modern 64-bit devices.

---

### 🧪 Verification & Test Suite
- **Automated Tests**: **1,252 / 1,252 Passing** (100% pass rate).
- **Security Audit**: Firestore rules, Firebase App Check attestation, and Cloud Functions input boundary validation verified.
- **Responsive E2E Audit**: Tested across mobile (`420×880`), tablet, and desktop (`1920×912`) viewports.
