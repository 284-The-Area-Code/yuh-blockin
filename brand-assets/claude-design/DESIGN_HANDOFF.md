# Design Handoff — Yuh Blockin

This brief describes the existing identity, which future design work should evolve. It is not a redesign proposal. Supporting detail is in `../colors/palette.md`, `../typography/typography.md`, `../design-tokens/design-tokens.md` and `../components/component-reference.md`.

## Brand

**Yuh Blockin.**, with the tagline **"Move with respect."** and the publisher credit "from DezeTingz".

"Yuh Blockin'" is Caribbean English for "you're blocking". The name is the phrase you would call out across a parking lot. The product exists so you don't have to.

## Product

Yuh Blockin is an anonymous, respectful parking-alert app for iOS and Android.

1. **Register a plate.** A driver registers a licence plate. It is hashed on the device, and the user receives a secret ownership key (`YB-XXXX-…`) instead of creating an account.
2. **Send an alert.** When someone is blocked in, they tap the large blue **YUH BLOCKIN'** button, choose "I'm Blocked" (or "I'm Blocking", a Premium option), type the plate, pick an emoji and an urgency level (Low / Normal / High), and send.
3. **Reply.** The blocking driver gets a push notification and an in-app banner, then replies with one tap: *Moving now*, *5 minutes*, *Can't move* or *Wrong car*.
4. **Track activity.** Alert history, activity feed and daily-usage counts.
5. **Stay safe.** New users must agree to the Terms of Service, including a zero-tolerance policy for abuse, before onboarding. Recipients can hide, report or block a sender from Alert History, and blocked users can be unblocked in Contact & Support.
6. **Premium.** $2.99 per month or $19.99 lifetime, through the App Store or Google Play. Premium unlocks more daily alerts, up to 10 vehicles, "I'm Blocking" alerts, and four extra themes.

## Audience

This section is based only on what the project itself says:

- **Location:** the British Virgin Islands. The legal documents name BVI governing law, the launch plan is titled "Marketing & Launch Strategy (BVI)", and there is a BVI Pride theme.
- **First users** (from `docs/Yuh_Blockin_Branded_Marketing_Plan.pdf`): daily commuters, taxi drivers, delivery drivers and shop staff. Later: property managers (B2B).
- **Wider region:** Caribbean, reflected in island-themed copy.
- **How they're reached:** WhatsApp groups, word of mouth, flyers and QR codes in parking areas.

## Brand personality

This describes the personality the current app already has:

- **Respectful and calm.** It diffuses conflict. Copy repeatedly uses "respectful", "politely notify" and "polite notifications only".
- **Private and trustworthy.** Privacy is a headline feature: "Your Privacy Protected", "We never see your plate number", "No personal info required".
- **Quick and practical.** One big button, one-tap replies, "Most cars move in 5 min".
- **Local warmth.** It has a Caribbean voice ("Easy nuh!", "Walk good", island themes, BVI Pride), but the core interface stays restrained. The local flavour sits in themes and copy, not in the main layout.
- **Premium-minimal.** The theme file describes itself as "inspired by Apple, Uber, Airbnb design languages. Professional, minimal, with subtle 2025 glow signature."

## Visual identity

### Logo
- **Construction:** a stacked wordmark, "Yuh" over "Blockin.", in a bold rounded sans-serif in teal. "Move with respect." sits beneath it in a lighter weight.
- **Symbol:** a coral car seen from the front, marked with an "x", with a coral arc and a slash rising from behind the "h" of "Yuh". Together they suggest a gauge or a "no" sign over a car.
- **Format:** raster only, 1024 px maximum. The same artwork is used for the app icon, which is the full lock-up on white.

### Colour
- **Identity:** teal `#0D7493` and coral `#FF7670` (sampled from the logo). The code's named brand values are teal `#0B6E7D` and coral `#FF847C`.
- **Interface:** an Apple-style neutral system (`#FCFCFC` background, `#FFFFFF` surfaces, `#1C1C1E` text, `#8E8E93` secondary) with **Action Blue `#0A84FF`** for everything interactive.
- **Where teal and coral appear in the app:** the logo, the splash (a white-to-`#E8F6F8` background and a teal-to-coral "DezeTingz" credit), and the legacy Premium Monthly screen.
- **Optional user themes:** Dark, Caribbean Sunset, and Premium-only Pink, Cyberpunk, Island Gold and BVI Pride. BVI Pride is blue-dominant (Resolution Blue `#001F7E` family), with gold `#E6B800` held to small accents and touches of red; it also restyles the hero button.

### Typography
- System fonts only: SF Pro on iOS (with Apple's tracking values) and Roboto on Android.
- Semibold (w600) is the dominant weight. Most text is 13-17 pt.
- There is no display or brand typeface in the app. The logo lettering exists only as artwork.

### Visual language
- **Soft, airy and rounded.** Generous white space, 12-16 px corner radii (24-28 for sheets and the alert card), and hairline borders in accent at 10-15%.
- **Glow, not elevation.** Depth comes from soft shadows tinted with the accent colour, not Material elevation. The hero button is a radial-gradient blue circle with a blue glow.
- **Emoji as expression.** Alerts carry an emoji (🚗 🙏 ⏰ 🚨 😊 👋).
- **Colour-coded urgency** (green, blue, red) and green success checks.
- **Material Icons**, mostly the rounded and outlined variants.

## Design principles to preserve

1. **One obvious action.** The home screen centres on a single large circular "YUH BLOCKIN'" button. Everything else is secondary.
2. **Politeness in every word.** Copy should de-escalate, never accuse.
3. **Privacy made visible.** Keys, hashing and "we never see your plate" are part of the product's promise and should stay prominent.
4. **Calm surfaces.** Light, neutral backgrounds; one accent colour; soft shadows; no visual noise.
5. **Fast, tactile feedback.** Press-scale with haptics, toasts that pop in, quick one-tap replies.

## Do not change without intent

- The **logo artwork**, including the coral car-and-arc symbol, the teal stacked wordmark and the full stop in "Yuh Blockin.".
- The **tagline**, "Move with respect.".
- The **teal and coral pairing** as the identity colours.
- The **large circular hero button** as the home screen's centrepiece, and its label "YUH BLOCKIN'".
- The **four canned responses** and their wording.
- The **anonymous, key-based ownership model** and the language around it ("Secret Ownership Key", "YB-" keys).
- The **"from DezeTingz" credit** on the splash.

## Design opportunities

These are places where the identity could evolve without losing recognition. They are open questions, not decisions.

1. **Bring the identity into the UI.** The biggest gap is the split between the teal/coral logo and the blue interface. A redesign could test teal or coral as the interactive accent, or keep blue for actions and use teal and coral for brand moments. Either way the change should be deliberate.
2. **Unify teal and coral.** Choose one teal and one coral (from the logo, the code `#0B6E7D`/`#FF847C`, or the website `#21819B`/`#DE5E59`) and use them everywhere.
3. **Vector and logo variants.** Produce a faithful vector master, an icon-only mark (the coral car symbol), and approved light, dark and monochrome versions. The app icon is currently the full lock-up with tagline, which is unreadable at small sizes. A symbol-only app icon is an obvious candidate.
4. **Name consistency.** Pick one spelling for UI copy: "Yuh Blockin'" or "Yuh Blockin".
5. **Urgency colours.** Three slightly different green/blue/red sets exist. Consolidate them into one semantic set.
6. **Home logo treatment.** The home header recolours the logo to solid accent blue, which loses the coral symbol.
7. **Web and PWA.** `web/manifest.json` still uses Flutter defaults (`#0175C2`, "A new Flutter project.").
