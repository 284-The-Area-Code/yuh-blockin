# Yuh Blockin — UI Component Reference

This page documents the screens and components that exist in the current Flutter app. Values come from the code; file paths and line numbers are listed so each one can be checked. "Accent" means the theme accent colour, which is `#0A84FF` in the default Light and Dark themes.

Screenshots referenced below are in [`../screenshots/`](../screenshots/).

> **Some code is never shown to users.** `AlertWorkflowScreen`, `AlertConfirmationScreen` and `PremiumMonthlyScreen` are not reachable from any navigation. The emoji-pack modal is only used by those screens. The home screen's floating bottom bar (`_buildFloatingBottomBar`) and `_buildStatsCounters` are unused. They are noted here for completeness and marked **(unreachable)**. Do not treat them as the current design.

---

## Screen map

| Screen | Reached from | Screenshot |
|---|---|---|
| Splash (`AppInitializer`) | App launch | `screenshots/other/splash.jpeg` |
| Onboarding, 3 pages | First launch | `screenshots/onboarding/` (01-welcome, 02-privacy, 03-all-set) |
| Home (`PremiumHomeScreen`) | After onboarding | `screenshots/home/home.jpeg` |
| Alert-type sheet ("What would you like to do?") | Tap hero button | `screenshots/home/home-action-sheet.jpeg` |
| Inline Send Alert card | Pick "I'm Blocked" | `screenshots/alerts/send-alert.jpeg` |
| Incoming alert banner | Receiving an alert | none |
| My Vehicles / plate registration | Home menu, onboarding | `screenshots/other/plate-registered-ownership-key.jpeg` (success dialog) |
| Alert History | History button | none |
| Theme Settings | Home menu, then Themes | none |
| Alert Sounds | Home menu, then Alert Sounds | none |
| My Secret Keys | Home menu | none |
| Recover Your Account (login with key) | Onboarding page 1 link | none |
| Go Premium (`UpgradeScreen`) | Subscription badge, paywall | none |
| Paywall dialog | Hitting the daily limit or a premium feature | none |
| Subscription status | Subscription badge | none |
| Premium Monthly **(unreachable)** | none | `screenshots/premium/*` (App Store submission captures) |

**Login, sign-up and profile screens do not exist.** The account is anonymous: a licence plate is stored as a hash and ownership is proven with a secret key (`YB-XXXX-XXXX-XXXX-XXXX`). The nearest equivalents are "Recover Your Account" (`login_with_key_screen.dart`) and "My Secret Keys" (`view_my_keys_screen.dart`).

---

## 1. Splash (`lib/main.dart:400-560`)

- **Background:** linear gradient, top to bottom, `#FFFFFF` to `#E8F6F8`.
- **Logo:** `app_icon.png` at 42% of screen width, clamped to 220-340 px, with a radial fade mask and a 2 s white shimmer at 35% opacity.
- **Footer:**
  - "from": 10/w300, letter-spacing 1.5, teal `#0B6E7D` at 45%, between two 20 px teal hairlines.
  - "DezeTingz": 15/w400, letter-spacing 0.5, filled with a teal-to-coral gradient (`#0B6E7D` to `#FF847C`).
- **Timing:** the controller runs 900 ms; the logo scales 0.92 to 1.0 with `easeOutCubic`.

## 2. Onboarding (`lib/features/onboarding/onboarding_flow.dart`)

- **Frame:**
  - App bar title "Welcome" (17/w600) and "Skip" (14/w500, secondary text).
  - Progress indicator: one 32x4 bar per page, radius 2, 8 px gap. Accent for the current and past pages, divider colour for the rest.
  - Footer buttons: "Back" (outlined) and "Get Started" / "Continue" (filled accent). Both radius 10, 14 px vertical padding.
