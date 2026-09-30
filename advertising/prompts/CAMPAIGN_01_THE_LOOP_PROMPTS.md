# YuhBlockin Advertising — Campaign 01: "The Loop" — Generation Prompts

**Phase:** PROMPT DESIGN. Follows `advertising/storyboards/
CAMPAIGN_01_THE_LOOP_STORYBOARD.md` (approved). No generation system invoked
yet — this is the prompt package only.

Prompts are written in structured, keyword-dense form (subject / environment
/ action / camera / lighting / style / negative), matched to how Runway and
Veo actually consume prompts, not as flowing cinematic prose.

---

## 0. Shared Reference Package

Reuse this exact language across every shot's prompt to prevent drift. In
production, generate or select still reference images for the two vehicles
and the environment **before** running any shot, and attach them as image
references wherever the model supports it (per `vehicle-universe.md`:
"Use reference images when supported").

**Blocked Car (reference tag: `BLOCKED_CAR`):** modern compact hatchback,
muted blue-grey paint, clean unbranded bodywork, no visible badges or logos,
factory-standard wheels, a visible license plate in the correct position
front and rear.

**Blocking Car (reference tag: `BLOCKING_CAR`):** older-model sedan,
faded off-white/cream paint, unbranded bodywork, no visible badges or logos,
factory-standard wheels, a visible license plate in the correct position
front and rear.

**Plate policy (revised 2026-09-30):** every vehicle must show a visible
plate-shaped rectangle in the correct real-world position — an unplated car
reads as fake/staged. The plate itself must stay soft/abstract/illegible,
never sharp legible characters (that remains the only reliably real plate
text source: composited real app footage, per the locked authenticity rule).
This is a refinement, not a reversal — "no legible plate characters" in the
global negative below still applies; what changed is adding an explicit
positive instruction for the plate's physical presence, since the earlier
prompts' silence on this caused the model to omit plates entirely rather than
just keep them blank.

**Environment (reference tag: `PARKING_ENV`):** modest Caribbean commercial/
residential parking area, low painted concrete block wall, corrugated metal
roofline edge in the background, sparse tropical vegetation (palm fronds) at
frame edges, sun-bleached asphalt surface, no signage, no readable text
anywhere in the environment, not a recognizable landmark.

