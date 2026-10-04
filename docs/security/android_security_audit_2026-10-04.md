# Android Security Audit — 2026-10-04

**Scope:** Android-side security review of YuhBlockin (`com.yuhblockin.v1`) on
branch `audit/android-security-review`, branched from
`feature/onboarding-product-tour` (the current Play Store release
candidate). Read-only audit — no code was modified.

**Method:** Findings are checked against the live guidance at
[developer.android.com/privacy-and-security/security-tips](https://developer.android.com/privacy-and-security/security-tips),
fetched directly rather than relied on from training data. Each finding
cites the specific section of that guidance it maps to.

**Not re-litigated:** this session already closed a set of real Supabase
RLS vulnerabilities (`plates`, `alerts`, `device_tokens`, `users`) and
verified the `subscriptions` table is correctly read-only to the client.
Those are confirmed still correct (see §5) but are backend/database issues,
not Android-platform issues, so they're summarized rather than re-audited
in depth here.

---

## Summary

| Severity | Count |
|---|---|
| Critical | 0 |
| High | 1 |
| Medium | 4 |
| Low | 3 |
| Informational | confirmed-correct items, §5 |

The most significant finding is that the plate **ownership/recovery
key — the one credential that fully controls a registered plate** — is
stored in plain, unencrypted `SharedPreferences`, while a separate local
store (the plate list) uses a field literally named `encryptedData` that is
actually just base64 encoding and provides no real confidentiality. Neither
is exploitable by another app on a normal, non-rooted device (Android's
per-app sandbox already prevents that — see §5), but neither matches the
Android guidance's explicit recommendation to use Keystore-backed
encryption for credential-like values, and both would be trivially
recoverable from a rooted device, a forensic extraction, or a future bug
that exposes the file.

---

## High

### H1. Plate ownership/recovery key stored unencrypted

**Guidance:** "API Key Management — Generation and Storage": *"Use Android
Keystore for optimal key storage... Encrypt stored keys using robust tools
like Tink."* Also "User Data": *"Don't expose user data through... world
accessible files."*

**Found:** `lib/core/services/plate_verification_service.dart:65-73`

```dart
Future<bool> saveKeyLocally({
  required String plateNumber,
  required String ownershipKey,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final storageKey = _storagePrefix + _hashPlateForStorage(plateNumber);
  await prefs.setString(storageKey, ownershipKey);   // <-- plaintext
```

The class's own doc comment confirms what this key is: *"This key is
stored ONLY on their device (like a crypto private key)... Server only
stores a hash of the key... To prove ownership, user must provide the
original key."* This is explicitly a bearer credential — anyone who has it
can dispute/recover ownership of the plate — yet it's written to
`SharedPreferences` with no encryption layer at all, via the plugin's
standard (unencrypted) backend.

**Why it matters:** On a normal, non-rooted device this is *not* readable
by other apps — Android's per-app storage sandbox already handles that (see
§5, "Internal storage isolation"). The real exposure is: a rooted device, a
lost/stolen device subjected to forensic extraction (e.g. via ADB with USB
debugging left on, or a filesystem image), or any future bug/misconfig that
exposes app-private storage (for example, if `allowBackup` were ever
flipped back to `true` without someone remembering to re-check
`backup_rules.xml` coverage). In any of those scenarios, the recovery key
is sitting in cleartext, handing over full account recovery for that plate.

**Recommended fix (not implemented):** Store the ownership key via
`flutter_secure_storage` (backed by Android Keystore on this platform) or
wrap it with `EncryptedSharedPreferences`/Jetpack Security before the
`setString` call, consistent with the Keystore guidance above.

---

## Medium

### M1. `usesCleartextTraffic="true"` with no network security config

**Guidance:** "Networking — IP Networking": *"Use HTTPS over HTTP
everywhere HTTPS is supported... Follow network security configuration
best practices."*