- **Page 1:**
  - `app_icon.png` at 220 px.
  - "The respectful way to solve parking conflicts".
  - Three feature rows (radius 10, 24 px accent icons): "Privacy-First / Your data is encrypted", "Respectful / Polite notifications only", "Quick / Most cars move in 5 min".
  - Outlined link: "Already registered? Login with secret key".
- **Page 2:**
  - 70 px green gradient circle (`green.shade400` to `green.shade600`) with `verified_user_rounded`.
  - "Your Privacy Protected" (24/w600).
  - Checklist: "Military-grade encryption", "We never see your plate number", "No personal info required", "Data stays on your device".
- **Page 3:**
  - 80 px green check circle and "You're All Set!" (28/w600).
  - "Register License Plate" (radius 12, 16/w600) and "Skip for now".

## 3. Home (`lib/main.dart`, `PremiumHomeScreen`)

**Layout, top to bottom** (`_buildStaticContent`, 4867-4941):
1. Header
2. Hero button
3. History and Alerts icon buttons
4. Subscription badge
5. Active vehicle card, or the "Add your vehicle" hint
6. Activity feed
7. Branding footer

**Overall styling:**
- Horizontal padding: 32 (80 on tablet).
- Background: linear gradient `#F8FBFF` to the theme background (stops 0, 0.3, 1). A ghosted 200 px car icon sits at 2% opacity, bottom right.

### Header (`_buildAppHeader`, 1995)
- **Logo:** `logo_transparent.png` at 48 px tall (60 on tablet), **recoloured to the accent colour** using `ColorFilter srcIn`. On the home screen the logo is therefore a single-colour blue, not teal and coral. This is visible in the home screenshot.
- **Menu button:** 40x40, radius 12, surface at 80%, 1 px border in accent at 10%, `menu_rounded` icon in accent.
- **Popup menu:** radius 16, elevation 8. Items: My Vehicles, Themes, Alert Sounds, My Secret Keys.

### Hero button (`_buildHeroButton`, 2207-2320)
This is the signature element of the app.
- **Shape:** circle, 240 px (280 on tablet).
- **Gradient:** radial, centre (-0.3, -0.3), radius 1.2. Stops: `#1A73E8`, then accent `#0A84FF`, then `#1662CE`.
- **Pressed:** `#1565C0`, `#1565C0`, `#0D47A1`. Scales to 0.92 over 100 ms and triggers a medium haptic.
- **Shadow:** accent at 30%, blur 16, offset (0, 8).
- **Content:** white `campaign_rounded` megaphone icon (48), "YUH BLOCKIN'" (16/w600) and "Tap to alert" (11/w400, white at 70%).

### Icon buttons: History / Alerts (3988, 4402)
- Circular, 10 px padding, surface gradient, 1 px accent border at 10%. Icons: `trending_up`, `notifications_outlined` (18 px).
- **Count badge:** minimum 20 px, accent gradient, 2 px border in the background colour, 12/w600.
- **Labels:** 13/w500, secondary text.

### Subscription badge (2835)
- Pill: radius 20, padding 12x6, 12/w500.
- Text: "Premium" or "2/3 today".
- Icons: `workspace_premium_rounded`, `flash_on_rounded`, `warning_amber_rounded`.

### Active vehicle card (3074)
- Max width 280, padding 20x12, radius 16.
- Border: accent at 15%. Shadow: accent at 8%, blur 16, offset (0, 4).
- Content: "Your Vehicle" (12/w500) above the plate (16/w600).

### Setup hint (5056)
Accent at 6% fill, accent at 12% border, radius 16. Text: "Add your vehicle / to start receiving alerts".

### Activity feed (2378-2792)
- **Card:** radius 16, divider-colour border at 30%.
- **Rows:** 32x32 status tile (radius 8), title 13/w500, status line 11/w500.
- **Rows needing action:** 3 px orange left border, orange tint, and response chips "Moving", "5 min", "Can't", "Wrong".

### Branding footer (2322)
- "Move with respect." in 13/w400 *italic*, tertiary text at 70%.
- "DezeTingz © 2026" in 11 px at 50%.

