# YuhBlockin Advertising — Campaign 01: Concepts

**Phase:** CONCEPT (per `.claude/skills/yuhblockin-ad-studio/SKILL.md`
workflow). Follows `CAMPAIGN_01_BRIEF.md`. No video generated, no storyboard
or shot plan yet, no generation system invoked.

All three concepts operate inside the locked system (creative direction,
palette, copy, product authenticity — `docs/marketing/
YUHBLOCKIN_BRAND_SOURCE_OF_TRUTH.md` §11–12) and demonstrate only the
verified mechanic: **a vehicle is blocked → the driver identifies the
blocking plate → they send an alert with no names exchanged → the situation
resolves.** No AR/camera-scanning capability is implied anywhere below — the
real app takes a typed plate number, not a scanned one, and every concept
reflects that.

**Style note (updated 2026-09-30):** these concepts were originally written
for the stylized-3D direction locked 2026-09-29. The creative direction has
since been revised to **2D flat/vector animation with subtle depth** (see
source-of-truth §12). Camera and visual-style language below has been
updated to 2D-appropriate terms — "camera move" now means movement within a
flat composition (zoom/pan/parallax) or a cut to a differently-framed flat
illustration, not literal 3D perspective/depth-of-field camera work.

**Shared compositing approach (all three):** the real app UI enters each
story as a **screen-only insert** — a close crop of the actual phone screen
(from real screenshots/footage), never a hand, arm, or any human body part in
frame. This keeps every concept human-free per the locked rule while still
showing authentic UI. Flagging this as a judgment call worth your explicit
confirmation before STORYBOARD, since "human-free" doesn't unambiguously
settle whether an anonymous hand/phone insert would have been acceptable —
this brief assumes the stricter reading (no hands at all).

---

## Concept A — "The Loop"

**One-sentence premise:** A single, continuous cinematic shot follows one
boxed-in car from the moment it's trapped to the moment the road clears,
with no cuts breaking the tension.

**Why it works:** Minimalism reads as confidence. One unbroken flat-composition
zoom mirrors the product's own promise — a small, single, decisive action
(one tap) resolves the whole problem. The restraint is the message.

**Opening hook:** Top-down flat illustration of a parking area, the
composition slowly zooming in; one car sits nose-out, completely boxed in by
a vehicle parked across the only exit line. No motion for a beat — stillness
reads as "stuck."

**Beginning / middle / ending:**
- *Beginning:* Top-down flat reveal → the composition zooms in and settles
  on a closer flat framing at vehicle level, showing the blocked car and the
  blocking plate in the same illustration.
- *Middle:* Zoom in further toward the blocking plate (readable in the
  illustration only as texture/context, not as the authoritative text — see
  Compositing below) → cut to the screen-only UI insert: plate entered,
  Send tapped.
- *Ending:* Cut back to the same flat scene — the blocking car's lights
  activate, it pulls away. The composition holds as the blocked car eases
  forward and exits cleanly. Logo lockup fades in over the now-clear road.

**Vehicle roles:** Two vehicles only — the blocked car (audience's point of
identification) and the blocking car (resolves the tension by leaving).
Personality carried entirely through stillness → light activation → motion.

**BVI/Caribbean setting:** A modest residential or commercial parking area —
low-key, believable, not a landmark. Midday, natural direct sun, hard-edged
shadows for graphic clarity.

**Visual style:** Clean, flat/vector, controlled — simplified shapes, subtle
parallax depth between background/midground/foreground layers, not full 3D.
Fewer elements on screen at any time than the other two concepts —
deliberately spare.

**Camera language:** One continuous zoom (top-down → zoom in → hold) within
a single flat illustrated scene, no hard cuts in the environment itself
(only the UI insert breaks the shot). Smooth, deliberate, unhurried. This is
actually *easier* to achieve cleanly in 2D motion-graphics terms than the
equivalent was in 3D — a single continuous camera move through 3D space is
a harder technical ask for AI video generation than a zoom/pan across one
flat illustrated composition.

**Lighting/mood:** Bright midday BVI sun, high contrast, optimistic rather
than tense — the "problem" reads as mundane annoyance, not danger.

**How real UI enters the story:** One screen-only insert at the midpoint —
the actual "I'm Blocked" flow (plate entry → Send → confirmation), sourced
from the real `send_flow.mp4` reference footage and app screenshots.

