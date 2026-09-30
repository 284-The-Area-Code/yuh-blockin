# YuhBlockin Advertising — Campaign 01: "The Loop" Storyboard

**Phase:** STORYBOARD (per `.claude/skills/yuhblockin-ad-studio/SKILL.md`
workflow). Follows `advertising/concepts/CAMPAIGN_01_CONCEPTS.md` (Concept A
approved). No video generated, no generation system invoked, no generation
prompts written — this is the production/creative specification only.

Runtime target: **18 seconds** (within the locked 15–20s range).

---

## 1. Creative Intent

**Revised 2026-09-30 for the 2D direction** (was written for stylized 3D —
see source-of-truth §12 for why). Concept A's appeal was visual restraint —
one small, decisive action solving the whole problem, mirrored by unhurried
camera work. A literal single unbroken 18-second generated take is not a
realistic production target regardless of medium: current AI video
generation works in short segments, and asking one continuous shot to carry
that much duration multiplies continuity risk (vehicle/environment drift
over a long single generation).

This storyboard preserves the *feeling* of restraint through a small number
of shots (7) connected by matched, motivated transitions — motion direction
that continues logically shot-to-shot, cuts placed on stillness or on
motion-matches rather than arbitrary points — so the edit reads as close to
continuous as the concept intended, while being realistic to produce and
review shot-by-shot.

**Medium-specific note:** in flat 2D, a "camera move" means movement within
one flat illustrated composition (zoom, pan, parallax) — it cannot show a
genuine perspective/angle change the way a 3D camera can. Shot 2 originally
called for the camera to "settle from overhead into a 3/4-front vehicle-level
angle," which isn't achievable as a continuous zoom in flat illustration —
that would require physically redrawing the scene from a different angle,
breaking the single-flat-scene economy that makes 2D attractive here. This
storyboard instead keeps Shots 1–2 in one consistent top-down illustrated
angle (zooming in, not rotating), and treats Shot 3's plate detail as an
editorial cut to a separate close-up illustration panel — a standard flat
motion-graphics/infographic convention, not a claimed camera move.

The whole piece stays in one location, one time of day, two vehicles. Nothing
about the mechanic is exaggerated: the driver never scans anything — the
plate is identified visually, then typed into the real app, exactly as the
product actually works.

## 2. Complete Shot-by-Shot Storyboard

### Shot 1 — Top-Down Establish
- **Duration:** 3.0s | **Timestamp:** 0:00–0:03
- **Framing:** Top-down flat illustration of a modest parking area, wide
  enough to read the whole layout at once
- **Camera movement:** Slow, steady zoom-in on the flat composition,
  beginning the single continuous move that carries through Shot 2
- **Vehicle position/action:** Blocked Car parked nose-out in its spot;
  Blocking Car parked directly across the only exit lane, fully obstructing
  it. Both static.
- **Environment:** Believable BVI residential/commercial parking area — low
  block wall, corrugated roofline edge, modest tropical vegetation at frame
  edges, rendered as flat/vector shapes. Not a landmark.
- **Lighting:** Bright midday sun, flat-illustrated hard-edged shadow shapes
- **Animation behavior:** Zoom moves; vehicles completely static
- **Screen/UI treatment:** None
- **On-screen copy:** None
- **Narration:** None
- **Sound design:** Ambient midday outdoor bed begins — distant traffic hum,
  light breeze, no music yet
- **Transition to next shot:** Continuous — the zoom keeps tightening in the
  same top-down angle into Shot 2 (planned as a matched/hidden cut, see §8)
- **Asset type:** `GENERATED`

### Shot 2 — Tight on the Two Vehicles
- **Duration:** 3.0s | **Timestamp:** 0:03–0:06
- **Framing:** Continues the zoom from Shot 1, still top-down, now tight
  enough that both vehicles and the blocked exit lane fill most of the frame