## 4. Alerts

### Alert-type sheet (`main.dart:3233`)
- Top radius 24, 40x4 drag handle.
- Title: "What would you like to do?".
- Options:
  - "I'm Blocked": Alert the driver blocking me.
  - "I'm Blocking": Alert the driver I blocked them, with a **PRO** badge.
- Rows are radius 16 with a 48x48 icon tile (radius 12).

### Inline Send Alert card (`main.dart:5417-5975`)
- **Card:** radius 28, padding 20, surface gradient 95% to 85%, accent border at 15%. Shadows: accent at 8% blur 40, plus black at 15% blur 20.
- **Header:**
  - 4 px accent bar.
  - "Send Alert" (18/w600).
  - Subtitle: "Politely notify the driver blocking you".
  - 36 px circular close button.
- **Plate field:**
  - Radius 16, text 22/w600 centred, placeholder "ABC-1234".
  - When the plate is valid: 2 px accent border plus an accent glow.
- **Emoji picker** ("Express yourself"):
  - 40 px tiles, radius 12.
  - Emojis: 🚗 🙏 ⏰ 🚨 😊 👋.
  - The selected tile scales to 1.1 and gets an accent tint.
- **Urgency picker** ("Urgency level"):
  - Low uses `Colors.green` with a clock icon.
  - Normal uses accent with a bell icon.
  - High uses `Colors.red` with `priority_high`.
  - Tiles are radius 12.
- **Send button:**
  - Full width, radius 16, 14 px vertical padding.
  - Accent gradient (100% to 85%) with an accent shadow.
  - Label: emoji + "Send Alert" + `send_rounded` icon (15/w600).
  - Disabled: divider-colour gradient.

### Incoming alert banner (`main.dart:5146-5343`)
- Slides in from the top over 250 ms with a shake.
- **Card:** radius 14, 1.5 px border in the urgency colour at 30%.
- **Content:**
  - 36 px circular app icon.
  - "<emoji> Move Request" (14/w700).
  - "<alias> needs you to move."
  - Reply chips: "Moving Now", "5 Minutes", "Can't Move".
- **Urgency colours** (`main.dart:1162-1186`): Low `#43A047`, Normal `#1E88E5`, High `#E53935`.

### Alert History (`alert_history_screen.dart`)
- Cupertino sliding segmented control: "Received (n)" / "Sent (n)".
- Cards radius 12.
- Status colours: success `#34C759`, warning `#FF9500`, pending `#007AFF`, can't-move `#FF3B30`.
- **Empty state** (985): 72 px tile (radius 20) with a 32 px Cupertino tray or paper-plane icon, title (17/w600) and one line of help text. For example: "No alerts received" / "When someone sends you an alert, it will appear here".

### Responses
- Codes: `moving_now`, `5_minutes`, `cant_move`, `wrong_car`.
- Toast titles: "They're moving!", "Give them 5 minutes", "Can't move right now", "Wrong car!".

## 5. Plate registration (`plate_registration_screen.dart`)

- **Hero:**
  - 56 px accent gradient circle with a white car icon.
  - "My Vehicles" (26/w600) over a 40x3 accent underline.
  - Subtitle: "Register your license plate to receive alerts".
- **Input:**
  - Max width 300, radius 14, text 24/w600 centred, placeholder "ABC-1234".
  - When valid: 1.5 px accent border at 50%, an accent glow, and an 8 px green "Valid format" dot.
- **Register button:** fixed height **52**, radius 14, 15/w600, accent shadow.
- **Success dialog** (radius 24, see screenshot):
  - Green check, "Plate Registered!" and the plate in accent.
  - A gold-bordered "Your Ownership Key" box with "Copy Key".
  - A red warning box: "Save this key securely!…".
  - Full-width "I've Saved My Key" button.
