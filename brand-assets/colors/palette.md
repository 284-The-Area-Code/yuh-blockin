# Yuh Blockin — Colour Palette

Every value on this page comes from the app's source code or was sampled from an authoritative image file. The source is listed for each. The machine-readable version is [`colors.json`](colors.json).

## How the colour system is organised

Yuh Blockin uses two separate colour layers. Treat them as distinct.

1. **Identity colours (teal and coral).** These come from the logo. In the app they appear on the splash screen, in the logo, in the "from DezeTingz" footer and on the Premium Monthly screen.
2. **Interface colours (Apple-style neutrals plus Action Blue).** These are defined in `lib/core/theme/premium_theme.dart`. They drive every everyday screen in the default Light theme: home, onboarding, alerts and dialogs.

The result is that the logo is teal and coral, while the buttons people tap are blue (`#0A84FF`). This split is how the app currently works. Any redesign should change it deliberately, not by accident (see "Conflicts" below).

---

## 1. Identity colours

| Name | Hex | RGB | Where it is defined | Where it appears |
|---|---|---|---|---|
| Brand Teal | `#0B6E7D` | 11, 110, 125 | `lib/main.dart:155`, `premium_monthly_screen.dart:26` | Splash footer gradient start, Premium Monthly title, avatar circle and bullets |
| Brand Coral | `#FF847C` | 255, 132, 124 | `lib/main.dart:156` | Splash footer gradient end |
| Deep Blue | `#045C71` | 4, 92, 113 | `lib/main.dart:157` | Declared alongside the splash palette |
| Soft Teal | `#E8F6F8` | 232, 246, 248 | `lib/main.dart:158` | Splash background gradient (bottom) |
| Teal Light | `#0D8A9C` | 13, 138, 156 | `premium_monthly_screen.dart:27` | Premium Monthly accents |
| Premium Coral | `#FF6B6B` | 255, 107, 107 | `premium_monthly_screen.dart:28` | "Subscribe - Premium Monthly" button (confirmed in screenshot) |

### Logo colours (sampled from the artwork)

The logo is only available as a raster image. These are its dominant pixel colours, sampled from `assets/images/app_icon.png` and `logo_transparent.png`. The two files give identical results.

| Name | Hex | RGB | Notes |
|---|---|---|---|
| Logo Teal | `#0D7493` | 13, 116, 147 | Wordmark "Yuh Blockin." and tagline |
| Logo Coral | `#FF7670` | 255, 118, 112 | Car-and-arc symbol |

---

## 2. Interface colours: default Light theme

This is the theme first-time users see. It is defined in `lib/core/theme/premium_theme.dart:63-69`.

| Role | Name | Hex | RGB | Usage |
|---|---|---|---|---|
| Background | Background | `#FCFCFC` | 252, 252, 252 | Scaffold background |
| Surface | Surface | `#FFFFFF` | 255, 255, 255 | Cards, sheets, dialogs |
| Accent | Action Blue | `#0A84FF` | 10, 132, 255 | Hero "YUH BLOCKIN'" button, primary buttons, links, selected states, onboarding progress (confirmed in screenshots) |
| Text | Primary text | `#1C1C1E` | 28, 28, 30 | Headings and body copy |
| Text | Secondary text | `#8E8E93` | 142, 142, 147 | Body-medium text and subtitles |
| Text | Tertiary text | `#C7C7CC` | 199, 199, 204 | Captions and disabled text |
| Border | Divider | `#E5E5EA` | 229, 229, 234 | 0.5px dividers |

## 3. Interface colours: Dark theme

Defined in `premium_theme.dart:74-80`.

| Role | Hex | RGB |
|---|---|---|
| Background | `#000000` | 0, 0, 0 |
| Surface | `#1C1C1E` | 28, 28, 30 |
| Accent | `#0A84FF` | 10, 132, 255 |
| Primary text | `#FFFFFF` | 255, 255, 255 |
| Secondary text | `#8E8E93` | 142, 142, 147 |
| Tertiary text | `#48484A` | 72, 72, 74 |
| Divider | `#38383A` | 56, 56, 58 |

## 4. Semantic colours

| Role | Hex | RGB | Source | Usage |
|---|---|---|---|---|
| Success | `#34C759` | 52, 199, 89 | `alert_history_screen.dart:41` | Resolved alerts. The success check circles in onboarding and on "Plate Registered!" are green. |
| Warning | `#FF9500` | 255, 149, 0 | `alert_history_screen.dart:42` | Pending/attention states in alert history |
| Error | `#FF3B30` | 255, 59, 48 | `alert_history_screen.dart:413, 503` | Failed or negative status |
| Info / Pending | `#007AFF` | 0, 122, 255 | `alert_history_screen.dart:43` | Pending alert status |
| Payment success | `#4CAF50` | 76, 175, 80 | `ath_payment_dialog.dart:265, 425`, notification LED colour | Payment confirmation, Android notification LED |

