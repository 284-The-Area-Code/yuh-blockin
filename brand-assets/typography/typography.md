# Yuh Blockin — Typography

## Summary

- **The app ships no custom fonts.** There are no `.ttf` or `.otf` files in the repository, and `pubspec.yaml` declares no `fonts:` block. The `fonts/` folder here is therefore empty on purpose.
- **The app uses the platform system font.**
  - iOS: SF Pro, through the `CupertinoSystemDisplay` family, which gives correct SF Pro Display/Text switching.
  - Android: Roboto.
  - Source: `lib/core/theme/premium_theme.dart`, `fontFamily = null` and `_iosFontFamily`.
- **Emoji fallback chain:** Noto Color Emoji, Apple Color Emoji, Segoe UI Emoji, Segoe UI Symbol, Noto Sans Symbols.
- **The logo lettering is part of the artwork.** "Yuh Blockin." and "Move with respect." exist only inside the raster logo images. The typeface used in the logo is not named anywhere in the project, and no font file for it exists. Do not try to recreate the wordmark with a live font; use the logo files.
- **The marketing website uses different fonts.** `yuhblockin-site/astra` loads Google Fonts: **Poppins** (600, 700) for headings and **Inter** (400, 500, 600, 700) for body text (`functions.php:220`, `yuhblockin.css`). These are not used in the app.

## iOS letter-spacing

On iOS the theme applies Apple's official tracking values by font size (`premium_theme.dart`, `_appleLetterSpacing`). On Android, letter-spacing is `0`.

| Size (pt) | Letter-spacing (iOS) | Apple style |
|---|---|---|
| 34 and up | 0.38 | Large Title |
| 28 | 0.36 | Title 1 |
| 22 | -0.26 | Title 2 |
| 20 | -0.45 | Title 3 |
| 17 | -0.41 | Body / Headline |
| 16 | -0.32 | Callout |
| 15 | -0.23 | Subhead |
| 13 | -0.08 | Footnote |
| 12 | 0 | Caption 1 |
| 11 | 0.07 | Caption 2 |
| 10 | -0.24 | Tab label |

## Type scale

Defined in the `ThemeData.textTheme` in `premium_theme.dart`. No line-heights are set, so the platform defaults apply.

| Token (Flutter) | Role | Size | Weight | Colour (Light theme) |
|---|---|---|---|---|
| `displayLarge` | Display | 34 | 700 Bold | Primary text `#1C1C1E` |
| `displayMedium` | Heading 1 | 28 | 400 Regular | Primary text |
| `headlineLarge` | Heading 2 | 22 | 400 Regular | Primary text |
| `headlineMedium` | Heading 3 | 20 | 400 Regular | Primary text |
| `titleLarge` | Title | 17 | 600 Semibold | Primary text |
| `titleMedium` | Subtitle | 16 | 500 Medium | Primary text |
| `bodyLarge` | Body | 17 | 400 Regular | Primary text |
| `bodyMedium` | Body secondary | 15 | 400 Regular | Secondary text `#8E8E93` |
| `bodySmall` | Caption | 13 | 400 Regular | Tertiary text `#C7C7CC` |

## Component typography

| Element | Size | Weight | Notes | Source |
|---|---|---|---|---|
| App bar title | 18 | 600 | Primary text colour | `premium_theme.dart`, `appBarTheme` |
| Elevated (primary) button | 16 | 600 | White on accent | `elevatedButtonTheme` |
| Text button | 16 | 600 | Accent colour | `textButtonTheme` |
| Splash "from" label | 10 | 300 Light | Letter-spacing 1.5, teal at 45% opacity | `lib/main.dart:~525` |
| Splash "DezeTingz" | 15 | 400 | Letter-spacing 0.5, teal-to-coral gradient fill | `lib/main.dart:~556` |
| Product tour step counter ("1 of 4") | 12 | 700 | Letter-spacing 0.4, accent colour | `lib/core/widgets/coach_mark_tour.dart` |
| Product tour title | 18 | 700 | Primary text colour | `coach_mark_tour.dart` |
| Product tour description | 14 | Not set (inherited) | Line height 1.35, secondary text colour | `coach_mark_tour.dart` |

Most screens set many sizes inline rather than through the theme. The recurring inline sizes are listed in [`../design-tokens/design-tokens.md`](../design-tokens/design-tokens.md).

## Wordmark capitalisation and spelling

The name appears in several forms across the project:

- **"Yuh Blockin."**, with a full stop: the logo artwork.
- **"YUH BLOCKIN'"**, with an apostrophe and in upper case: the label on the home hero button (visible in screenshots).
- **"Yuh Blockin'"**, with an apostrophe: the Premium Monthly screen header and `pubspec.yaml`.
- **"Yuh Blockin"**, with no punctuation: documentation.

The logo form, **Yuh Blockin.**, is the visual mark. Settling the spelling used in body copy is an open decision.