- **Camera movement:** Continued zoom-in, decelerating to a near-static hold
  by the end of the shot — stays in the same flat top-down angle throughout;
  no perspective/angle change (see §1's medium-specific note)
- **Vehicle position/action:** Both vehicles now clearly framed together;
  stillness continues — this held stillness is the "stuck" beat
- **Environment:** Same location, tighter crop — vegetation and architecture
  cues visible at frame edges
- **Lighting:** Continues bright midday
- **Animation behavior:** Settles to near-total stillness by shot end
- **Screen/UI treatment:** None
- **On-screen copy:** None — no branding appears until the final lockup
  (Shot 7); the story plays with zero on-screen logo/text until then
- **Narration:** None
- **Sound design:** Ambient bed continues, very slightly quieter as the
  zoom settles (focus pulls attention inward)
- **Transition to next shot:** Hard cut on stillness (low continuity risk —
  nothing is moving at the cut point) → Shot 3
- **Asset type:** `GENERATED`

### Shot 3 — Plate Detail / Identify
- **Duration:** 2.0s | **Timestamp:** 0:06–0:08
- **Framing:** Editorial cut to a separate close-up illustration panel — a
  differently-framed flat illustration (near-front-on angle) isolating the
  Blocking Car's plate area, not a continuation of Shot 2's top-down camera
  (see §1's medium-specific note: this is a cut to a new flat illustration,
  not a claimed physical camera move). Plate characters intentionally kept
  soft/out of critical focus (see §8, this is a deliberate risk mitigation,
  not an oversight)
- **Camera movement:** None — a static detail panel; any "closeness" is
  built into how tight the illustration itself is framed, not a camera move
- **Vehicle position/action:** Blocking Car stationary; no vehicle motion
- **Environment:** Background simplified/flattened and desaturated behind
  the plate area to draw the eye (2D equivalent of shallow depth of field)
- **Lighting:** Same midday, slightly higher contrast on the vehicle body to
  draw the eye
- **Animation behavior:** None — fully static
- **Screen/UI treatment:** None yet — this shot sets up the transition
- **On-screen copy:** None
- **Narration:** None
- **Sound design:** Ambient bed fades down further; a single soft rising tone
  begins, anticipating the transition
- **Transition to next shot:** **Match-cut** — the plate's rectangular
  silhouette whip-matches directly into the rectangular plate-entry field on
  the phone screen (see §6, UI Integration Strategy)
- **Asset type:** `GENERATED`

### Shot 4 — UI Moment: Plate Entry + Send
- **Duration:** 3.0s | **Timestamp:** 0:08–0:11
- **Framing:** Full-screen, frame-filling crop of the real phone screen —
  the screen itself fills the entire 9:16 frame edge-to-edge, no hands, arms,
  or any body part visible at any point
- **Camera movement:** None on the physical "camera" — a subtle simulated
  zoom-in on the UI content itself (matching the momentum from Shot 3's
  tight framing) is acceptable if it reads as native to the screen recording,
  not as an artificial zoom on top of it
- **Vehicle position/action:** N/A
- **Environment:** N/A — pure UI
- **Lighting:** N/A — real screen content, unaltered
- **Animation behavior:** Real captured interaction: plate field showing the
  identified plate → tap Send → brief confirmation state
- **Screen/UI treatment:** `AUTHENTIC ASSET` — sourced and re-recorded
  cleanly from the real "I'm Blocked" flow (reference: this session's
  `send_flow.mp4` and the app's actual UI; a fresh, tightly-cropped capture
  specifically for this shot is recommended over reusing the raw reference
  clip as-is — see §9)
- **On-screen copy:** None added on top of the real UI — the UI's own text
  (plate field, Send button) is left completely unaltered per the locked
  authenticity rule
- **Narration:** None
- **Sound design:** UI tap sound on the Send press, followed by a soft
  "sent" chime
- **Transition to next shot:** **Bleed-through dissolve** — the screen's
  glow/confirmation state dissolves outward into the Blocking Car's headlight
  activating in Shot 5, visually rhyming "message sent" with "message
  received" (see §6)
- **Asset type:** `AUTHENTIC ASSET` (screen content) + `COMPOSITE` (transition
  edges/framing into the 9:16 canvas)

### Shot 5 — Notification Lands
- **Duration:** 2.0s | **Timestamp:** 0:11–0:13
- **Framing:** Medium flat illustration of the Blocking Car, framed to
  clearly show its headlights/indicator
- **Camera movement:** Static hold
- **Vehicle position/action:** Headlights/indicator activate — a single clear
  "waking up" cue (brief light pulse), no other motion yet
- **Environment:** Same parking area, midday
- **Lighting:** Consistent with prior shots, subtle warm highlight matching
  the incoming dissolve from Shot 4
- **Animation behavior:** Light activation only — this is the sole
  "notification received" cue and must read unambiguously
- **Screen/UI treatment:** None
- **On-screen copy:** None
- **Narration:** None
- **Sound design:** Soft chime/musical sting on the light activation,
  ambient bed begins to rebuild under it
- **Transition to next shot:** Motion-matched cut as the car begins to move
  → Shot 6
- **Asset type:** `GENERATED`

### Shot 6 — Blocking Vehicle Moves / Road Clears
- **Duration:** 2.5s | **Timestamp:** 0:13–0:15.5
- **Framing:** Wider flat illustration at vehicle level, static
- **Camera movement:** Static wide hold (deliberately not panning to follow
  the moving vehicle — see §8, lower generation risk than following motion)
- **Vehicle position/action:** Blocking Car reverses/pulls away at a natural,
  unhurried speed and clears the lane; Blocked Car remains static but now
  visibly unobstructed
- **Environment:** Same location, exit lane now open
- **Lighting:** Consistent midday
- **Animation behavior:** Smooth, moderate-speed, natural vehicle motion —
  explicitly not fast or abrupt
- **Screen/UI treatment:** None
- **On-screen copy:** **"No names. No confrontation. Just movement."**
  appears small, lower-third, timed to land as the Blocking Car clears frame
- **Narration:** None
- **Sound design:** Vehicle engine/movement sound, ambient bed rebuilding,
  light musical build begins
- **Transition to next shot:** As the Blocking Car fully exits, cut/continue
  as the Blocked Car's own lights activate, implying its turn to move →
  Shot 7
- **Asset type:** `GENERATED` (scene) + `COMPOSITE` (on-screen copy)

### Shot 7 — Resolution / Logo Lockup / CTA
- **Duration:** 2.5s | **Timestamp:** 0:15.5–0:18
- **Framing:** Wide, static hold on the now-clear lane
- **Camera movement:** Very slow, gentle zoom-out — the visual bookend to
  Shot 1–2's zoom-in, closing the loop
- **Vehicle position/action:** Blocked Car eases forward calmly and exits
  frame
- **Environment:** Same location, fully resolved
- **Lighting:** Consistent midday warmth
- **Animation behavior:** Smooth, unhurried final motion
- **Screen/UI treatment:** None (pure logo/CTA composite over the generated
  background)
- **On-screen copy:** Logo lockup (`logo_transparent.png`, unaltered) fades
  in at full size, centered/lower-third — the first and only branding to
  appear anywhere in the piece; "Move with respect." tagline;
  **"Download YuhBlockin"** CTA beneath, in brand teal `#0D7493`
- **Narration:** Optional single VO line reading the tagline — not required;
  flagged as an open choice, not a locked decision (see §5)
- **Sound design:** Soft musical resolve/stinger, ambient sound fades under
  and out
- **Transition to next shot:** End card, hold to black or brand-color card
- **Asset type:** `GENERATED` (background) + `COMPOSITE` (logo, tagline, CTA)

## 3. Timing Map

| Shot | Timestamp | Duration | Cumulative |
|---|---|---|---|
| 1 | 0:00–0:03 | 3.0s | 3.0s |
| 2 | 0:03–0:06 | 3.0s | 6.0s |
| 3 | 0:06–0:08 | 2.0s | 8.0s |
| 4 | 0:08–0:11 | 3.0s | 11.0s |
| 5 | 0:11–0:13 | 2.0s | 13.0s |
| 6 | 0:13–0:15.5 | 2.5s | 15.5s |
| 7 | 0:15.5–0:18 | 2.5s | **18.0s** |

Total runtime: **18.0 seconds** — within the locked 15–20s range, matching
the concept's own "fits the shorter end of the range" estimate with a small
margin for the UI beat to breathe.

## 4. Generated vs. Authentic Asset Map

| Element | Type |
|---|---|
| Shots 1, 2, 3 (environment + vehicles) | `GENERATED` |
| Shot 4 screen content | `AUTHENTIC ASSET` |
| Shot 4 framing/transition edges | `COMPOSITE` |
| Shots 5, 6, 7 (environment + vehicles) | `GENERATED` |
| Shot 6 on-screen copy | `COMPOSITE` |
| Shot 7 logo lockup, tagline, CTA text | `COMPOSITE` (logo is `AUTHENTIC ASSET` sourced from `logo_transparent.png`, never regenerated) |

No shot relies on AI-generated text, UI, or logo at any point — every piece
of text or interface on screen is either real captured footage or composited
from real brand assets.

## 5. Audio/SFX Direction

- **Ambient bed:** midday BVI outdoor sound (light traffic hum, breeze) —
  present throughout, dipping during Shots 3–4 to focus attention on the UI
  beat, rebuilding through Shots 5–7. **Not yet sourced** — needs a licensed
  or custom ambient track.
- **UI SFX:** a tap sound on Send (Shot 4) and a soft "sent" chime — can be
  the app's actual sound if one exists in `assets/sounds/` (not yet checked
  against this storyboard), or a designed equivalent that matches the app's
  real tone.