**Style tag (all shots) — revised 2026-09-30 for the 2D direction** (was
premium stylized 3D; see `docs/marketing/YUHBLOCKIN_BRAND_SOURCE_OF_TRUTH.md`
§12 and `SKILL.md` for why): premium 2D flat/vector animated commercial,
clean vector linework and simplified shapes, subtle parallax/depth layering
between flat planes (not full 3D, not photoreal), contemporary 2026
aesthetic in the register of Slack's or Spotify's explainer-video work,
sophisticated and restrained, bold-but-muted color palette (not pastel, not
saturated kids'-show colors), smooth rigged-feeling movement. 9:16 vertical,
24fps look.

**Global negative prompt (apply to every generated shot):** no 3D rendering,
no photoreal rendering, no realistic materials or physics, no photographic
depth of field or lens blur, no cinematic lens effects, no humans, no hands,
no fingers, no body parts, no faces, no pedestrians, no readable text, no
sharp/legible license plate characters (plates should be present but
blank/abstract — see Plate policy above), no logos, no brand marks, no UI
elements, no app screens, no signage text, no subtitles, no watermarks, no
childish/cartoon proportions, no oversized eyes, no anthropomorphized vehicle
faces, no slapstick motion, no camera shake, no lens flare, no glitch/AI
artifact look, no dystopian or cyberpunk tone, no third-party vehicle brand
badges or logos.

---

## Shot 1 — Top-Down Establish

**Recommended model: Runway.** Simple establishing zoom, no cross-shot
continuity dependency yet, no complex vehicle motion — a cost-effective,
reliable choice for a text-to-video opening shot.

**Prompt (revised 2026-09-30 — geometry fix from the production log below,
plus the 2D style rewrite; see §0's Style tag and Global negative):**
> [Style tag]. Top-down flat vector illustration, `PARKING_ENV`, bright
> midday Caribbean sun, flat-illustrated hard-edged shadow shapes, high
> contrast. `BLOCKED_CAR` is parked nose-in, normally, inside a single
> marked parking space. `BLOCKING_CAR` is stopped perpendicular/crosswise
> directly behind `BLOCKED_CAR`'s rear bumper, forming a T-shape with it —
> `BLOCKING_CAR`'s body physically spans and seals the only path out of the
> space, touching or nearly touching `BLOCKED_CAR`'s bumper, like a classic
> double-park blocking a driveway. There is zero gap between the two
> vehicles and no visible exit path. `BLOCKED_CAR` is completely boxed in.
> Both vehicles completely static, engines off, no motion. Camera: slow,
> steady, continuous zoom-in within the flat top-down composition, smooth
> mechanical movement, no shake, no rotation, no perspective change.
> Duration 3 seconds.

**Negative prompt:** [global negative, above] + no camera shake, no rapid
zoom, no cuts within the shot, no additional vehicles or pedestrians
entering frame, **no side-by-side parking, no parallel parking in adjacent
spaces, no visible gap or open lane between the two vehicles, vehicles must
not form a parallel row.**

**Production log:** first attempt (before this revision) rendered the two
vehicles parked normally side-by-side in adjacent spaces — no blocking
geometry at all, the core story point was invisible. Root cause: the
original prompt described the relationship only in words ("parked directly
across the exit lane") without pinning down the actual shape, so the model
defaulted to the most common parking-lot composition. Fixed by explicitly
naming the T-shape/perpendicular/zero-gap geometry and adding a negative
prompt against the side-by-side failure mode specifically.

**Continuity note:** this shot's **final frame** must be captured and reused
as the starting reference image for Shot 2 (see below).

---

## Shot 2 — Tight on the Two Vehicles

**Recommended model: Veo.** This shot must continue Shot 1's zoom and match
its final frame almost exactly — Veo's reference-consistency strength (per
`SKILL.md`) is the better fit for an image-to-video continuation than a
fresh text-to-video generation, which is the highest-risk continuity seam in
the whole piece.

**Prompt (revised 2026-09-30 — same geometry fix as Shot 1, plus the 2D
style rewrite; also drops the angle change the 3D-era version called for —
see storyboard §1's medium-specific note: flat illustration can't rotate
perspective mid-zoom, so this shot stays in the same top-down angle as
Shot 1, just tighter):**
> [Style tag]. Continue the zoom-in from the attached reference frame (Shot
> 1 final frame), same flat top-down angle, `PARKING_ENV`, same bright
> midday sun and shadow direction. `BLOCKED_CAR` is parked nose-in, normally,
> inside its space. `BLOCKING_CAR` remains stopped perpendicular/crosswise
> directly behind `BLOCKED_CAR`'s rear bumper, sealing the only exit path —
> zero gap between the two vehicles, no visible way out, consistent with the
> T-shaped blocking layout established in Shot 1. Both vehicles remain
> completely static — no motion, no engine start, this is a stillness beat.
> Duration 3 seconds.

**Reference image required:** Shot 1's final frame (image-to-video /
continuation input).

**Negative prompt:** [global negative] + no discontinuity in zoom speed or
direction, no perspective/angle change from the reference frame, no change
in vehicle position/color/shape from the reference frame, no change in
lighting direction, no added motion, no side-by-side parking, no visible
gap or open lane between the two vehicles.

---

## Shot 3 — Plate Detail / Identify

**Recommended model: Runway.** Simple, isolated, static-subject illustration
— no complex motion, no cross-shot continuity beyond matching the vehicle
reference. Runway is sufficient and cost-effective here.

**Prompt (revised 2026-09-30 for the 2D direction — see storyboard §1's
medium-specific note: this is now a cut to a separate close-up illustration
panel, not a continuation of Shot 2's camera):**
> [Style tag]. Static close-up flat illustration, near-front-on angle on
> the rear of `BLOCKING_CAR` (a new, differently-framed illustration, not a
> continuation of Shot 2's top-down angle), isolating the license-plate area
> compositionally within the frame. Background simplified and desaturated
> behind the vehicle to draw the eye (flat-illustration equivalent of
> shallow depth of field — not photographic blur), `PARKING_ENV` reduced to
> soft flat shapes only. Bright midday sun, slightly higher contrast on the
> vehicle body. Vehicle completely static, no motion. The plate area should
> read as a plate-shaped surface only — **do not render sharp, legible
> plate characters**; keep any text on the plate soft, blurred, or abstract.
> Duration 2 seconds.

**Negative prompt:** [global negative] + no sharp/legible plate text or
characters, no readable alphanumeric characters anywhere in frame, no
vehicle motion, no camera shake, no photographic lens blur.

**Continuity note:** this shot's final frame (or the plate's on-screen
rectangular silhouette/position) is used as the graphic match target for the
cut into Shot 4's authentic UI insert — coordinate framing/aspect with the
edit, not the generation itself.

---

## Shot 4 — UI Moment: Plate Entry + Send

**Duration: 3.0 seconds** (the six generated shots total 15.0s; this
authentic-asset shot is what brings the piece to the full 18.0s target — see
`CAMPAIGN_01_THE_LOOP_STORYBOARD.md` §3 Timing Map).

**No generation prompt — `AUTHENTIC ASSET`.**

This shot uses real, unaltered YuhBlockin app footage/screenshots, not
generated video, per the locked product-authenticity rule. Production note
(carried over from the storyboard): source a fresh, tightly-cropped
recording of the actual "I'm Blocked" send flow (plate entry → Send tap →
confirmation) rather than reusing the longer raw reference clip captured
earlier this session. Insert as a full-screen, frame-filling crop, no
hands/body visible, real UI colors and text completely unaltered.

**Insertion point marker:** `[[AUTHENTIC_ASSET: real "I'm Blocked" send flow,
full-screen crop]]`

---

## Shot 5 — Notification Lands

**Recommended model: Runway**, with Veo as a fallback if the light-activation
cue doesn't read clearly enough on the first pass. This is a short, simple
animation beat (a single light-pulse) — not complex enough on its own to
default to the higher-cost model, but the cue must be unambiguous, so quality
should be checked before committing.

**Prompt:**
> [Style tag]. Medium flat illustration of `BLOCKING_CAR`, framed to clearly
> show its headlights and front indicator. Static composition, no camera
> movement. `PARKING_ENV` visible in background, consistent bright midday
> lighting matching prior shots. Animation: headlights and indicator
> activate — a single clear light pulse/blink, as if the vehicle just "woke
> up." No other motion, vehicle remains parked and stationary otherwise.
> Duration 2 seconds.

**Negative prompt:** [global negative] + no vehicle movement yet (movement
begins in Shot 6, not this shot), no engine-start smoke/exhaust effects, no
exaggerated cartoon light-burst, no change in camera framing mid-shot.

---

## Shot 6 — Blocking Vehicle Moves / Road Clears

**Recommended model: Veo.** Real vehicle motion (reversing and clearing the
lane) is one of the higher-risk elements this storyboard flags (unrealistic
motion/physics is an explicit `quality-control.md` reject criterion) —
Veo's complex-motion strength is the better fit for this shot specifically.

**Prompt:**
> [Style tag]. Wide flat illustration at vehicle level, static composition
> (no panning). `PARKING_ENV`, consistent bright midday lighting matching
> prior shots. `BLOCKING_CAR` reverses out of the exit lane at a natural,
> unhurried, moderate speed and exits the frame, wheels turning smoothly,
> believable rigged-feeling weight/motion (not photographic suspension
> physics). `BLOCKED_CAR` remains static in frame throughout, now visibly
> unobstructed once `BLOCKING_CAR` clears. Duration 2.5 seconds.

**Negative prompt:** [global negative] + no fast/erratic movement, no
impossible turning radius, no wheel clipping/sliding artifacts, no camera
movement, no collision or near-collision, no change in `BLOCKED_CAR`
position.

---

## Shot 7 — Resolution / Logo Lockup / CTA

**Recommended model: Veo.** Called out in `SKILL.md` as a "premium hero
shot" use case — this is the final visual impression before the logo/CTA
composite, and needs the highest polish of the piece plus another instance
of natural vehicle motion.

**Prompt:**
> [Style tag]. Wide static flat illustration, `PARKING_ENV`, exit lane now
> fully clear. Very slow, gentle zoom-out within the flat composition (the
> reverse of Shots 1–2's zoom-in). `BLOCKED_CAR` eases forward calmly at a
> natural, unhurried speed and exits frame. Warm, consistent midday lighting
> matching all prior shots. Clean, uncluttered final composition suitable
> for a logo/text overlay to be added in post — leave visual "breathing
> room" in the lower third and center of frame. Duration 2.5 seconds.

**Negative prompt:** [global negative] + no text, no logo, no graphic
overlays generated in-shot (all of that is composited afterward), no fast
motion, no camera shake.

**Composite note:** logo lockup (`logo_transparent.png`, unaltered), tagline
"Move with respect.", and CTA "Download YuhBlockin" (brand teal `#0D7493`)
are added in post over this generated background — not part of the
generation prompt. This is the only branding in the entire piece — no logo
or text appears in any earlier shot, so the full lockup lands as a single
strong beat rather than growing from a persistent mark.

---

## Model Recommendation Summary

**Revised (2026-09-30):** the original Runway/Veo split below was the
cost-optimized plan, but Runway generation itself turned out to require a
paid upgrade with no free-tier path — not just the aspect-ratio/duration
options. Google Flow (Veo) is the account actually available (paid Ultra
plan), so **all 6 generated shots now go through Veo/Flow**, not just 2, 6,
and 7. The per-shot reasoning below is kept for reference (it still explains
relative risk/complexity per shot), but "Runway" should be read as "Veo" for
every row.

**Also revised (2026-09-30, 2D direction):** whether Veo/Flow can hold a
convincing flat 2D look — consistently, across all 6 shots — is **not yet
validated**, per `SKILL.md`'s Model Selection section. Test with a cheap
still-image generation first (the same image-first workflow used to fix
Shot 1's blocking geometry), using the explicit flat/vector style keywords
in each prompt above, before spending on video. If results drift back
toward photoreal/3D or look inconsistent shot-to-shot, `SKILL.md` names
Adobe Firefly (style-consistent stills) plus a separate 2.5D animation layer
as the fallback — not yet tested for this project.

| Shot | Original plan | Actual (Veo/Flow) | Why (original reasoning) |
|---|---|---|---|
| 1 | Runway | Veo | Simple establishing shot, no continuity dependency, cost-effective |
| 2 | Veo | Veo | Must continue Shot 1's exact camera move — reference-consistency strength |
| 3 | Runway | Veo | Simple static close-up, no complex motion |
| 4 | N/A | N/A | Authentic asset — no generation |
| 5 | Runway (Veo fallback) | Veo | Simple light-pulse animation |
| 6 | Veo | Veo | Real vehicle motion/physics — highest-risk motion beat |
| 7 | Veo | Veo | Premium hero/final shot, plus a second vehicle-motion beat |

**Also revised:** free-tier generation is locked to whatever default
aspect ratio/duration Flow offers per shot — the locked 9:16/exact-duration
spec is enforced in post (crop/trim), not at generation time. See each
shot's prompt below; duration figures are now targets for trimming, not
generation parameters.

---

Stopping here — no video generated, no generation system invoked. This is
the prompt package only, ready for the GENERATION phase when approved.
