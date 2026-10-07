# Yuh Blockin — Brand Asset Pack

This folder is the single source of truth for the **existing** Yuh Blockin visual identity. It was extracted from the current Flutter app and its assets, without changing either. Nothing here is a redesign. Nothing has been invented: every colour and measurement points back to a file in the repository.

## What Yuh Blockin is

Yuh Blockin is a mobile app for resolving blocked-parking situations politely and anonymously.

- A driver registers their licence plate. It is stored only as a one-way hash.
- If someone is blocked in, they type the blocking car's plate and send a respectful alert, with an emoji and an urgency level.
- The owner gets a push notification and replies with a canned response: "Moving now", "5 minutes", "Can't move" or "Wrong car".
- Ownership of a plate is proven with a secret key (`YB-…`), not an account.

The tagline is **"Move with respect."** The app is published by **DezeTingz**. It was built for the British Virgin Islands (BVI governing law in the terms, a BVI Pride theme, a BVI launch plan), with a planned ATH Móvil (Puerto Rico) payment option.

**Platforms:** iOS and Android, from one Flutter codebase (`useMaterial3: false`, iOS-style styling). A Flutter web target exists but is unbranded. A separate WordPress landing page lives in `yuhblockin-site/`.

## What's in this pack

| Folder | Contents |
|---|---|
| `logo/primary/` | **Authoritative logo.** Stacked lock-up: "Yuh Blockin." with the coral car-and-arc symbol and the tagline. 1024 px and a transparent crop. |
| `logo/icon/` | App-icon source files for iOS and Android (the Android one is the adaptive foreground). |
| `logo/light/` | The splash-screen logo file (logo on white). |
| `logo/dark/` | An existing dark-background rendering ("Premium User Splash"). This is a stylised mockup and **is not used in the app**. |
| `logo/original/` | Historical files: the original four-concept logo sheet and the App Store promo artwork with pricing. Reference only. |
| `colors/` | `palette.md` (readable) and `colors.json` (machine-readable). Every value has its source. |
| `typography/` | `typography.md`. There are no custom fonts, so `fonts/` is intentionally empty. |
| `icons/app-icon/` | Exported app icons as shipped: the iOS `AppIcon.appiconset`, the Android launcher and Play Store icon, and the web favicon and PWA icons. |
| `components/` | `component-reference.md`: every live screen and component, with measurements. |
| `screenshots/` | 10 real captures of the app (onboarding, splash, home, send alert, plate registration, premium). |
| `design-tokens/` | `design-tokens.md`: spacing, radius, borders, shadows, sizes, motion. |
| `claude-design/` | `DESIGN_HANDOFF.md` (the full brief) and `DESIGN_CONTEXT.md` (the short version to paste into Claude Design). |

## What is authoritative

- **Logo:** `logo/primary/yuh-blockin-logo-stacked-1024.png`. It is byte-identical to `assets/images/app_icon.png`, the file the app shows on the splash and onboarding screens, and to the master icon in `assets/yuh_blockin_full_icon_set/`. Use `logo/primary/yuh-blockin-logo-stacked-transparent.png` on non-white backgrounds.
- **Identity colours:** teal and coral, taken from the logo. Use the logo-sampled values (`#0D7493` and `#FF7670`) when matching the mark. The code's named brand colours (`#0B6E7D` and `#FF847C`) are close but not identical. See the conflicts below.
- **Interface colours:** the default Light theme in `lib/core/theme/premium_theme.dart`. That means background `#FCFCFC`, surface `#FFFFFF`, text `#1C1C1E` / `#8E8E93` and Action Blue `#0A84FF`.
- **Typography:** the platform system font (SF Pro on iOS, Roboto on Android) with the type scale in `typography/typography.md`.
- **Screenshots:** the files in `screenshots/` are real captures that were already in the repository.

## What should not be modified

- **The logo files.** No vector version exists. Do not trace, redraw, recolour or re-letter the logo without a deliberate decision, and keep the full stop in "Yuh Blockin.".
- **The tagline:** "Move with respect."
- **The coral car-and-arc symbol and its pairing with the teal wordmark.**
- **The originals in `assets/`, `ios/`, `android/` and `web/`.** This pack holds copies. Change the originals only as part of an approved implementation.

## Important brand considerations

1. **The logo is raster only.** The largest version is 1024 × 1024 PNG. There is no SVG, no icon-only mark, and no official light or dark variant. Producing a vector master is the most valuable next step, as a faithful trace that someone approves, not a redesign.
2. **Two colour worlds.** The logo is teal and coral, but the everyday UI is Apple-style blue (`#0A84FF`). On the home screen the logo is even recoloured to solid blue (`ColorFilter srcIn`). Whether the identity colours should carry through to the UI is the main open question for a redesign.
3. **Inconsistent teal and coral values.** The logo, the app code and the website each use slightly different teal and coral values. See `colors/palette.md`, section 7.
4. **Name spelling varies.** "Yuh Blockin." (logo), "Yuh Blockin'" (app title), "YUH BLOCKIN'" (hero button) and "Yuh Blockin" (store label and notifications) all appear.
5. **Tone.** Respectful, calm and community-minded, with a Caribbean voice: "Easy nuh!" and "Walk good" appear in config copy. The interface itself is restrained and iOS-like.

## What is missing

These are honest gaps. Nothing was fabricated to fill them.

- No vector logo, icon-only mark, or monochrome or dark logo variant.
- No custom font files.
- No custom icon set. The app uses Material Icons, with some Cupertino Icons.
- No screenshots of Settings, Alert History, Theme picker, Secret Keys, Go Premium, the paywall, or the incoming-alert banner. The app could not be run in the environment where this pack was built (no Flutter SDK). These should be captured from a device build.
- The existing screenshots date from December 2025 (WhatsApp exports at 592 × 1280). They may not match the newest build exactly.