- **Notification cue:** soft chime/musical sting on the Blocking Car's light
  activation (Shot 5) — this is the "message received" audio payoff and
  should feel connected to the Shot 4 "sent" chime (e.g., a resolving musical
  interval between the two).
- **Resolution:** light musical build from Shot 6, resolving into a soft
  stinger under the Shot 7 logo lockup.
- **Narration:** optional single VO line of the tagline over Shot 7 — left
  as an open choice for the next phase, not locked here. The storyboard
  works fully muted without it (on-screen text carries every beat).

## 6. UI Integration Strategy

**Selected treatment: match-cut in, bleed-through dissolve out.**

Evaluated against the alternatives named in the brief:
- A brief full-screen product moment (used here) beats a small inset/picture-
  in-picture treatment, which would read as "pasted on" rather than part of
  the world.
- A hard cut with no visual link (no match) was rejected — it would break
  the continuous, restrained feeling Concept A depends on.
- The chosen approach ties the UI moment to the physical world on both sides:
  **in** via a graphic match (plate silhouette → UI field, both rectangular,
  same screen position), **out** via a bleed-through dissolve (screen glow →
  headlight glow), so the UI beat feels like the hinge of the story rather
  than an interruption to it.
- No hand, arm, or body part appears at any point — the screen itself is the
  only UI presence, satisfying the strict reading of "human-free."

