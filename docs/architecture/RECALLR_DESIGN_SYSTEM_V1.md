# Recallr — Phase 03 Design System Specification v1
**Developer Reference & Visual Foundation Manual**

*Document Status:* **READY FOR REVIEW**  
*Version:* `1.0.0`  
*Target Framework:* Flutter (iOS, Android, Web) + Material 3 (Dark-First Pro Custom Theme)  
*Companion Documents:*  
- Recallr Data & Memory Architecture v1 (LOCKED)  
- Recallr UI Architecture v1 (LOCKED)  

---

## 1. Design Principles

The Recallr design system is built to make personal professional memory feel **calm, intelligent, fast, and trustworthy**.

```
    ┌─────────────────────────────────────────────────────────────┐
    │                 RECALLR DESIGN SYSTEM PILLARS               │
    ├───────────────────────────┬─────────────────────────────────┤
    │ 1. Dark-First Precision   │ Obsidian base, crisp 1px subtle │
    │                           │ borders, no muddy drop-shadows. │
    ├───────────────────────────┼─────────────────────────────────┤
    │ 2. High-Density Clarity   │ Disciplined typography hierarchy│
    │                           │ optimized for skimming dossiers.│
    ├───────────────────────────┼─────────────────────────────────┤
    │ 3. Restrained Accents     │ Electric Violet & Cyan for AI;  │
    │                           │ Amber for promises; Emerald for │
    │                           │ verified truth.                 │
    ├───────────────────────────┼─────────────────────────────────┤
    │ 4. WCAG 2.1 AA Compliance │ Minimum 48x48dp touch targets,  │
    │                           │ >= 4.5:1 text contrast, dynamic │
    │                           │ type scaling up to 200%.        │
    └───────────────────────────┴─────────────────────────────────┘
```

---

## 2. Color Tokens & Semantic Architecture

