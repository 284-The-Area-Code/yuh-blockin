# YuhBlockin — Brand Source of Truth

**Status:** Consolidated from verified project sources only. Nothing in this
document is invented — every claim below cites the file(s) it was verified
against. Where something could not be verified, it is marked `UNKNOWN`.

**Compiled:** 2026-09-28

---

## 1. VERIFIED PRODUCT FACTS

- **App name:** "Yuh Blockin" (iOS `CFBundleDisplayName`, Android
  `android:label`) / "Yuh Blockin'" (with apostrophe, used in logo, ToS, and
  marketing copy). Both forms are real and in current use — the apostrophe
  form is the brand-facing one.
- **Bundle/package ID:** `com.yuhblockin.v1` (both iOS `PRODUCT_BUNDLE_IDENTIFIER`
  and Android `applicationId`).
- **Current version:** `1.0.0+31` (`pubspec.yaml`).
- **Core mechanic (verified by reading `_handleAlertTap`/`_sendInlineAlert` in
  `lib/main.dart`, and by live-testing the actual flow this session):** a user
  taps the home-screen hero button → chooses "I'm Blocked" (free) or "I'm
  Blocking" (marked `PRO` in the UI) → enters the other vehicle's plate →
  picks an emoji + urgency level → sends. The target device (if that plate is
  registered) receives a notification and the alert appears in their Alert
  History "Received" tab.