## 7. Continuity Requirements

- **Vehicle identity:** Blocked Car and Blocking Car must maintain identical
  body shape, color, wheels, and proportions across Shots 1, 2, 3, 5, 6, 7 —
  six separate generated shots sharing two vehicles. Reference images for
  both vehicles must be established and locked before any shot generation
  begins (next phase).
- **Environment identity:** the same parking location (wall, roofline,
  vegetation, ground surface) must persist across all generated shots —
  an environment reference plate should be established once and reused.
- **Camera logic:** Shots 1→2 must read as one continuous zoom-in within the
  same flat top-down illustration; the cut between them is the single
  highest continuity risk in the piece (see §8). Shot 3 is a deliberate cut
  to a new flat illustration angle, not a claimed continuation of that
  camera move (see §1).
- **Lighting:** consistent bright midday sun and shadow direction across all
  generated shots — no shift in time of day anywhere in this piece.
- **Logo:** identical, unaltered asset (`logo_transparent.png`) used in the
  final lockup — never regenerated or redrawn. No logo appears anywhere
  before Shot 7.

## 8. Generation-Risk Assessment

| Risk | Where | Mitigation designed into this storyboard |
|---|---|---|
| Vehicle continuity drift | Shots 1,2,3,5,6,7 | Two vehicles only, reused reference images planned for the next phase |
| License-plate legibility/distortion | Shot 3 | Plate kept intentionally soft/out of critical focus in the generated shot; the only legible plate lives in the `AUTHENTIC ASSET` UI insert (Shot 4) |
| Camera continuity (the zoom-in) | Shots 1→2 | Planned as a matched/hidden cut on continued zoom direction within one flat illustration; flagged as the highest-risk single seam in the storyboard — may require several generation attempts or a blended overlap in post |
| UI legibility | Shot 4 | Entirely sidestepped — real footage/screenshots, never generated |
| Unrealistic vehicle movement | Shot 6 | Static wide hold instead of a panning shot; natural/moderate speed specified explicitly |
| Style drift toward photoreal/3D | Shots 1,2,3,5,6,7 | Explicit flat/vector style keywords required in every generation prompt; image-first verification before any video spend (see SKILL.md Model Selection) |
| Environmental continuity | Shots 1,2,3,5,6,7 | Single reused environment reference planned for the next phase |
| Typography/text generation | Shots 6, 7 | All on-screen text is `COMPOSITE`, added in post from real typography — never rendered by the generation model |
| Logo distortion | Shot 7 (only appearance) | Logo is always `COMPOSITE` from the real asset file, never generated |

