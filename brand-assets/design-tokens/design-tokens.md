# Yuh Blockin — Design Tokens

The app has a small formal token set in `lib/core/theme/premium_theme.dart`. Most screens set values inline, though. This page lists both kinds:

- **Defined**: a named constant in the theme file.
- **Inferred**: the most common inline value, counted across `lib/`. These are a description of current practice, not an official scale.

## Spacing

| Token | Value | Status |
|---|---|---|
| Base unit | 8 | **Defined**: `PremiumTheme.baseUnit`, with `space(n) = 8 × n` |
| Common vertical gaps | 16 (×25), 8 (×24), 12 (×21), 20 (×17), 24 (×16), 4 (×12) | Inferred from `SizedBox` heights |
| Common horizontal gaps | 12 (×35), 8 (×26), 6 (×15) | Inferred from `SizedBox` widths |
| Screen side padding (home) | 32 (80 on tablet) | Inline, `main.dart:2303` |
| Badge padding | 6 × 2 | Inferred, the most common badge padding |
| Card padding | 12, 16 or 20 | Inferred |

In practice the scale is **4 / 6 / 8 / 12 / 16 / 20 / 24 / 32**.

## Corner radius

| Token | Value | Status | Typical use |
|---|---|---|---|
| `smallRadius` | 8 | **Defined** | Text buttons, chips, status tiles |
| `mediumRadius` | 12 | **Defined** | Primary buttons, menu button, list rows, plan cards |
| `largeRadius` | 16 | **Defined** | Cards, vehicle card, activity feed, popup menu, send button |
| `extraLargeRadius` | 24 | **Defined** | Dialogs, bottom sheets (top corners) |
| 10 | 10 | Inferred (×17) | Onboarding buttons and rows |
| 14 | 14 | Inferred (×10) | Plate input, register button, alert banner, CTAs |
| 20 | 20 | Inferred (×17) | Pills (subscription badge), empty-state tiles |
| 28 | 28 | Inferred (×4) | Inline Send Alert card |
| Full circle | — | Inline | Hero button, icon buttons, avatars |

Frequency across `lib/`: 12 (×41), 16 (×28), 8 (×25), 20 (×17), 10 (×17), 14 (×10).

## Borders

| Use | Value |
|---|---|
| Divider | 0.5 px, divider colour (**defined**, `dividerTheme`) |
| Subtle outline | 1 px, accent at 10-15% |
| Focused / valid input | 1.5-2 px, accent at 50-60% |
| Outlined button | 1.5 px, accent at 30% |
| Selected plan card | 2 px, accent |

## Shadows and elevation

Material elevation is turned off almost everywhere (`elevation: 0`). Depth comes from soft custom shadows, usually tinted with the accent colour.

| Token | Layers | Status |
|---|---|---|
| `subtleShadow` | black 4% blur 16 (0, 4) + black 2% blur 4 (0, 1) | **Defined** |
| `mediumShadow` | black 8% blur 24 (0, 8) + black 4% blur 8 (0, 2) | **Defined** |
| `strongShadow` | accent 25% blur 32 (0, 16) spread 8 + black 12% blur 48 (0, 24) | **Defined** (used on the paywall) |
| Accent glow | accent 30% blur 16 (0, 4-8) | Inferred, the most common pattern (hero button, toasts, CTAs) |
| Soft lift | black 10% blur 4 (0, 2) | Inferred, usually paired with the accent glow |

Most common blur radii: 16 (×13), 8 (×10), 12 (×9). Most common offsets: (0, 4) ×17 and (0, 2) ×15.

## Opacity

Colours are usually tinted by opacity rather than taken from separate tint swatches. The most common alpha values are 0.3 (×52), 0.1 (×43), 0.15 (×29), 0.2 (×27), 0.5 (×25), 0.08 (×17) and 0.05 (×10).

Typical pattern:
- accent at 6-10% for tinted fills
- accent at 10-15% for hairline borders
- accent at 30% for glows

## Component sizes

| Component | Size | Source |
|---|---|---|
| Hero button | 240 circle (280 on tablet) | `main.dart:2666` |
| Primary button | padding 24 × 16, radius 12, label 16/w600 | **Defined**, `elevatedButtonTheme` |
| Text button | padding 16 × 12, radius 8 | **Defined**, `textButtonTheme` |
| Register vehicle button | height 52 (48 compact), max width 260 | `plate_registration_screen.dart:1673` |
| Menu button | 40 × 40 (44 on tablet) | `main.dart:2359` |
| Icon button (home) | about 38 px (padding 10 + 18 px icon) | `main.dart:4477` |
| Count badge | minimum 20 px | `main.dart:4477` |
| Plate input | max width 300, text 22-24/w600 | inline alert, plate screen |
| Emoji tile | 40 (44 on tablet) | `main.dart:6286` |
| Onboarding progress bar | 32 × 4, radius 2 | `onboarding_flow.dart:279` |
| Bottom-sheet handle | 40 × 4 | `main.dart:3719, 6629` |
| Paywall dialog | max width 340 | `paywall_dialog.dart` |
| Product tour tooltip | padding 20/18/20/14, radius 18, black 28% shadow blur 24 (0, 10) | `coach_mark_tour.dart` |
| Product tour spotlight | scrim black at 78%; cutout padded 10 px, radius 18 (circle for the hero button), white 90% ring 2.5 px | `coach_mark_tour.dart` |

## Navigation

- **App bar:** background matches the screen, elevation 0, title 18/w600 (**defined**).
- **Home:** there is no tab bar or bottom bar. Navigation goes through the header menu (popup menu, radius 16, elevation 8; items: My Vehicles, Themes, Alert Sounds, My Secret Keys, Replay Product Tour, Contact & Support) and the History/Alerts icon buttons.
- **Page transitions:** Cupertino slide on both iOS and Android (**defined**, `pageTransitionsTheme`).

## Icon sizing

| Use | Size |
|---|---|
| Default (theme) | 24 (**defined**) |
| Menu items | 20 |
| Home icon buttons | 18 (20 on tablet) |
| Badges and pills | 12-14 |
| Hero button | 48 (56 on tablet) |
| Empty states | 32-48 |

## Motion

| Token | Value | Status |
|---|---|---|
| `fastDuration` | 150 ms | **Defined** |
| `mediumDuration` | 200 ms | **Defined** |
| `slowDuration` | 250 ms | **Defined** |
| `breathingDuration` | 4 s | **Defined** |
| `standardCurve` | `easeOut` | **Defined** |
| `breathingCurve` | `easeInOut` | **Defined** |
| `bounceCurve` | `elasticOut` | **Defined** |
| Press feedback | scale to 0.92 over 100 ms, plus haptic | Inline (hero button) |
| Toast | 600 ms `easeOutBack` | Inline |
| Product tour step change | 360 ms `easeInOutCubic`, the spotlight moves between targets | Inline (`coach_mark_tour.dart`) |
| Sender response banner | slides in over 250 ms `easeOut`, auto-dismisses after 6 s | Inline (`main.dart:1762`, `5851`) |

## Platform notes

- `useMaterial3: false`. The app uses Material 2 widgets with iOS-flavoured styling throughout: SF Pro typography, Apple system colours and Cupertino transitions.
- Tablet layouts scale most values up by about 15-25% (`isTablet` branches).
