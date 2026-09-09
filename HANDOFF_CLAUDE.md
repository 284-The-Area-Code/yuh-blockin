# YuhBlockin APNs Investigation — Claude Handoff

**Date:** 2026-09-08
**Supersedes:** `HANDOFF.md` (written by Gemini — retained, but contains six documented
inaccuracies; see `HANDOFF_AUDIT.md` §5)
**Companions:** `HANDOFF_AUDIT.md` (read-only takeover audit), `T0_DIFF_FOR_REVIEW.md`
**Status:** 🎯 **MISSION OBJECTIVE MET — TEST B AND TEST C BOTH PASS ON iOS.**
Build 23 delivered a user-visible APNs alert to a real iPhone 14 (iOS 16.4) **on the Lock
Screen**, and to Notification Center while backgrounded. Android delivery confirmed
separately. **One defect remains: notification sound.** Six root causes were found and
fixed; none of them was the authorization/presentation hypothesis the investigation
started from.

---

## 0. Current next steps — sound only

TEST B and TEST C both pass (see §2c). `pubspec.yaml` is at **`1.0.0+24`**.

1. **Build 24** via the normal Codemagic GUI workflow. It contains the sound fix:
   `ios/Runner.xcodeproj/project.pbxproj` now adds all seven `.wav` files to the Runner
   target's Copy Bundle Resources phase (28 lines added, 0 removed, backup at
   `/tmp/pbxproj.backup`).
2. **Verify in the shipped IPA before device testing** — this is checkable without a device:
   ```
   unzip -l <build24.ipa> | grep -E "Payload/Runner.app/[a-z_0-9]+\.wav"
   ```
   Seven `.wav` files must appear at **bundle root**, not under `flutter_assets/`.
3. **On device:** fire an alert and confirm audio plays on the Lock Screen. The iOS log
   error `Failed to find sound "high_alert_1.wav"` must be **gone**.
4. If sound still fails, fall back to sending `"default"` from `alerts-fcm`'s `soundMap` —
   a one-line server change requiring no rebuild.

`/tmp/fcm_validate.py` is a ready-made `validate_only` FCM probe if a no-delivery test of
a specific token is ever needed.

---

## 1. Repository state