**Found:** `android/app/src/main/AndroidManifest.xml:24`

```xml
android:usesCleartextTraffic="true"
```

No `android:networkSecurityConfig` attribute is set, and no
`network_security_config.xml` exists anywhere under `android/app/src/main/res/xml/`
— this is a blanket, app-wide permission to make unencrypted HTTP
connections to *any* host, not scoped to a specific debug/dev domain.

Checked whether this is actually load-bearing: `grep -rn "'http://\|\"http://"
lib/` (excluding `https://` matches) returns nothing. Every network call in
the app's own code goes to Supabase/Firebase/RevenueCat, all HTTPS. No
legitimate current use for this flag was found.

**Why it matters:** this is attack surface that doesn't appear to be used
for anything. If any dependency (current or future) ever makes an
unexpected HTTP request, or a user is on a network with a transparent
HTTP-downgrade proxy, cleartext is currently permitted app-wide rather than
blocked by default.

**Recommended fix (not implemented):** Set
`android:usesCleartextTraffic="false"`, or better, add a
`network_security_config.xml` with `cleartextTrafficPermitted="false"` as
the base config (optionally allow-listing `localhost` only, if local dev
builds need it).

### M2. "Encrypted" local plate storage is actually just base64

**Guidance:** "Cryptography": *"Don't implement your own cryptographic
algorithms."* (Not doing so here — but the naming implies crypto that isn't
present, which is its own risk: it signals a false sense of security to
anyone reading/maintaining this code.)

**Found:** `lib/core/services/plate_storage_service.dart`

```dart
final encryptedData = base64.encode(utf8.encode(jsonString));   // line 118
await prefs.setString(_storageKey, encryptedData);
```

The class does have a `_encryptionSalt` constant (line 14), but it's only
used for a SHA-256 tamper-detection checksum (`_calculateChecksum`, line
533-538) — a genuinely good practice for corruption detection — not for
encrypting the stored payload itself. The variable/field names
(`encryptedData`, `_encryptionSalt`) imply confidentiality that doesn't
exist: base64 is an encoding, not encryption, and is trivially reversed by
anyone with the raw string (no key needed).

**Why it matters:** same threat model as H1 — not exploitable by another
app on a normal device, but gives zero real protection against a rooted
device or forensic extraction, despite the naming suggesting otherwise to
future maintainers.

**Recommended fix (not implemented):** Either rename these to reflect what
they actually do (`_encodedData`, `_checksumSalt`) to stop implying false
security, or — better, since this stores the user's full registered-plate
list — route it through the same secure-storage mechanism recommended for
H1.

### M3. No `FLAG_SECURE` on any screen

**Guidance:** "User Data": *"Don't expose user data through... [other
exposure channels]."* (General principle; this specific control isn't
named on the security-tips page itself, but is the standard Android
mechanism for exactly this threat.)

**Found:** `grep -rn "FLAG_SECURE\|flagSecure\|setSecure" android/ lib/`
returns no matches anywhere in the project.