**Messaging/copy:** No logo or tagline appears until the final lockup — the
story plays out with zero branding on screen, keeping it a commercial
first and an app ad second. "No names. No confrontation. Just movement."
lands right as the blocking car pulls away — the line and the visual payoff
hit together. "Move with respect." appears only once, at the final lockup,
alongside the CTA — saving the brand's full presence for a single strong
beat rather than a persistent watermark.

**CTA treatment:** Logo lockup + "Download YuhBlockin" on the cleared road,
held for the final ~2 seconds.

**Estimated runtime:** 15 seconds — the concept's minimalism naturally fits
the shorter end of the locked 15–20s range.

**Generation/compositing considerations:** Single environment, two vehicles,
one camera move — the smallest surface area for anything to go visually
wrong. The plate itself never needs to be legible in the generated footage
(vehicle-universe.md's own guidance) since the UI insert carries the
authoritative plate text.

**Potential risks/weaknesses:** Whether current AI video tools can hold a
consistent flat/vector 2D look (rather than drifting toward photoreal or an
inconsistent style) across one continuous zoom is **not yet validated** —
this needs empirical testing (see the source-of-truth doc's Model Selection
revision). Also the lowest-energy opening of the three, which is a real
tradeoff in a fast-scroll vertical-video context.

---

## Concept B — "Chain Reaction"

**One-sentence premise:** A livelier, multi-vehicle commercial-street scene
shows YuhBlockin solving a friction that's part of a working day, and the
street's normal rhythm resumes the moment it's resolved.

**Why it works:** Speaks most directly to the working-driver personas (taxi,
delivery) named in the source of truth — the problem is framed as a
work-day interruption, and the payoff is the whole street's flow returning
to normal, not just one car.

**Opening hook:** A delivery van has double-parked across a narrow
commercial street, boxing in a taxi mid-route. Immediate visual read: this
is a working vehicle, on a working street, stuck.

**Beginning / middle / ending:**
- *Beginning:* A flat illustrated pan along the street (vehicle-level
  framing) establishes the commercial setting and the blockage in one
  motion.
- *Middle:* Cut to the taxi's dashboard-level framing of the blocking van's
  plate → cut to the screen-only UI insert (plate entered, Send tapped) →
  cut to a wider shot holding on the van, stillness.
- *Ending:* The van's lights activate, pulls in/moves; the street's motion
  resumes — other traffic, motion in the background restarts. Logo lockup
  over the moving street.

**Vehicle roles:** The taxi (blocked, audience's point of identification),
the delivery van (blocking, resolves by moving), background traffic
(environmental texture only, establishes "normal" rhythm before and after).

**BVI/Caribbean setting:** A believable BVI commercial street — modest
storefronts, midday activity, the kind of narrow shared road where this kind
of blockage is a daily, recognizable occurrence.

**Visual style:** More kinetic than Concept A — multiple short flat-
illustration framings rather than one continuous zoom, but still
controlled, never chaotic.

**Camera language:** 3–4 shorter flat framings (street pan → dashboard-level
close-up → wide-hold → resumed-motion wide), cut together rather than one
continuous zoom.

**Lighting/mood:** Warm midday sun, busier visual texture, energetic but not
frantic.

**How real UI enters the story:** Same screen-only insert approach as
Concept A, placed mid-sequence at the dashboard-level beat.

**Messaging/copy:** "Move with respect. Find the driver. Clear the road."
appears as the street's motion resumes — tying the tagline directly to the
visual payoff of normal life continuing. "No names. No confrontation."
appears smaller, earlier, near the UI insert.

**CTA treatment:** Logo lockup over the resumed street motion, "Download
YuhBlockin."

**Estimated runtime:** 18–20 seconds — the multi-shot structure needs more
of the locked runtime range to breathe than Concept A's single move does.

**Generation/compositing considerations:** More vehicles and a busier
environment mean more surface area for the exact defects `quality-control.md`
flags (malformed vehicles, inconsistent background traffic, distorted
plates) — background traffic in particular is the highest-risk element,
since it needs to read as "alive" without needing to be a focal point.

**Potential risks/weaknesses:** Highest production risk of the three —
multiple vehicles and multiple shots multiply the chances of a shot needing
regeneration, and maintaining consistent vehicle identity/environment across
cuts is harder than within Concept A's single take. Also carries the mildest
risk of reading as a generic "day in the life" spot if the individual shots
aren't distinctive.

---

## Concept C — "Golden Hour"

**One-sentence premise:** A slower, warmer evening scene at a coastal/marina
setting reframes the same resolution as an act of everyday respect rather
than a utility, leaning fully into the tagline's meaning.

**Why it works:** Directly embodies "Move with respect" as a felt tone, not
just a printed line — softest, most premium-feeling of the three, and the
one most likely to build brand warmth rather than just demonstrate a
feature.

**Opening hook:** Golden-hour light over a quiet coastal road near a marina;
a car sits parked, waiting, no urgency — just inconvenienced at the end of a
pleasant day.

**Beginning / middle / ending:**
- *Beginning:* Wide, held flat illustration establishes the coastal setting
  and the gentle inconvenience — no tension-building camera move, just
  stillness in beautiful light.
- *Middle:* Slow zoom toward the blocking vehicle's plate → screen-only UI
  insert (plate entered, Send tapped) → hold on the waiting car in soft
  light.
- *Ending:* The blocking car's lights come on, eases away unhurried; the
  waiting car pulls out into the sunset road. Logo lockup over the departing
  car.

**Vehicle roles:** Same two-vehicle structure as Concept A (waiting car,
blocking car), but the pacing and light do the emotional work instead of the
single-take camera move.

**BVI/Caribbean setting:** Coastal road / marina-adjacent parking, sunset —
the most visually "Caribbean-coded" of the three settings, closest to the
locked palette's "ocean, sunlight, sunset atmosphere" description.

**Visual style:** Painterly (within the flat/vector style), warm, unhurried
— fewer, longer-held illustrated framings.

**Camera language:** Two or three slow, deliberate flat framings (wide hold
→ slow zoom → wide hold), minimal cutting, longest average shot length of
the three concepts.

**Lighting/mood:** Golden-hour warmth, soft contrast, serene rather than
tense at any point — even the "problem" beat stays calm.

**How real UI enters the story:** Same screen-only insert approach, placed
during the slow zoom.

**Messaging/copy:** "Move with respect." carries the most emotional weight
here — it can appear as the closing line rather than an early beat, landing
over the final departing-car shot rather than earlier in the sequence.

**CTA treatment:** Logo lockup over the sunset road, "Download YuhBlockin,"
held slightly longer than the other two concepts to match the slower pacing.

**Estimated runtime:** 18–20 seconds — the slow pacing needs the fuller end
of the range to still land three distinct beats (setup, resolution, CTA)
without feeling rushed.

**Generation/compositing considerations:** Fewer, simpler shots than
Concept B, similar complexity to Concept A. Golden-hour lighting consistency
across shots is its own generation challenge (matching light direction/color
temperature shot-to-shot).

**Potential risks/weaknesses:** Closest of the three to drifting into a
generic travel/tourism-ad look, which `environments.md` explicitly warns
against ("do not make every scene look like a tourism advertisement") — this
concept needs the most editorial discipline to stay product-forward rather
than becoming a postcard. Slower pacing also risks under-communicating the
mechanic if the three beats aren't cut tightly. Narrowest persona fit of the
three (leans toward the tourist/rental-vehicle audience specifically, less
toward taxi/delivery/commuter personas).

---

## Production Recommendation

**Recommend Concept A ("The Loop") as the first flagship production
candidate.**

Judged strictly on production and communication criteria:

- **Clarity of product mechanic:** Concept A's single, focused scenario keeps
  the mechanic legible without competing visual noise — the other two
  concepts either add background traffic (B) or slower pacing that risks
  under-communicating the mechanic within the runtime (C).
- **Ability to execute consistently in generated video:** Fewest vehicles,
  simplest environment, smallest surface area for the defects
  `quality-control.md` explicitly flags (malformed vehicles, inconsistent
  environments). Concept B's multi-vehicle busy street carries the highest
  generation risk of the three.
- **Ease of integrating authentic UI/footage:** All three use the same
  screen-only insert approach, so this is roughly even — Concept A's
  simpler environment makes the insert placement marginally easier to frame
  cleanly.
- **Strength of the opening hook:** Concept A's overhead-to-ground reveal
  delivers "this car is completely stuck" in a single unambiguous shot,
  as fast as Concept B's busier hook, without needing a second shot to
  establish context.
- **Suitability for a 15–20s vertical ad:** Concept A's minimalism naturally
  fits the shorter end of the runtime range; Concept B and C both need
  closer to the full 20 seconds to land their additional beats, leaving less
  margin for error.

Concept B is the strongest candidate for a **later persona-specific variant**
(taxi/delivery angle) once the visual system is proven. Concept C is the
strongest candidate for a **later brand-building/atmospheric piece**, but
carries the most tonal risk (tourism-ad drift) to lead with on an unproven
pipeline.

Stopping here — no storyboard, shot plan, or generation started.