## 9. Post-Production/Compositing Requirements

- Color-match all generated shots to one consistent midday grade
- Source or re-record a clean, tightly-cropped version of the real
  "I'm Blocked" send flow specifically for Shot 4 (the existing
  `send_flow.mp4` from this session is a longer raw reference take, not
  edit-ready)
- Design and composite the Shot 7 logo lockup from `logo_transparent.png`
  (the only branding in the piece — no logo appears before Shot 7)
- Add on-screen copy (Shot 6 supporting line, Shot 7 tagline/CTA) — **note:**
  no advertising typography has been locked yet (flagged as open in the
  source-of-truth doc, §10); a typeface decision is needed before this step
- Build the Shot 3→4 match-cut and Shot 4→5 bleed-through dissolve — both are
  bespoke transition work, not simple cuts
- Source/compose ambient sound bed, UI SFX, notification chime, and musical
  resolve — none currently exist
- Run the finished edit through the `quality-control.md` review checklist
  (Brand, Story, Product, Visual quality, Caribbean authenticity, Animation,
  Continuity, UI accuracy, Audio, CTA, Platform suitability) before export

## 10. Final Frame / CTA Specification

- **Visual:** wide, static hold on the cleared parking lane, Blocked Car
  mid-exit, warm consistent midday light
- **Logo:** full-size lockup, authentic asset, unaltered
- **Copy:** "Move with respect." (tagline) + **"Download YuhBlockin"** (CTA),
  brand teal `#0D7493`
- **No store badge or link included** — no current, verified store URL exists
  (the flyer's TestFlight link is stale per the source-of-truth doc); revisit
  before final export if a live link becomes available
- **Hold duration:** final ~2.5 seconds of the 18-second total (Shot 7)

---

Stopping here — no generation prompts written, no generation system invoked.
