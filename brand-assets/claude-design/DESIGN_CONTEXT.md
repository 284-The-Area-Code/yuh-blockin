# Yuh Blockin — Design Context

> Paste this into Claude Design as context. It describes the app as it exists today. Attach `logo/primary/yuh-blockin-logo-stacked-1024.png` and the files in `screenshots/` alongside it.

## What does Yuh Blockin currently look and feel like?

A calm, minimal, iOS-style mobile app for anonymous, polite parking alerts in the British Virgin Islands.

- **Surfaces:** off-white `#FCFCFC` background, white cards, dark-grey text `#1C1C1E`, secondary grey `#8E8E93`.
- **Accent:** one bright accent, Action Blue `#0A84FF`.
- **Shapes and depth:** rounded corners (12-16 px; 24-28 px for sheets) and soft blue-tinted glows instead of hard shadows.
- **Type:** the system font (SF Pro / Roboto), mostly semibold, 13-17 pt.
- **Home screen:** dominated by one large blue circular button reading "YUH BLOCKIN' / Tap to alert".
- **Overall:** airy, friendly, uncluttered and reassuring.

## What visual elements define the brand?

- **The logo:**
  - "Yuh Blockin." in a bold teal stacked wordmark, with a full stop.
  - A coral car with an "x" and a rising arc, beside "Yuh".
  - The tagline "Move with respect." beneath.
- **Teal + coral.** Logo values: `#0D7493` and `#FF7670`. Code brand values: `#0B6E7D` and `#FF847C`.
- **The big circular blue hero button.** Radial gradient `#1A73E8` → `#0A84FF` → `#1662CE`, with a soft blue glow and a white megaphone icon.
- **Polite, de-escalating copy:** "Politely notify the driver blocking you", plus the four replies "Moving now", "5 minutes", "Can't move" and "Wrong car".
- **Emoji in alerts** and **green / blue / red urgency** colours.
- **Privacy cues:** shield and key icons, "Your Ownership Key", "We never see your plate number".
- **The splash:** a white-to-pale-teal (`#E8F6F8`) gradient, the full logo, and "from DezeTingz" in a teal-to-coral gradient.

## What should Claude Design preserve?

- The logo artwork exactly as supplied: no redrawing, re-lettering or recolouring.
- The tagline "Move with respect.".
- Teal and coral as the identity pair.
- The single-big-button home screen concept and the "YUH BLOCKIN'" label.
- The respectful, privacy-first tone and the four canned responses.
- The light, minimal, rounded, soft-shadow interface style.
- System typography. No custom typeface currently exists.

## What assets are authoritative?

- **Logo:** `logo/primary/yuh-blockin-logo-stacked-1024.png`, and the transparent version `logo/primary/yuh-blockin-logo-stacked-transparent.png`.
- **Colours:** `colors/colors.json` and `colors/palette.md`.
- **Type scale:** `typography/typography.md`.
- **Tokens:** `design-tokens/design-tokens.md`.
- **Real UI:** the screenshots in `screenshots/`.

## What should Claude Design avoid inventing?

- New logos, logo variants, a vector redraw presented as the original, or a new icon-only mark presented as existing.
- A new colour palette or new brand fonts.
- Features the app doesn't have. There is **no** login/password, sign-up, profile page, map, chat or country/flag picker.
- Fake users, testimonials, ratings, download counts or statistics.
- New pricing. The real prices are **$2.99 per month** and **$19.99 lifetime**.
- A different personality. Keep it respectful, calm and private, with Caribbean warmth in moderation.

## What is the current relationship between logo, colours, typography and UI?

The **logo** carries the identity colours (teal and coral). The **UI** does not: it uses an Apple-style neutral palette with blue `#0A84FF` for every interactive element. On the home screen the logo is even shown recoloured to solid blue.

**Typography** is not linked to the logo. The logo lettering is fixed artwork, and the UI uses system fonts.

Teal and coral appear in the UI only on the splash screen (background tint and the "DezeTingz" credit) and on a legacy Premium Monthly screen (teal headings, a coral subscribe button).

In short, the brand mark and the product interface currently read as two related but separate systems. Reconciling them is the main design opportunity. Any change should be deliberate and should keep the logo recognisable.