- **Garage full:** "Garage Full" with an "Upgrade for 10 vehicles" pill (radius 20).
- **Country/flag display:** none. There is no country or flag selection in the code.

### Quick plate sheet (`main.dart:5991-6209`)
- Top radius 24.
- Header: "My Vehicles" with a "Manage" link.
- Active row: accent at 10% fill with an "Active" pill.
- **Empty state:** 48 px outlined car icon, "No vehicles registered", "Add your license plate to get started".

## 6. Premium and subscription

**Pricing** (`payment_config.dart`):
- Monthly $2.99, Lifetime $19.99.
- Free: 1 alert per day, 3 plates. Premium: 10 plates.

### Go Premium (`upgrade_screen.dart`)
- 56 px accent gradient circle with a star icon.
- "Go Premium" (24/w600) and "Unlock unlimited alerts".
- **Plan cards:** radius 12. The selected card gets an accent tint and a 2 px accent border, and the price is 22/w600.
- **CTA:** Cupertino filled button, radius 14.
- **ATH Móvil:** shown with a "Coming Soon" badge, which makes it disabled.

### Paywall dialog (`paywall_dialog.dart`)
- Max width 340, radius 24, `strongShadow`.
- 64 px accent gradient circle with `workspace_premium_rounded`.
- Title: "Daily Limit Reached".
- CTAs: "Upgrade to Premium" and "Maybe Later".

### Subscription status
- The Premium card uses an accent gradient with white text.
- "Premium Member" / "Free Plan" (22/w600).
- Daily-alerts progress bar.

### Premium Monthly (unreachable)
- This is the only screen styled in the **teal/coral identity colours**:
  - teal `#0B6E7D` title, avatar and bullets
  - coral `#FF6B6B` subscribe button
  - text `#1A1A1A` / `#6B7280`
- It uses a placeholder "YB" monogram instead of the logo.
- App Store screenshots of it exist in `screenshots/premium/`.

## 7. Settings

### Theme Settings (`theme_settings_screen.dart`)
- Headline: "Choose Your Vibe".
- **Free themes:** Light, Dark, Caribbean Sunset.
- **"Premium Themes":** Premium Pink, Cyberpunk, Island Gold, BVI Pride.
- **Cards:** radius 16, preview circle with a 2 px border in the theme colour.
- **Premium marking:** gradient "PRO" badge; locked cards show a lock icon and the message "Subscribe to unlock premium themes".

### Alert Sounds (`alert_sound_settings_screen.dart`)
- One sound per urgency: Low `#34D399`, Normal `#0A84FF`, High `#EF4444`.
- "Troubleshoot Notifications" section with "Fix" buttons.

### My Secret Keys / Recover Your Account
- Key-style cards with a "Secure" badge and "Copy Key".
- Recovery form: plate plus "Secret Ownership Key", button "Recover Account".

## 8. Feedback components

- **Toast** (`_PremiumToast`, `main.dart:6213`):
  - Bottom-centred, radius 12, padding 16x12.
  - Accent fill for success, `red.shade600` for errors.
  - White 24 px icon circle and 14/w600 white text.
  - Pops in with `easeOutBack` over 600 ms.
- **Offline banner:** `Colors.orange.shade700` with "No internet - alerts may be delayed".
- **Success marks:** green check circles appear in onboarding and in the "Plate Registered!" dialog.
- **Loading:** shimmer is used on the splash screen. No Lottie animations are used (the package is installed but never imported).

## 9. Unreachable code (for reference only)

- **Send Respectful Alert screen** (`alert_workflow_screen.dart`) and **Alert Status screen** (`alert_confirmation_screen.dart`).
- **Emoji packs** (`premium_emoji_system.dart`):
  - "Classic": Polite Wave, Friendly Smile, Urgent Alert and others.
  - "Gen Z Island": Coconut Chill, Wave Check, Palm Sway and others.
  - Each has its own accent colour.
- **Floating bottom bar:** the only use of a backdrop blur (sigma 20).