- **Identity model:** anonymous. Accounts are created via Supabase anonymous
  sign-in with no manual login (`SimpleAlertService`, confirmed in code and by
  testing). A "Secret Ownership Key" is generated per registered plate for
  recovery — explicitly one-way ("This key will never be shown again... we
  cannot recover it for you"), confirmed live during testing.
- **Safety mechanisms (shipped, verified in code this session):** Hide,
  Report, and Block-sender actions on any received alert
  (`lib/features/premium_alert/alert_history_screen.dart`); reports are
  insert-only into a `reports` table with **no automated notification** —
  review is manual via an internal admin tool only (see §10 for the
  implication of this).

## 2. VERIFIED BRAND ASSETS

- **Primary logo:** `assets/images/logo_transparent.png` — stacked wordmark
  "Yuh Blockin." over tagline "Move with respect." with a car+padlock mark
  replacing part of the "h" in "Yuh".
- **App icon:** `assets/images/app_icon.png` / `app_icon_ios.png` /
  `app_icon_foreground.png` — same mark, used via `flutter_launcher_icons`
  config in `pubspec.yaml`.
- **Extracted logo colors** (programmatically sampled from the actual pixel
  data of `logo_transparent.png` and cross-checked against `app_icon.png` —
  both files agree):
  - Wordmark teal: **`#0D7493`** (clustered RGB(12–13, 115–116, 146–148) —
    small variance is anti-aliasing, not multiple colors)
  - Car/padlock coral: **`#FF7670`** (clustered RGB(255, 117–118, 112))
  - **These were not previously documented anywhere in the project.** No
    design-system file declares them. This session extracted them directly
    from the official asset files for this document.
- **Splash assets:** `assets/images/splash_logo.png`, `Premium User Splash.png`.

## 3. VERIFIED PRODUCT FEATURES

From the app's own hamburger menu (confirmed live this session) and code:
- Send Alert ("I'm Blocked" / "I'm Blocking" — the latter marked PRO)
- Alert History (Received / Sent tabs)
- Hide / Report / Block sender (per-alert)
- My Vehicles — register up to the plate limit (see §4), each with a
  recoverable Secret Ownership Key; supports multiple vehicles, one marked
  PRIMARY
- Themes (see §8)
- Alert Sounds
- My Secret Keys
- Contact & Support (in-app, includes blocked-user management and a link to
  Terms of Service)

## 4. VERIFIED PRICING

Source: `lib/config/payment_config.dart` (live config, RevenueCat-backed) and
`assets/images/AppStore_Screenshots/Premium_Screenshot_1284x2778.png` (real
App Store screenshot).

| Tier | Price | Daily alerts | Max plates |
|---|---|---|---|
| Free | $0 | 1/day | 3 |
| Premium Monthly | **$2.99/mo** | 200/day (marketed as unlimited) | 10 |
| Premium Lifetime | **$19.99** one-time | 200/day (marketed as unlimited) | 10 |

Premium marketing bullets, as they actually appear in the App Store
screenshot asset: "Multi-vehicle plate management," "Priority notifications
and alerts," "Enhanced privacy and control," "Early access to new features."
**Note:** these differ slightly in wording from the premium feature bullets
currently in `upgrade_screen.dart` live code ("Unlimited Alerts," "Priority
Features") — the screenshot asset and the live in-app copy are not perfectly
in sync. Flagged, not resolved, by this document.

## 5. VERIFIED TARGET USERS/PERSONAS

Source: `docs/Yuh_Blockin_One_Page_Flyer.pdf` (the only project document that
states this):

> Perfect For: Office Workers · Taxi Drivers · Delivery Drivers · Tourists &
> Rental Vehicles

> Launching First in the British Virgin Islands

Source: `docs/Yuh_Blockin_Branded_Marketing_Plan.pdf`:

> Target daily commuters, taxi drivers, delivery drivers, and shop staff as
> first users.

Combined verified persona list: **daily commuters / office workers, taxi
drivers, delivery drivers, shop staff, tourists & rental-vehicle drivers.**

## 6. VERIFIED POSITIONING/COPY

Existing, already-approved marketing copy (verbatim from the flyer PDF —
**this is the authoritative existing ad copy**, not something to reinvent):

> "Move with respect. Find the driver. Clear the road."
> "Instantly alert a driver when they're blocking you."
> "No names. No confrontation. Just movement."

In-app tagline (logo + splash + App Store screenshot asset, all consistent):
**"Move with respect."**

ToS §1 "Description of Service" (`docs/TERMS_OF_SERVICE.md`) uses more
generic/legal phrasing: *"a vehicle monitoring application that allows users
to: Register and monitor license plates, Receive notifications when
registered plates are detected, Access premium features through paid
subscriptions."* This does not clearly describe the actual send-alert
mechanic and reads as boilerplate — flagged as an internal inconsistency in
the existing docs, not something this document resolves.

ToS §4.1 Zero Tolerance for Abuse (verbatim, verified safety-positioning
language that any ad copy should not contradict):

> "Yuh Blockin' has zero tolerance for objectionable content or abusive
> users... Any alert can be reported directly in the App by the recipient. We
> review reports and act on them within 24 hours of receipt... You may also
> block another user directly in the App."

Privacy Policy §1.3 "Information We Do NOT Collect" (verified, supports
"anonymous"/"no personal info" claims in ad copy): Location data, Personal
identification documents, Payment card details.

## 7. VERIFIED PLATFORM INFORMATION

- iOS: bundle ID `com.yuhblockin.v1`, min iOS `13.0` (`IPHONEOS_DEPLOYMENT_TARGET`)
- Android: package `com.yuhblockin.v1`, `compileSdk 36`, `targetSdk 36`,
  `minSdk` = Flutter default (not overridden)
- Both platforms ship from a single shared Flutter/Dart codebase — no
  platform-specific branching exists in any of the UGC-safety or core-alert
  features (confirmed by code search this session)
- Support email: `dev@dezetingz.ai` (`payment_config.dart`,
  `contact_support_screen.dart`)
- URLs on file in `payment_config.dart` (not independently verified as live):
  `https://deze-tingz.github.io/yuh-blockin/{terms,privacy,support}.html`

## 8. EXISTING VISUAL IDENTITY

- **Default experience** (`lib/core/theme/premium_theme.dart`, `lightMode` —
  confirmed as the actual default in `theme_notifier.dart`): near-white
  background (`#FCFCFC`), white surfaces, Apple-system-blue accent
  (`#0A84FF`), Apple-style typography (`CupertinoSystemDisplay` on iOS). This
  is what most users see by default — it is **not** visually Caribbean-coded.
- **Premium-only themes** (locked behind subscription, opt-in, NOT default):
  `caribbean_sunset`, `premium_pink`, `cyberpunk`, `island_gold`, `bvi_pride`.
  - `bvi_pride` is explicitly documented in code comments as derived from the
    official BVI flag/coat of arms: Resolution Blue `#001F7E`, Golden Poppy
    `#F7C700`, Cadmium Green `#006124`, Philippine Red `#D00C27`.
  - `caribbean_sunset` accent: `#FF8C42`.
  - `island_gold` exists but its exact values were not extracted for this
    document (not yet needed — see §10).
- **Per explicit instruction for this document:** the BVI Pride / Island Gold
  / Caribbean Sunset premium-theme colors are documented here as **existing,
  real, in-product palettes** — not as the recommended core advertising
  identity. No project source states these are intended as the primary brand
  palette; they are one of five equal-standing premium customization options.
  Promoting any of them to "the brand palette" would be a **new creative
  decision**, not a verified fact.
- **Logo colors** (`#0D7493` teal / `#FF7670` coral, §2) are visually distinct
  from both the default blue theme and the BVI Pride palette. They are the
  one color pairing that appears consistently everywhere the brand mark
  itself appears (icon, screenshots, splash).

## 9. MARKETING ASSETS AVAILABLE

- `docs/Yuh_Blockin_Branded_Marketing_Plan.pdf` — BVI launch/marketing strategy
- `docs/Yuh_Blockin_One_Page_Flyer.pdf` — existing approved ad copy + personas
- `assets/images/AppStore_Screenshots/*.png` (4 files) + `phone_screenshots/**`
  (dozens, multiple device sizes, dated July 2026) — real, submitted App
  Store screenshots
- `assets/images/logo_transparent.png`, `app_icon*.png`, `splash_logo.png`,
  `Premium User Splash.png`
- Real app-screen recordings captured this session (outside the repo, not
  committed): `~/Videos/yuh_blockin_ad_footage/send_flow.mp4` (send-alert
  flow) and `receive_flow.mp4` (Hide/Report/Block menu on a real received
  alert)
- `docs/marketing/ad_campaign_30s/` — a prior 30-second live-action ad
  concept (strategy/storyboard/script) produced **before** this audit and
  before the Ad Studio skill was reviewed. **Superseded (2026-09-29):** the
  user has decided the Ad Studio's direction (stylized 3D animated,
  human-free, 9:16 vertical, 15–20s) is what YuhBlockin advertising should
  pursue going forward. Kept for reference only, marked superseded in its own
  README, not deleted.

## 10. UNKNOWN / UNDECIDED BRAND QUESTIONS

- No formal brand guideline document existed anywhere in the project before
  this one — brand truth was scattered across code, PDFs, and asset files
  with no cross-references.
- Logo colors (`#0D7493` / `#FF7670`) have never been formally declared in
  any design-system file — they were extracted from pixels for this document
  only. Whether these are the "official" intended values (vs. e.g. a
  rounder/simpler hex the original designer intended) is `UNKNOWN`.
  `island_gold` theme's exact hex values were not extracted — `UNKNOWN` in
  this document (available in `premium_theme.dart` if needed).
  Android `minSdk` exact numeric value is `UNKNOWN` from this audit (defined
  by Flutter's default, not overridden in `build.gradle.kts`).
  Whether the support/terms/privacy GitHub Pages URLs in `payment_config.dart`
  are actually live/current is `UNKNOWN` — not checked this session.
  The discrepancy between App Store screenshot premium bullets and live
  `upgrade_screen.dart` copy (§4) — which is authoritative — is `UNKNOWN`/unresolved.

## 11. ADVERTISING DECISIONS — ALL LOCKED (2026-09-29)

All previously-open advertising decisions have been locked by explicit user
approval. These are decisions, not verified product facts — kept separate
from §1–§10 on purpose. Full detail in §12.

- Creative direction: **LOCKED, REVISED (2026-09-30)** — 2D flat/vector
  animation with subtle depth (Slack/Spotify-explainer-style), human-free,
  vehicle-led. Supersedes the original stylized-3D direction locked
  2026-09-29 — see §12 for the full revision history and why. Shots 1 & 2
  already generated in 3D under the old direction are paused, not deleted;
  `docs/marketing/ad_campaign_30s/` (the live-action concept, distinct from
  this) remains separately superseded and must not influence new concepts
  unless explicitly requested.
- Format: **LOCKED** — 9:16 vertical, default runtime 15–20s.
- Advertising palette: **LOCKED** — logo colors (`#0D7493` teal / `#FF7670`
  coral) as primary brand accents, not the premium in-app themes. See §12.
- Copy direction: **LOCKED** — existing flyer language as foundation, new
  copy permitted only if derived from verified product facts. See §12.

## 12. LOCKED ADVERTISING DECISIONS (official record)

Locked by explicit user instruction, 2026-09-29. These govern all Ad Studio
work going forward unless the user changes them explicitly.

### Creative direction

**Revision history:**
- 2026-09-29 — locked as stylized 3D animation (see git history of this file
  for the original wording).
- 2026-09-30 — user asked for a "friendlier, cartoonify" feel; research was
  done into how to achieve "friendly but premium, not childish/trashy" 3D
  looks (Pixar-adjacent styling, anti-childish negatives). User then reversed
  course mid-discussion ("No 3D... Stick to 2D") and locked **2D flat/vector
  with subtle depth** instead — explicitly matching the "3D is too heavy"
  instinct. This is the current, governing direction.

**Current locked direction (2D):**
- 2D flat/vector animation with subtle parallax/depth layering — not fully
  flat single-plane, not full 3D. Reference points: Slack's and Spotify's
  explainer-video style — simplified character/vehicle shapes, bold-but-muted
  (not pastel) color palette, restrained detail, smooth rigged-feeling
  movement.
- Human-free, vehicle-led storytelling
- Premium, contemporary, approachable — friendly without being childish,
  goofy, cheesy, or cartoonishly exaggerated. Avoid bright saturated
  "kids'-show" palettes and slapstick/bouncy motion.
- Caribbean/BVI environment (still applies — expressed through 2D
  background/environment illustration rather than 3D-rendered scenery)
- 9:16 vertical, default runtime 15–20 seconds
- `docs/marketing/ad_campaign_30s/` (live-action concept) is reference-only
  and must not influence new concepts unless explicitly requested
- Shots 1 & 2 generated under the prior 3D direction (real still images +
  animated clips, stored in `advertising/references/stills/` and
  `~/Videos/yuh_blockin_ad_footage/generated/`) are **paused, not deleted** —
  they no longer match the governing style and should not be used in the
  final piece unless the direction reverts again

### Advertising palette
- Primary brand accents: **Teal `#0D7493`, Coral `#FF7670`** (the actual logo
  colors, §2) — **not** `bvi_pride`, `island_gold`, or `caribbean_sunset`
  in-app premium theme colors, which remain product-only and are not
  promoted into the advertising identity
- Supporting palette: natural Caribbean/BVI environmental colors around those
  accents — ocean, tropical vegetation, roads, buildings, sky, sunlight,
  sunset atmosphere
- When real app UI is shown on screen, its actual interface colors must be
  preserved as-is — never recolored to match the advertisement's palette

### Copy direction
- Foundation (existing, approved, verbatim from the flyer, §6): **"Move with
  respect. Find the driver. Clear the road."**
- Supporting line: **"No names. No confrontation. Just movement."**
- New copy is permitted when useful, but must be derived from verified
  product facts in this document (§1–§7) — never invented capabilities,
  claims, statistics, partnerships, or outcomes
- Tone: confident, modern, concise, culturally aware, respectful, useful,
  memorable. Avoid generic AI-advertising language and exaggerated claims.

### Product authenticity (non-negotiable — unaffected by the 3D→2D revision)
- Generated 2D environments/vehicles/motion are fine for the illustrated
  world (this line updated 2026-09-30 to match the current 2D direction;
  the underlying rule is unchanged)
- Never generate fake YuhBlockin UI when real UI is available — use actual
  logo assets, real screenshots, or real recorded app footage (§9) instead
- Never invent product features, pricing, or alter the meaning of the actual
  product mechanic (§1, §3, §4)