### Alert urgency levels

| Level | Hex | RGB | Source |
|---|---|---|---|
| Low | `#34D399` | 52, 211, 153 | `alert_workflow_screen.dart:618`, `alert_sound_settings_screen.dart:32` |
| Normal | `#0A84FF` | 10, 132, 255 | `alert_sound_settings_screen.dart:33` |
| High | `#EF4444` | 239, 68, 68 | `alert_workflow_screen.dart:620`, `alert_sound_settings_screen.dart:34` |

---

## 5. Gradients

| Name | Type | Stops | Source |
|---|---|---|---|
| Splash background | Linear, top to bottom | `#FFFFFF` to `#E8F6F8` | `lib/main.dart:420-428` |
| "DezeTingz" footer text | Linear, left to right, applied as a text mask | `#0B6E7D` to `#FF847C` | `lib/main.dart:544` |
| Home hero button | Radial, centre (-0.3, -0.3), radius 1.2 | `#1A73E8` at 0, accent `#0A84FF` at 0.5, `#1662CE` at 1 | `lib/main.dart:2245-2258` |
| Home hero button (pressed) | Radial | `#1565C0`, `#1565C0`, `#0D47A1` | `lib/main.dart:2249-2253` |
| `heroGradient` | Linear, top-left to bottom-right | accent at 100% to accent at 80% opacity | `premium_theme.dart:614` |
| `subtleOverlay` | Linear, top-left to bottom-right | white at 10%, transparent, black at 5% (stops 0, 0.5, 1) | `premium_theme.dart:602` |
| Home background | Linear, top to bottom | `#F8FBFF` at 0, theme background at 0.3 and 1.0 | `lib/main.dart:1888-1899` |

---

## 6. Optional user themes

Users choose these in Settings, then Theme (`theme_settings_screen.dart`). Four of them require a Premium subscription. They are part of the product, but they are **not** the core brand palette. Full values are in `colors.json` under `themes`.

| Theme id | Premium | Background | Surface | Accent |
|---|---|---|---|---|
| `light` (default) | No | `#FCFCFC` | `#FFFFFF` | `#0A84FF` |
| `dark` | No | `#000000` | `#1C1C1E` | `#0A84FF` |
| `caribbean_sunset` | No | `#2D1B14` | `#3D2A1F` | `#FF8C42` |
| `premium_pink` | Yes | `#1A1218` | `#2A1F26` | `#FF6B9D` |
| `cyberpunk` | Yes | `#0A0A12` | `#12121C` | `#00F5FF` (secondary `#FF00FF`) |
| `island_gold` | Yes | `#0A1628` | `#142238` | `#F7C700` (secondary `#00A86B`) |
| `bvi_pride` | Yes | `#0A1628` | `#122140` | `#F7C700` (secondary `#00A86B`, tertiary `#D00C27`) |

According to the code comments, BVI Pride is based on the British Virgin Islands flag and coat of arms: Resolution Blue `#001F7E`, Golden Poppy `#F7C700`, Cadmium Green (brightened to `#00A86B`) and Philippine Red `#D00C27`.

The alert emoji system (`premium_emoji_system.dart`) also gives each emoji/message category its own accent colour. These are listed in the component reference, not here, because they are content colours rather than brand colours.

---

## 7. Conflicts and uncertainties

1. **Three teal/coral variants exist.**
   - Logo artwork (sampled): `#0D7493` and `#FF7670`.
   - App code (splash): `#0B6E7D` and `#FF847C`. Premium Monthly uses a third coral, `#FF6B6B`.
   - Website CSS (`yuhblockin-site/astra/assets/css/yuhblockin.css`): `#21819B` and `#DE5E59`.

   No single file declares which is official. The logo artwork is the most widely seen source. The code value `#0B6E7D` is the one deliberately named "Brand colors" in the code. **A decision is needed** before a redesign; see `../claude-design/DESIGN_HANDOFF.md`.
2. **The UI accent is blue, not teal.** Day-to-day interactive elements use `#0A84FF` (Apple system blue). The logo teal is not used for buttons on the main screens.
3. **The web manifest uses a Flutter default.** `web/manifest.json` sets `theme_color` and `background_color` to `#0175C2`. That is the Flutter template default, not a brand choice.