Implemented centrally in `lib/core/theme/recallr_colors.dart` and provided via `ThemeExtension<RecallrThemeColors>`.

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                               RECALLR COLOR PALETTE                                    │
├───────────────────────┬───────────┬────────────────────────────────────────────────────┤
│ Token Name            │ Hex Code  │ Semantic Usage                                     │
├───────────────────────┼───────────┼────────────────────────────────────────────────────┤
│ `obsidianBase`        │ `#0A0A0C` │ Deep scaffold background, primary canvas           │
│ `slateSurface`        │ `#131316` │ Bottom nav, dialogs, bottom sheets, chips          │
│ `charcoalCard`        │ `#1C1C20` │ Cards, text input fills, list items                │
│ `glassOverlay`        │ `#B3131316│ BackdropFilter blurred surfaces (70% opacity)      │
│ `aiElectricViolet`    │ `#8B5CF6` │ Primary AI actions, active tabs, glowing accents   │
│ `aiCyanHighlight`     │ `#06B6D4` │ Secondary AI highlights, cursor, text button links │
│ `warmAmberGold`       │ `#F59E0B` │ Commitments, pending follow-ups, offline dots      │
│ `emeraldVerified`     │ `#10B981` │ Verified memory claims, task completions           │
│ `crimsonAlert`        │ `#EF4444` │ Errors, destructive buttons, critical alerts       │
│ `textPrimary`         │ `#F8FAFC` │ Main titles, headlines, active labels (17.5:1 ratio│
│ `textSecondary`       │ `#A1A1AA` │ Subtitles, secondary metadata, inactive icons      │
│ `textTertiary`        │ `#71717A` │ Placeholders, timestamps, disabled indicators      │
│ `borderSubtle`        │ `#27272A` │ 1px default borders on cards, inputs, dividers     │
│ `borderHighlight`     │ `#3F3F46` │ Focused input borders, hovered card outlines       │
└───────────────────────┴───────────┴────────────────────────────────────────────────────┘
```

---

## 3. Typography Hierarchy

Defined in `lib/core/theme/recallr_typography.dart` using *Inter / Geist* with system sans-serif fallback, and *JetBrains Mono* for metadata.

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              RECALLR TYPOGRAPHY SCALE                                  │
├───────────────────────┬──────┬─────────┬──────────┬────────┬───────────────────────────┤
│ Style Name            │ Size │ Weight  │ Tracking │ Height │ Usage                     │
├───────────────────────┼──────┼─────────┼──────────┼────────┼───────────────────────────┤
│ `displayLarge`        │ 30px │ w600    │ -1.0%    │ 1.2    │ Dossier contact names     │
│ `headlineMedium`      │ 22px │ w600    │ -0.5%    │ 1.25   │ Screen & section titles   │
│ `titleMedium`         │ 16px │ w500    │ 0.0%     │ 1.35   │ Card titles, button labels│
│ `bodyLarge`           │ 15px │ w400    │ 0.0%     │ 1.5    │ Notes, AI claim body text │
│ `bodyMedium`          │ 13px │ w400    │ 0.0%     │ 1.4    │ Secondary descriptions    │
│ `labelSmall`          │ 11px │ w600    │ +1.5%    │ 1.2    │ Badges, uppercase kickers │
│ `monoMetadata`        │ 12px │ w400    │ 0.0%     │ 1.4    │ Timestamps, IDs, status   │
└───────────────────────┴──────┴─────────┴──────────┴────────┴───────────────────────────┘
```

---

## 4. Spacing, Radii & Shadows

### Spacing Grid (4px / 8px)
* `xs`: `4.0dp` (tight badge padding, icon gaps)
* `sm`: `8.0dp` (compact item spacing, chip vertical padding)
* `md`: `16.0dp` (standard card padding, text field insets, section margins)
* `lg`: `24.0dp` (page vertical padding, dialog margins)
* `xl`: `32.0dp` (bottom sheet bottom padding, major section gaps)
* `xxl`: `48.0dp` (touch target boundaries)

### Border Radii
* `radiusSm` (`4.0dp`): Status badges, mini tags.
* `radiusMd` (`8.0dp`): Buttons, text field outlines.
* `radiusLg` (`16.0dp`): Cards, modal dialogs, bottom sheet top corners.
* `radiusPill` (`999.0dp`): Search bar, chips, avatar circles, FAB.

### Elevation & Tonal Depth
* Depth is established via **tonal step-ups** (`obsidianBase` $\rightarrow$ `slateSurface` $\rightarrow$ `charcoalCard`) and **1px crisp borders** (`borderSubtle`), rather than heavy drop shadows.
---

## 5. Foundation Component Catalogue (`lib/core/widgets/`)

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              17 FOUNDATION PRIMITIVES                                  │
├───────────────────────┬─────────────────────────────────┬──────────────────────────────┤
│ Category              │ Component Name                  │ Primary Function             │
├───────────────────────┼─────────────────────────────────┼──────────────────────────────┤
│ Buttons               │ `RecallrButton`                 │ Primary, secondary, AI grad. │
│                       │ `RecallrIconButton`             │ 48dp accessible icon action  │
│                       │ `RecallrTextButton`             │ Link-style text action       │
├───────────────────────┼─────────────────────────────────┼──────────────────────────────┤
│ Inputs                │ `RecallrTextField`              │ Form input with border/error │
│                       │ `RecallrSearchField`            │ Pill search with clear/voice │
├───────────────────────┼─────────────────────────────────┼──────────────────────────────┤
│ Containers            │ `RecallrCard`                   │ Charcoal card with 1px border│
│                       │ `RecallrSurface`                │ BackdropFilter glass sheet   │
├───────────────────────┼─────────────────────────────────┼──────────────────────────────┤
│ Display               │ `RecallrChip`                   │ Filter / capability tag      │
│                       │ `RecallrBadge`                  │ Verified / pending indicator │
│                       │ `RecallrDivider`                │ 1px subtle divider with label│
│                       │ `RecallrAvatar`                 │ Initials fallback or image   │
├───────────────────────┼─────────────────────────────────┼──────────────────────────────┤
│ Overlays              │ `RecallrBottomSheet`            │ Draggable glass sheet modal  │
│                       │ `RecallrDialog`                 │ Clean modal dialog container │
├───────────────────────┼─────────────────────────────────┼──────────────────────────────┤
│ States & Feedback     │ `RecallrSkeleton`               │ Shimmering placeholder loader│
│                       │ `RecallrEmptyState`             │ Vector icon & guidance       │
│                       │ `RecallrErrorState`             │ Inline error card with retry │
│                       │ `RecallrOfflineIndicator`       │ Slim top offline banner      │
└───────────────────────┴─────────────────────────────────┴──────────────────────────────┘
```

---

## 6. Accessibility & Compliance (WCAG 2.1 AA)

1. **Touch Target Dimensions:**  
   Every interactive element enforces `constraints: BoxConstraints(minWidth: 48, minHeight: 48)`.
2. **Text Contrast Ratios:**  
   `textPrimary` on `obsidianBase` achieves **17.5:1** contrast ratio (far exceeding the 4.5:1 WCAG minimum).
3. **Screen Reader Semantics:**  
   All buttons, badges, and search inputs contain `Semantics(button: true, label: ...)` annotations.
4. **Dynamic Text Scaling (up to 200%):**  
   Components use `Wrap`, `Flexible`, and adaptive flex sizing to accommodate large system fonts without clipping.
5. **Reduced Motion Adaptation:**  
   `RecallrSkeleton` and transitions observe `MediaQuery.of(context).disableAnimations` and fall back to static representations.

---

## 7. Developer Usage & Do / Don't Guide

```dart
// RECOMMENDED USAGE:
import 'package:recallr/core/theme/theme.dart';
import 'package:recallr/core/widgets/widgets.dart';

Widget build(BuildContext context) {
  final colors = context.colors;
  
  return RecallrCard(
    child: Column(
      children: [
        Text("Rajesh Sharma", style: RecallrTypography.titleMedium),
        RecallrSpacing.gapSm,
        RecallrChip(label: "PCB Design", isSelected: true),
        RecallrSpacing.gapMd,
        RecallrButton(
          label: "Log Catchup",
          variant: RecallrButtonVariant.primary,
          onPressed: () => {},
        ),
      ],
    ),
  );
}
```

### Strict Do's and Don'ts

| Practice | DO | DON'T |
| :--- | :--- | :--- |
| **Colors** | Use `RecallrColors.obsidianBase` or `context.colors` | Never hardcode raw hex values like `Color(0xFF112233)` |
| **Spacing** | Use `RecallrSpacing.md` or `RecallrSpacing.gapMd` | Never scatter magic padding like `EdgeInsets.all(13.5)` |
| **Typography**| Use `RecallrTypography.titleMedium` | Never create ad-hoc `TextStyle(fontSize: 17, ...)` |
| **Cards** | Use `RecallrCard` with standard 1px border | Never use default Material 3 cards with elevation shadows |
| **Buttons** | Use `RecallrButton` with defined variants | Never mix in unstyled `ElevatedButton` widgets |

---

## 8. Future Component Extension Rules (Phase 04+)

* Product-specific cards (`PersonCard`, `CompanyCard`, `InteractionCard`, `MemoryClaimCard`, `FollowUpCard`, `AIAnswerCard`) will be composed directly using these foundation primitives in their respective feature packages.
* No domain logic, Firestore references, or AI pipeline code may be introduced into `lib/core/`.

---

### DESIGN SYSTEM STATUS
`READY FOR REVIEW`