- Branch `firebase-production-push`, HEAD **`976a561`** ("Restore
  GeneratedPluginRegistrant; bump to 1.0.0+23"), in sync with origin.
- `pubspec.yaml` = **`1.0.0+24`** (uncommitted) — Build 24 carries the sound fix.
- Commit history this session: `2ba3f5e` server push fix, `93d2b39` publishable-key
  migration, `a65c3e4` handoff docs, `976a561` GeneratedPluginRegistrant restore.
- `ios/Runner/Runner.entitlements` = `aps-environment = production` (untouched).
- **Production/distribution builds use the normal Codemagic GUI workflow, as Build 20
  did.** `codemagic.yaml` holds only the temporary `ios-apns-forensic` diagnostic
  workflow. It is **not** the production path, **not** a blocker, and must **not** be
  modified. `codemagic.yaml.apns-diagnostic.backup` must **not** be restored.

**Uncommitted right now:**
- `ios/Runner.xcodeproj/project.pbxproj` — seven `.wav` files added to the Runner target's
  Copy Bundle Resources phase (28 lines added, 0 removed; backup `/tmp/pbxproj.backup`)
- `pubspec.yaml` — `1.0.0+24`
- `HANDOFF_CLAUDE.md` — this file

Both migrations were **applied to the database manually via the SQL Editor** and are
committed in `2ba3f5e`. The Edge Function is **deployed via CLI** with
`--no-verify-jwt`.

---

## 2. SESSION RESULT — server-side pipeline repaired

### The confirmed root cause (F1)

`notify_alert_push()` built its authorization header as:

```
'Bearer ' || current_setting('supabase.service_role_key', true)
```

`supabase.service_role_key` is not a standard Supabase GUC and was never set on this
database. With `missing_ok = true` it returns NULL, and `'Bearer ' || NULL` evaluates to
NULL — so the header was absent. Every alert insert produced
**401 UNAUTHORIZED_NO_AUTH_HEADER** at the Edge Function gateway and the handler never
ran. `pg_net` is fire-and-forget, so the failure surfaced nowhere except
`net._http_response`.

Confirmed empirically: `guc_missing = true`, and repeated 401s in `net._http_response`.

**Consequence: `alerts-fcm` had never executed from the trigger. No push had ever been
sent by this path.** Every downstream hypothesis was untestable because nothing was
ever emitted.

### Four defects fixed

| # | Defect | Fix |
|---|---|---|
| 1 | **F1** — trigger auth via a GUC that was never set | `notify_alert_push()` rewritten: reads Vault, sends `apikey` only |
| 2 | **Three duplicate triggers** on `alerts` AFTER INSERT, all calling `alerts-fcm` | Dropped two; would have caused 2–3× duplicate pushes |
| 3 | **`FIREBASE_SERVICE_ACCOUNT_JSON` truncated** — ~95 base64 chars lost in a paste | Re-uploaded via `supabase secrets set --env-file`; digest verified byte-exact |
| 4 | **`@supabase/supabase-js@2.28.0` pin** lacked the `./cors` subpath required by `@supabase/server` | Bumped to `2.116.0`; had caused `BOOT_ERROR` |

Plus a **security fix**: the anon key is extractable from the shipped IPA with `strings`
(proven against the Build 21 artifact). Before this change, anyone holding it could have
invoked `alerts-fcm` and pushed arbitrary messages to any `receiver_id`. It is now
rejected.

### Final architecture (current Supabase service-to-service pattern)

```
alerts INSERT
  -> trigger on_new_alert_send_push  (AFTER INSERT, FOR EACH ROW — the only one left)
  -> notify_alert_push()             SECURITY DEFINER, search_path = ''
       reads vault.decrypted_secrets: alerts_fcm_project_url, alerts_fcm_secret_key
  -> pg_net net.http_post            header: apikey ONLY, no Authorization
  -> gateway                         verify_jwt = FALSE for this function
  -> alerts-fcm handler              createSupabaseContext(req, { auth: 'secret:alerts_fcm_trigger' })
                                     -> 403 on failure, before req.json()
  -> existing service-role client, device_tokens query, FCM logic  (all unchanged)
```

Deliberately **not** used: legacy `service_role` JWT in the trigger; a custom
shared-secret mechanism (the docs show the named secret key is sufficient);
`verify_jwt = true` with legacy keys.

### Verification evidence

Four probes, `{}` body (returns 400 before any credential read or write):

| Probe | Result |
|---|---|
| no `apikey` | `403 forbidden` |
| garbage `apikey` | `403 forbidden` |
| **legacy anon key** (the IPA-extractable one) | `403 forbidden` |
| correct `alerts_fcm_trigger` secret key | `400 missing receiver_id` |

Controlled trigger test, receiver chosen to have **zero** device tokens:

```
net._http_response id=176  status 200  {"ok":true,"message":"no tokens registered"}
```

One insert produced **exactly one** HTTP call, confirming the duplicate triggers are gone.

**What that 200 proves:** Vault read ✓ · `apikey` dispatched ✓ · gateway passed ✓ ·
handler authenticated ✓ · body parsed ✓ · service account decoded and parsed ✓ ·
**Google OAuth2 token exchange succeeded** ✓ · service-role client created ✓ ·
`device_tokens` query executed ✓.

**What it does not prove:** FCM was never called — the function exited at "no tokens
registered" before `messages:send`. **L6, L7 and L8 remain entirely untested.**

---

## 2b. ANDROID END-TO-END DELIVERY — PASSED (2026-09-09)

A push notification was **delivered to a real Samsung SM-A047M, displayed, and tapped.**

```
I/flutter: [FCM] Background push message: 0:1788963693009313%e2763796e2763796
I/NotificationManager: com.yuhblockin.v1: notify(0, FCM-Notification:162949570,
    Notification(channel=yuh_blockin_alert_normal_alert_v2 ...)) as user
I/flutter: Notification opened app: {alert_id: fe0ce3df-…, click_action: FLUTTER_NOTIFICATION_CLICK}
I/flutter: Push notification tapped with payload: fe0ce3df-…
```

Three alerts delivered: `3b367c5d…`, `fe0ce3df…`, `f3e7a15e…`.

**Full chain confirmed:** `alerts` INSERT → trigger → Vault → `apikey` → alerts-fcm auth →
service account → Google OAuth → `device_tokens` → FCM `messages:send` → FCM delivery →
device → `NotificationManager.notify` → visible → tapped.

**Conclusion: the original symptom was entirely server-side.** Four stacked defects, none
of them on the device. H0/H1 (iOS authorization / presentation state) were inferred from
"FCM reports success" — but FCM was never reached, so that premise never held.

### Legacy → publishable key migration also validated in the same run

No 401s, no "Legacy API keys are disabled". The app authenticated anonymously, resolved
its user, registered plate `101-TEST`, and Realtime connected — proving **GoTrue,
PostgREST and Realtime all accept an `sb_publishable_` key** through supabase_flutter
2.17.2, despite the SDK sending it as a Bearer token on those paths (only the functions
client omits it). A pre-migration probe of `/auth/v1/settings` with the key on both
`apikey` and `Authorization: Bearer` returned `200` on both, and the live run confirmed it.

### Two latent issues observed during the passing run

- `ℹ️ Background: Skipping system notification (app is in foreground)` fired **while the
  app was backgrounded** — `_isAppInForeground` is stale. Harmless here (the FCM SDK
  auto-displays the `notification` block when backgrounded, and iOS displays `aps.alert`
  at system level), but it is a real bug. Recorded as D5 in §7b.
- `sound=null` on the delivered notification. Expected on Android 8+, where sound comes
  from the channel — but it is the Android analogue of the still-open iOS H3.

---

## 2c. iOS — TEST B AND TEST C PASSED (2026-09-09, Build 23)

**Device:** iPhone 14, iOS 16.4, via BrowserStack App Live, TestFlight install.

**TEST C — locked iPhone: PASS.** Screenshot shows the Lock Screen displaying:
`Yuh Blockin — Move Request — MegaFox59 needs you to move.` plus a second stacked alert.

**TEST B — backgrounded: PASS.** Badge set to 1, alerts present in Notification Center.

### iOS's own log is the authoritative evidence

```
[com.yuhblockin.v1] Requesting authorization with options 7          (alert|sound|badge)
[com.yuhblockin.v1] Received remote notification request 03B5-953D
    [ waking: 0, hasAlertContent: 1, hasSound: 1 hasBadge: 1 ]
[com.yuhblockin.v1] Badge can be set ... [ canBadge: 1 badgeNumber: 1 ]
[com.yuhblockin.v1] Delivered user visible push notification 03B5-953D
[com.yuhblockin.v1] Adding notification 03B5-953D
    [ hasAlertContent: 1, shouldPresentAlert: 1 hasSound: 1 shouldPlaySound: 1 ]
BBDataProviderProxy com.yuhblockin.v1 has enqueued a bulletin request
<Error>: [com.yuhblockin.v1] Failed to find sound "high_alert_1.wav"     ← ONLY DEFECT
```

**H0 and H1 are DISPROVEN.** `shouldPresentAlert: 1` and *"Delivered user visible push
notification"* prove authorization was granted and presentation enabled. The hypotheses
that drove Build 21 and T0 were never the problem.

**H3 is CONFIRMED and is the only remaining defect.** Root cause located precisely: all
seven `.wav` files exist in `ios/Runner/`, but `project.pbxproj` contained **zero** `.wav`
references — they were never added to the target, so they never reached `Runner.app/`.
Forensics on the Build 21 IPA had already shown no `.wav` at bundle root.

### T0's instrumentation could not be used — design flaw

T0 logs via Swift `print()`, which writes to stdout. **iOS device syslog does not capture
stdout** — only `NSLog`/`os_log`. A 113,862-line device log contained **zero**
`[APNS-DIAG]` lines, and zero of the pre-existing AppDelegate prints. Flutter's
`debugPrint` does reach syslog, which is why Dart lines appeared.

If native diagnostics are needed again, use `NSLog`. In this case SpringBoard's
`UserNotificationsServer` logging proved more informative than the instrumentation would
have been.

### Also observed

`willPresentNotification delivery succeeded` fired for a second notification — that is the
**foreground** path, which `push_notification_service.dart:360` suppresses by design. Not
a defect.

---

## 3. Configuration created this session (operator-managed, not in git)

| Where | Name | Notes |
|---|---|---|
| Dashboard → API Keys → Secret keys | `alerts_fcm_trigger` | Names must match `^[a-z_][a-z0-9_]*$` — hyphens are rejected |
| Vault | `alerts_fcm_project_url` | 40 chars, no trailing slash |
| Vault | `alerts_fcm_secret_key` | the `sb_secret_…` value |
| Edge Function secret | `FIREBASE_SERVICE_ACCOUNT_JSON` | re-uploaded; sha256 verified against `base64 -w0` of the source file |
| Edge Function config | `verify_jwt = false` | set via CLI `--no-verify-jwt` |

Source service account file:
`~/Documents/lab/credentials/firebase-priv-key/yuh-blockin-8dfa0-firebase-adminsdk-fbsvc-6ecd06f028.json`
(2391 bytes, `project_id = yuh-blockin-8dfa0`, matches the app's `GoogleService-Info.plist`).

⚠️ **Operational trap:** a future CLI deploy **without** `--no-verify-jwt` re-enables the
legacy gate and silently breaks the trigger again. Always pass the flag, or set the
Dashboard toggle immediately after deploying.

⚠️ **Deprecation:** `anon` and `service_role` keys are deprecated by **end of 2026**. The
function still reads the legacy `SUPABASE_SERVICE_ROLE_KEY` env var internally; that must
become `ctx.supabaseAdmin` or `SUPABASE_SECRET_KEYS` before then.

---

## 4. Build 21 artifact — forensically verified

IPA `~/Downloads/yuh_blockin_app (2).ipa`, sha256 `d323df45…`, 37,549,259 bytes.

Signed entitlements read directly from the Mach-O `LC_CODE_SIGNATURE` (macOS `codesign`
is unavailable on this Linux workstation):

```
application-identifier                KPHP66W43B.com.yuhblockin.v1
aps-environment                       production
beta-reports-active                   true
com.apple.developer.team-identifier    KPHP66W43B
get-task-allow                        false
```

Embedded profile (`A parking alert app ios_app_store 1784369155`, expires 2027-07-18)
agrees on all five keys. `CFBundleVersion = 21`. T0 instrumentation confirmed present in
the compiled binary; pre-T0 literals confirmed absent.

**Excluded as causes at artifact level:** missing entitlement, environment mismatch,
stale build, and the `applicationDidBecomeActive` override risk (it compiled).

**Artifact discrepancies still open:** `MinimumOSVersion 15.0` vs `IPHONEOS_DEPLOYMENT_TARGET
13.0`; built with Xcode 26 / SDK 26.5 (known iOS 26 *simulator* token regression);
Firebase swizzling enabled, making the manual `apnsToken` assignment redundant; sound
files packaged under `flutter_assets` where `aps.sound` cannot resolve them (**sound**
defect, not a visibility defect); App Store profile with **no provisioned devices**, so
**TestFlight is the only install route**.

---

## 4b. ROOT CAUSES — the complete list

Six independent defects. Fixing any one alone would have changed nothing observable,
which is why the symptom appeared intractable.

| # | Defect | Layer | Fixed in |
|---|---|---|---|
| 1 | `notify_alert_push()` built its auth header from `current_setting('supabase.service_role_key')`, a GUC never set → NULL header → 401, Edge Function never ran | server | `2ba3f5e` |
| 2 | Three duplicate AFTER INSERT triggers on `alerts`, all calling alerts-fcm | server | `2ba3f5e` |
| 3 | `FIREBASE_SERVICE_ACCOUNT_JSON` truncated (~95 base64 chars lost in a paste) | server | operator |
| 4 | `@supabase/supabase-js` pinned at 2.28.0, which predates the `./cors` subpath `@supabase/server` requires → BOOT_ERROR | server | `2ba3f5e` |
| 5 | `GeneratedPluginRegistrant.register(with: self)` removed from AppDelegate → every iOS plugin's platform channel dead → `shared_preferences` failed → `_saveToken()` read a null `user_id` → **no iOS token was ever stored** | client | Build 23 |
| 6 | Seven `.wav` files present in `ios/Runner/` but absent from `project.pbxproj` → never copied into the bundle → `aps.sound` unresolvable | client | Build 24 |

Plus the deliberate migration off legacy `anon`/`service_role` keys, which were disabled
mid-investigation and broke every existing install until the publishable-key build shipped.

**None of these was H0 or H1.** The investigation began from "iOS notifications don't
appear when backgrounded or locked", which pointed at device-side authorization. That was
a reasonable inference from "FCM reports success" — but FCM was never actually reached.

---

## 5. Hypothesis register

| ID | Hypothesis | Status |
|---|---|---|
| **F1** | Trigger could not authenticate to the Edge Function | ✅ **CONFIRMED AND FIXED** |
| **F2** | `onConflict: 'user_id, fcm_token'` contains a space; PostgREST may reject it, so no iOS token is ever stored | ❌ **DISPROVEN.** 6 iOS + 10 Android rows existed, all written the same day. Upserts work. |
| **F5** | No `device_tokens` DDL/RLS in the repo; a missing unique constraint or a blocking RLS policy would make every upsert fail silently | ❌ **DISPROVEN.** Writes succeed. |
| **F3** | `THIRD_PARTY_AUTH_ERROR` unhandled — FCM's error for an APNs credential problem in the Firebase project | ❌ **Not reproduced.** Firebase holds a production APNs auth key, Key ID `XR7X7N6KLS`, Team ID `KPHP66W43B`, matching the signed artifact. FCM has now been called successfully many times (Android) with no such error. Remains theoretically possible on the APNs leg only. |
| **H0** | Authorization never reaches a granted state, so iOS delivers silently | ❌ **DISPROVEN.** iOS logged `Requesting authorization with options 7` and `Delivered user visible push notification`. Authorization was granted throughout. |
| **H1** | Authorization granted but presentation settings disabled (Lock Screen / Deliver Quietly / Scheduled Summary) | ❌ **DISPROVEN.** `shouldPresentAlert: 1`, bulletin enqueued, alert visible on the Lock Screen. |
| **H4** | Stale/duplicate `device_tokens` rows | ❌ **DISPROVEN.** 6 iOS tokens across 6 distinct users, exactly 1 each, all fresh. No accumulation. |
| **H5** | APNs environment mismatch | Weakened — artifact and profile agree on `production` |
| **H2** | `criticalAlert: true` without the entitlement | Settled at artifact level: no critical-alerts entitlement exists. Runtime effect answered by T0's `criticalAlertSetting` read. |

---

## 6. Constraints and environment

- **No physical iPhone. No local Mac.** Workstation is Linux/Kali, no Swift toolchain.
  Supabase CLI **is** available at `npx supabase` (devDependency, 2.114.0).
- Push Notification Console **delivery logs are development-environment only** — a
  production-signed build cannot produce them.
- Simulator registers with APNs in **sandbox only**, and registration is reported to fail
  inside VMs.
- AWS Device Farm strips the Push Notifications entitlement on re-sign; **BrowserStack
  App Live + TestFlight** is the only viable remote real-device route.

---

## 7. Standing constraints

- Git operations are manually controlled by the user. No commits, branches, merges,
  rebases or pushes without explicit instruction.
- **Do not modify any Codemagic YAML file.** Production builds use the Codemagic GUI
  workflow.
- **Do not modify:** `ios/Runner/Runner.entitlements`, `ios/Runner/Info.plist`,
  `lib/core/services/push_notification_service.dart`, the FCM/APNs payload construction
  in `alerts-fcm` (lines ~175–219), or signing configuration.
- **Never log a full APNs device token to CI.** Byte count and short prefix only.
- **Never put a secret in source, migrations, git, or SQL Editor history.** Use Vault
  (Dashboard UI) and `supabase secrets set --env-file`.
- Do not claim anything is fixed without evidence at the relevant layer.
- Source ≠ built artifact. Verify the artifact.
- Official documentation is the authority. Do not attribute requirements to Apple or
  Supabase that they do not state.
- One controlled change at a time; update the hypothesis when evidence arrives.
- `HANDOFF.md` is stale — read `HANDOFF_AUDIT.md` §5 before trusting it.

---

## 7b. Known latent defects — identified, deliberately NOT fixed

Found during investigation. None is the APNs root cause; none was touched, to avoid
changing app behaviour mid-investigation.

### D1 — `userExists()` trusts the auth session instead of the database

`lib/core/services/simple_alert_service.dart` (~line 205):

```dart
if (currentSession != null && !currentSession.isExpired) {
  if (currentSession.user.id == userId) {
    return true;          // trusts the JWT, never queries public.users
  }
}
```

`auth.users` and `public.users` are **different tables**. Deleting a row from
`public.users` does not invalidate the anonymous session, so this fast path reports a
user that no longer exists. `registerPlate()` then inserts into `plates`, which carries
`plates_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE`, and
the insert dies on a foreign-key violation.

**Confirmed 2026-09-09:** after the database was cleared, plate registration failed on a
real Android device with `public.users` at 0 rows.

**Workaround (no code change):** clear app storage / reinstall. That drops both the cached
`user_id` and the anonymous session, so `getOrCreateUser()` mints a fresh UID and upserts
it into `public.users` first.

**Impact:** any future user-row deletion, database restore, or environment switch strands
every existing install in an unrecoverable-looking state.

**Possible fix (not applied):** have the fast path verify against `public.users`, or treat
an FK violation on insert as a signal to re-run `getOrCreateUser()`.

### D2 — Registration errors are flattened into a generic message

`lib/features/plate_registration/plate_registration_screen.dart:355` maps any unrecognised
exception to `"Registration failed. Please try again."`, hiding the underlying Postgres
error. The FK violation above was invisible in the UI and only identifiable from logcat.

### D3 — Leftover test bypass in the Edge Function

`supabase/functions/alerts-fcm/index.ts:~276` — `if (alert_id && alert_id !== 'test-123')`
skips the `push_sent` update for a hardcoded magic id.

### D5 — `_isAppInForeground` goes stale

Observed 2026-09-09 during the passing Android run: `push_notification_service.dart:360`
logged `Skipping system notification (app is in foreground)` while the app was actually
backgrounded. `setAppInForeground()` (called from `main.dart:242/272/276`) is not tracking
lifecycle reliably.

Harmless in the observed case — the FCM SDK auto-displays the `notification` block when
the app is backgrounded, and iOS renders `aps.alert` at system level without involving the
Dart handler. But the suppression logic is unsound and could hide notifications in states
where the app *is* alive and expected to render them itself.

### D4 — Unsafe catch binding

Same file, final `catch (err)` returns `err.message` on an `unknown`. Pre-existing;
deploys fine because Supabase does not strict-type-check.

---

## 8. Test matrix (unchanged from `CLAUDE.md`)

- **TEST A — foreground:** informational. The app suppresses system notifications in the
  foreground by design, so a pass proves little.
- **TEST B — background:** CRITICAL. User-visible APNs alert expected.
- **TEST C — locked iPhone:** CRITICAL. User-visible alert on the Lock Screen expected.
- **TEST D — force-quit:** INFO ONLY. Not an acceptance criterion.

---

## 9. Reference — key locations

| Path | Role |
|---|---|
| `supabase/functions/alerts-fcm/index.ts` | Auth gate (line ~91), supabase-js pinned 2.116.0, FCM payload lines ~175–219 unchanged |
| `supabase/migrations/20260908_secure_alert_push_trigger_auth.sql` | Vault + `apikey` trigger function |
| `supabase/migrations/20260908_drop_duplicate_alert_push_triggers.sql` | Drops `alerts_notify_fcm`, `on_new_alert` |
| `ios/Runner/AppDelegate.swift` | T0 instrumentation, committed in `9793066` |
| `lib/core/services/notification_service.dart:97` | **First** iOS authorization request |
| `lib/core/services/push_notification_service.dart:93` | Second request (`criticalAlert: true`) — do not modify |
| `lib/core/services/push_notification_service.dart:320` | **F2** — `onConflict: 'user_id, fcm_token'` |
| `lib/core/services/push_notification_service.dart:360` | Foreground suppression |
| `supabase/functions/alerts-fcm/index.ts:5-9` | **F3** — `INVALID_TOKEN_ERRORS` lacks `THIRD_PARTY_AUTH_ERROR` |

### Useful diagnostic queries

```sql
-- trigger inventory (must be exactly one)
select tgname from pg_trigger where tgrelid='alerts'::regclass and not tgisinternal;

-- pipeline results
select id, status_code, left(content,300), created
from net._http_response order by created desc limit 10;

-- Vault sanity, no values exposed
select name, length(decrypted_secret) as len from vault.decrypted_secrets
where name like 'alerts_fcm%';

-- NEXT STEP: device_tokens census (F2 / F5)
select platform, count(*) from device_tokens group by platform;
```

### Documentation sources

- https://developer.apple.com/documentation/uikit/uiapplication/registerforremotenotifications()
- https://developer.apple.com/documentation/usernotifications/unnotificationsettings
- https://supabase.com/docs/guides/functions/auth
- https://supabase.com/docs/guides/getting-started/migrating-to-new-api-keys
- https://supabase.com/docs/guides/database/vault