**Why it matters:** the app has a screen whose entire purpose is displaying
a one-time, sensitive recovery key (plus the "Share Key" OS-share-sheet
flow added this session). With no `FLAG_SECURE` set on that
window/activity, any other app with screen-recording capability, or a
malicious accessibility service (not a hypothetical — this exact device has
a legitimate `AccessibilityService`-based automation tool installed for
unrelated reasons, confirming the capability exists and is in active use on
real devices in this project's own testing), can capture the key off
screen. A plain screenshot saved to a cloud-synced photos folder is an
even lower bar.

**Recommended fix (not implemented):** Set `FLAG_SECURE` via a platform
channel (or the `flutter_windowmanager` package) on whichever
screen(s) display the raw ownership key in plaintext.

### M4. Plaintext plate number logged, ungated, on a live screen

**Guidance:** "User Data": *"Limit logging of PII... Logs are shared
resource accessible with READ_LOGS permission."*

**Found:** `lib/features/plate_registration/plate_registration_screen.dart:104`

```dart
debugPrint('✅ Set $plate as primary vehicle');
```

No `kDebugMode` guard around this call (contrast with line 88 in the same
method, which *is* correctly gated — this looks like an inconsistency/
oversight rather than a deliberate choice). `debugPrint` is **not**
automatically stripped from release builds by Flutter; it only avoids
release builds if explicitly wrapped in `if (kDebugMode)`, same as every
other correctly-gated call site in this codebase.

This directly contradicts the app's own stated privacy model, verbatim
from `docs/app_store_review_notes.md`: *"Plates are hashed with SHA-256 on
the device before transmission; the plaintext plate never leaves the phone
and is never stored on our servers."* Logcat isn't "leaving the phone" in
the network sense, but it is a second, independent plaintext-exposure
channel beyond the one the privacy model explicitly guards against.

A second, lower-severity instance exists at
`lib/features/premium_alert/alert_workflow_screen.dart:1124`
(`debugPrint('📢 Sending real alert to: $plateNumber');`, also ungated) —
see L2 below for why this one is lower severity.

**Recommended fix (not implemented):** Wrap `plate_registration_screen.dart:104`
in `if (kDebugMode)` to match the pattern already used everywhere else in
this file and in `simple_alert_service.dart`.

---

## Low

### L1. Unused `webview_flutter` dependency

**Guidance:** "WebView" section's existence of multiple non-trivial
hardening requirements (JS-interface exposure, cache clearing, provider
updates) implies: don't carry a WebView you don't need, since every
unused dependency is still attack surface and an ongoing CVE-exposure
liability for zero functional benefit.

**Found:** `pubspec.yaml:50` declares `webview_flutter: ^4.13.0`. `grep -rln
"WebView\|webview_flutter" lib/` returns no matches — nothing in the app
actually uses it.

**Recommended fix (not implemented):** Remove the dependency if it's
genuinely unused, or confirm a near-term feature actually needs it.

### L2. Dead code also has an ungated plaintext-plate log

**Found:** `lib/features/premium_alert/alert_workflow_screen.dart:1124`.
Confirmed `AlertWorkflowScreen(` has exactly one match in the entire
codebase — its own constructor definition — meaning it is never
instantiated anywhere and is unreachable through the real app. This
matches an earlier finding from this same session (the "feedback
interface" investigation) that this screen, along with
`alert_confirmation_screen.dart`, is leftover dead code from a superseded
send-flow implementation.

**Why it matters:** not currently exploitable since the screen can't be
reached, but it's compiled into the APK regardless, and if this code is
ever revived (e.g. to resurrect the sender-side status tracker that
investigation flagged as missing) the same ungated-logging bug would ship
with it.

**Recommended fix (not implemented):** Delete `alert_workflow_screen.dart`
and `alert_confirmation_screen.dart` if they're confirmed permanently
superseded, or fix the logging gate if the screen is ever wired back in.

### L3. Firebase API keys present across git history

**Found:** `git log --all -p` across `*.dart`/`*.properties`/`*.json`
surfaces multiple `AIzaSy...`-format Firebase API keys committed over the
project's history (Firebase config, not Supabase/RevenueCat).

**Why it matters — calibrated correctly:** Firebase web/Android API keys
are explicitly *not* treated as secrets by Firebase's own design — they
identify a Firebase project, not authenticate access to it; real
authorization is enforced by Firebase Security Rules and, separately, by
*restricting* the key in Google Cloud Console (by Android package name +
SHA-1/256 signing fingerprint, and by which specific APIs it can call).
This is **not** the same severity as the `service_role`/private-key leaks
this session already found and fixed elsewhere — grep confirms no
`service_role` key, no RSA/EC private key block, and no RevenueCat
(`goog_`/`appl_`) key anywhere in history. This finding is only about
confirming the Firebase keys are properly *restricted*, which is a Google
Cloud Console setting, not something visible from the repo.

**Recommended fix (not implemented):** In Google Cloud Console → APIs &
Services → Credentials, confirm each of these keys is restricted to this
app's package name (`com.yuhblockin.v1`) + release signing certificate
fingerprint, and scoped to only the Firebase APIs actually used (FCM,
etc.). If any are unrestricted, restrict them; rotating is optional if
restriction is applied, since an unrestricted-but-now-restricted key stops
being abusable going forward.

---

## 5. Checked and confirmed correct (not just problems — the full picture)

- **RLS on `plates`, `alerts`, `device_tokens`, `users`**: closed earlier
  this session (migrations `20260914_secure_plates_table.sql`,
  `20260924_secure_alerts_device_tokens_users.sql`). Spot-checked the
  migration files again — still in place, no regression.
- **`subscriptions` table**: confirmed via this session's own live device
  testing that the client's local "demo purchase" write path fails against
  RLS exactly as the migration comment intends (*"A client that can write
  its own status can grant itself premium"* — it can't, here).
- **R8/ProGuard**: `android/app/build.gradle.kts:57-61` — `isMinifyEnabled
  = true`, `isShrinkResources = true`, both default + custom proguard rules
  applied for the release build type. Correctly enabled.
- **`android:allowBackup="false"`**: set at the application level
  (`AndroidManifest.xml:21`), *and* belt-and-suspenders —
  `backup_rules.xml` and `data_extraction_rules.xml` both additionally
  exclude the entire `sharedpref` domain from full backup, cloud backup,
  and device transfer, covering the case where `allowBackup` is ever
  flipped back to `true` without someone re-auditing these files at the
  same time.
- **Internal storage isolation**: per guidance, default internal storage
  is already isolated per-app by the OS; the app doesn't use
  `MODE_WORLD_READABLE`/`MODE_WORLD_WRITEABLE` anywhere (not present in the
  codebase), and defines no `ContentProvider` at all, so that whole
  guidance section has no applicable surface here.
- **Exported components**: `MainActivity` is `exported="true"`, which is
  correctly *required* for a launcher activity (`MAIN`/`LAUNCHER`
  intent-filter) — not a finding. Its intent-filter is the standard
  launcher filter only; no custom URL scheme / deep link is declared, so
  there's no externally-triggerable deep-link surface to audit.
  `BackgroundService` and `WatchdogReceiver` are both correctly
  `exported="false"`. `BootReceiver` is `exported="true"` but correctly
  guarded with the system-held `android.permission.RECEIVE_BOOT_COMPLETED`
  permission, consistent with guidance for receivers that must accept a
  system broadcast.
- **Permission footprint**: requested permissions
  (`INTERNET`, `ACCESS_NETWORK_STATE`, `POST_NOTIFICATIONS`, `VIBRATE`,
  `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`, `USE_FULL_SCREEN_INTENT`,
  `FOREGROUND_SERVICE[_DATA_SYNC]`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`,
  `SCHEDULE_EXACT_ALARM`) all map directly to the app's stated
  notification/background-alert functionality. No location, contacts,
  camera, phone-state, or storage permissions requested — a genuinely
  minimal footprint, matching the "minimize permission requests" guidance
  well.
- **Secrets not in source control**: `android/key.properties` (release
  signing config) and `dart_define.json` (RevenueCat production key) are
  both confirmed `.gitignore`'d. No Supabase `service_role` key, no
  RSA/EC private key block, and no RevenueCat key found anywhere in `git
  log --all -p` across the project's history.
- **Supabase publishable key**: `sb_publishable_...` format, by design
  meant to be public/shippable (not a traditional secret) — security is
  enforced entirely by RLS, which is the piece actually audited/fixed
  above, not the key's presence in source.

---

*No code was changed as part of this audit. All recommended fixes above
are proposals for a follow-up change, not applied here.*
