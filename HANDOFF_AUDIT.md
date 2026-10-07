# Claude Takeover Audit

Date: 2026-09-08
Scope: read-only takeover audit of the YuhBlockin iOS APNs investigation.
No project source files were modified. No git staging, commit, branch, merge, rebase, or push
was performed. This file is the only artifact created.

---

## 1. Verified State

### Git

- Branch: `firebase-production-push`
- HEAD: `6716fb8` — "Set iOS build number to 20"
- `origin/firebase-production-push` is at the **same** commit. Local and remote are in sync —
  not ahead, not behind.
- Recent history: `6716fb8` ← `afc1d15` (Fix iOS APNs entitlement key) ← `baf31eb` (Add iOS
  APNs forensic diagnostic workflow) ← `7602eda` (Link Firebase configuration for iOS Build 19)
  ← `2350e1c` (Fix iOS APNs registration for Build 18).

### Entitlements — `ios/Runner/Runner.entitlements`

Committed and unmodified. Contains exactly one key:

```
aps-environment = production
```

There is **no** `com.apple.developer.usernotifications.critical-alerts` entitlement.

### Xcode project — `ios/Runner.xcodeproj/project.pbxproj`

- `PRODUCT_BUNDLE_IDENTIFIER = com.yuhblockin.v1` on the Runner Debug / Release / Profile
  configurations.
- `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` present on all three Runner configs.
- `SystemCapabilities { com.apple.Push = { enabled = 1 } }` on target `97C146ED1CF9000F007C117D`.
- `CODE_SIGN_IDENTITY[sdk=iphoneos*] = "iPhone Developer"` at project level. Codemagic
  overrides this at build time via `xcode-project use-profiles`.
- `IPHONEOS_DEPLOYMENT_TARGET = 13.0`.

### `ios/Runner/Info.plist`

Unmodified. `UIBackgroundModes` = `audio`, `fetch`, `remote-notification`. No
UserNotifications-related keys.

### Firebase — `ios/Runner/GoogleService-Info.plist`

Present. `BUNDLE_ID = com.yuhblockin.v1` (matches Xcode), `PROJECT_ID = yuh-blockin-8dfa0`,
`GCM_SENDER_ID = 1030231082941`.

### `pubspec.yaml`

`version: 1.0.0+20`. Unmodified.

### Native — `ios/Runner/AppDelegate.swift` (working-tree state)

`didFinishLaunchingWithOptions` executes in this order:

1. `super.application(...)` — starts the Flutter engine and registers plugins
2. `FirebaseApp.configure()` (guarded by `FirebaseApp.app() == nil`)
3. `UNUserNotificationCenter.current().delegate = self`
4. `application.registerForRemoteNotifications()`
5. logs `application.isRegisteredForRemoteNotifications`

**There is no `UNUserNotificationCenter.requestAuthorization(...)` call anywhere in the native
layer.** Verified by direct grep of `AppDelegate.swift`.

`didRegisterForRemoteNotificationsWithDeviceToken` calls `super` first, then assigns
`Messaging.messaging().apnsToken = deviceToken`, then logs the first 20 characters of the token.

`didFailToRegisterForRemoteNotificationsWithError` calls `super` first, logs the error, then
pushes the error to Dart over the `com.yuhblockin.v1/push_diagnostics` `FlutterMethodChannel`.

### Dart

`lib/main.dart:895` `_initializeNotificationServices()` runs, in this order:

1. `NotificationService.initialize()` → `lib/core/services/notification_service.dart:73`
   `_requestPermissions()` → `notification_service.dart:97`
   `IOSFlutterLocalNotificationsPlugin.requestPermissions(alert: true, badge: true, sound: true,
   critical: false)`
2. `PushNotificationService().initialize()` (`lib/main.dart:907`) →
   `lib/core/services/push_notification_service.dart:93`
   `_messaging.requestPermission(alert: true, badge: true, sound: true, provisional: false,
   criticalAlert: true)`, then `_waitForAPNSToken()` (20 × 1s poll of `getAPNSToken()`), then
   `getToken()`, then upsert into Supabase `device_tokens` keyed on `user_id, fcm_token`.
3. `BackgroundAlertService` start.

`_saveToken()` returns early if `user_id` is absent from `SharedPreferences`, and again if the
APNs wait times out.

`push_notification_service.dart:360` deliberately suppresses the system notification while the
app is in the foreground, on the basis that the app draws its own in-app alert banner.

### Server — `supabase/functions/alerts-fcm/index.ts`

Sends one FCM HTTP v1 message per token. For `platform === 'ios'` it sets:

```
apns.headers['apns-priority'] = '10'
apns.headers['apns-push-type'] = 'alert'
apns.payload.aps = { alert: { title, body }, sound: '<file>.wav', badge: 1 }
```

alongside a top-level `notification: { title, body }` block. This matches `HANDOFF.md`.

---

## 2. Current Working-Tree Changes

### Modified (tracked)

| File | Nature of change |
|---|---|
| `CLAUDE.md` | Fully rewritten from the old WordPress-project rules into the YuhBlockin iOS/APNs operating instructions. Also a file-mode change 100755 → 100644. |
| `analysis_options.yaml` | Adds an `analyzer.exclude` block for `build/`, `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`. |
| `devtools_options.yaml` | Adds two `extensions` entries (`provider: false`, `shared_preferences: false`). |
| `pubspec.lock` | Modified. |
| `ios/Runner/AppDelegate.swift` | **Uncommitted and not described in `HANDOFF.md`** — see below. |

### The undocumented `AppDelegate.swift` diff

Three changes, none of which is the Build 21 authorization experiment:

1. `super.application(...)` moved to the **top** of `didFinishLaunchingWithOptions`, and the
   explicit `GeneratedPluginRegistrant.register(with: self)` call **removed**. This is
   behaviour-preserving — `FlutterAppDelegate`'s `super` performs plugin registration — but it
   is a real source change.
2. In `didRegisterForRemoteNotificationsWithDeviceToken`, `super` moved from last to **first**.
3. In `didFailToRegisterForRemoteNotificationsWithError`, `super` moved from last to **first**.

Plus comment renumbering. The diff contains **no** `requestAuthorization` call.

### Untracked

`AGENTS.md`, `HANDOFF.md`, `codemagic.yaml.apns-diagnostic.backup`, `node_modules/`,
`package.json`, `package-lock.json`, `supabase/.temp/linked-project.json`.

---

## 3. Build 21 Status

**Not started.** Evidence:

- `pubspec.yaml` is still `version: 1.0.0+20`, not `1.0.0+21`.
- `ios/Runner/AppDelegate.swift` contains no `UNUserNotificationCenter.requestAuthorization(...)`
  call — confirmed by grep.
- The only uncommitted `AppDelegate.swift` change is the `super`-ordering /
  `GeneratedPluginRegistrant` diff described in section 2, which is leftover Build 20 work
  rather than the Build 21 experiment.

The working tree is therefore **not clean** going into Build 21, which conflicts with
`HANDOFF.md`'s instruction to "confirm that only the intended files will change."

---

## 4. Leading APNs Hypothesis

`HANDOFF.md`'s stated hypothesis — that authorization must precede
`registerForRemoteNotifications()` — is **partially contradicted by the source** and should be
restated before it is acted on.

Authorization **is** requested on iOS today, twice, from Dart:
`notification_service.dart:97` (flutter_local_notifications) and
`push_notification_service.dart:93` (firebase_messaging). The accurate framing is therefore not
"authorization is never requested" but:

> **Authorization is requested late, asynchronously, after `registerForRemoteNotifications()` —
> and its outcome is never logged natively.**

Whether the user was ever actually prompted, and what the resulting `UNAuthorizationStatus`,
`alertSetting` and `lockScreenSetting` are on the physical device, is currently **unknown**.
That unknown is the single largest gap in the investigation.

### Competing hypotheses

All of the following fit the observed pattern of "FCM token exists, server reports success, no
visible alert in background or on the Lock Screen". These are hypotheses, not findings.

- **H1 — most consistent with the evidence.** Authorization is granted, but alert *presentation*
  settings are off: Lock Screen or Banners disabled, Deliver Quietly, or Scheduled Summary. This
  produces exactly the observed asymmetry, because the foreground case works via an in-app
  banner drawn by the app rather than by a system notification. Not yet checked on device.

- **H2 — `criticalAlert: true`.** Requested at `push_notification_service.dart:98` and `:515`.
  The app has no `com.apple.developer.usernotifications.critical-alerts` entitlement (confirmed
  in section 1). Whether requesting an unentitled option causes the entire `requestAuthorization`
  call to fail must be confirmed against official Apple documentation before it is treated as a
  cause. Currently an unverified risk.

- **H3 — unresolvable `aps.sound`.** The server sends `sound: '<name>.wav'`, but those files ship
  as Flutter assets (`assets/sounds/…` → `App.framework/flutter_assets/`), not as main-bundle
  resources, so iOS cannot resolve them. Apple's documented behaviour is to fall back to the
  default sound rather than suppress the alert, so this is low priority — but it should be
  verified rather than assumed.

- **H4 — stale `device_tokens` row.** The token the server pushes to may no longer be the one the
  device holds. Unverified; requires comparing the Supabase row against the token the device
  actually reports.

### Status of the ordering experiment

Still worth running, but its real value is **instrumentation**, not remedy: it would make the
authorization result and the registration result observable natively for the first time. It
should be framed as a diagnostic, not as a fix.

---

## 5. Discrepancies Between HANDOFF.md and Repository

| # | `HANDOFF.md` claim | Repository reality |
|---|---|---|
| 1 | "Known remote commit: `afc1d15`" | Remote is at `6716fb8`. `HANDOFF.md` is one commit stale. |
| 2 | Implies `AppDelegate.swift` is at its committed state; instructs to "confirm only intended files will change" | `AppDelegate.swift` already carries an **uncommitted, undocumented** diff (`super` reordering + removal of `GeneratedPluginRegistrant`). |
| 3 | Does not mention them | `CLAUDE.md`, `analysis_options.yaml`, `devtools_options.yaml` and `pubspec.lock` are also modified; `node_modules/`, `package.json` and `package-lock.json` are untracked additions. |
| 4 | "The Dart layer currently calls Firebase Messaging `requestPermission(...)`" | True but incomplete. `NotificationService` (`notification_service.dart:97`) requests iOS authorization **first**, before the Firebase call. `HANDOFF.md`'s framing that authorization happens only via Firebase is inaccurate and materially weakens the stated hypothesis. |
| 5 | "build through the normal Codemagic GUI workflow" | **Hard blocker.** The committed `codemagic.yaml` contains **only** the `ios-apns-forensic` workflow — labelled "diagnostic only", with no `publishing:` section and no TestFlight submission. The production `ios-release` workflow (with `app_store_connect.submit_to_testflight: true`) exists only in the **untracked** `codemagic.yaml.apns-diagnostic.backup`. As the repository stands there is no way to get Build 21 onto the device, so TEST B and TEST C cannot be run. |
| 6 | Build 21 scope = `AppDelegate.swift` + `pubspec.yaml` only | Given #5, a `codemagic.yaml` change is unavoidable. The two-file scope stated in `HANDOFF.md` and `CLAUDE.md` is not achievable as written. |

---

## 6. Exact Next Action

Nothing has been implemented. Two decisions are required before any code is written; the first
is cheap and could close the investigation outright.

### A. Capture the device's current notification settings first

On the physical iPhone: **Settings → Notifications → Yuh Blockin**. Record:

- Allow Notifications
- Lock Screen / Notification Centre / Banners
- Whether Scheduled Summary is on
- Whether Deliver Quietly is on
- Alert style

If Lock Screen is off, **H1 is confirmed and no build is needed**. This takes about a minute and
is strictly higher value than Build 21.

### B. Decide the disposition of the uncommitted `AppDelegate.swift` diff

Either keep it as the Build 21 baseline, or revert it so that Build 21 is a single clean change
against `6716fb8`. Git operations remain manually controlled by the user; Claude will not touch
them.

### Then, if Build 21 is approved

1. **`ios/Runner/AppDelegate.swift`** — inside `didFinishLaunchingWithOptions`, after setting the
   `UNUserNotificationCenter` delegate and before registration, call
   `requestAuthorization(options: [.alert, .sound, .badge])`. Log both `granted` and `error`. Call
   `application.registerForRemoteNotifications()` from inside the completion handler, dispatched
   to the main queue. Preserve `super.application(...)`, both registration callbacks, the
   `Messaging.messaging().apnsToken` handoff, and the `push_diagnostics` method channel.
   Additionally log `getNotificationSettings()` — `authorizationStatus`, `alertSetting`,
   `lockScreenSetting`, `alertStyle` — so that H1 is answered directly from device logs.
2. **`pubspec.yaml`** — set `version: 1.0.0+21`.
3. **`codemagic.yaml`** — restore the `ios-release` workflow from
   `codemagic.yaml.apns-diagnostic.backup` so that a TestFlight-distributable build exists.
   Whether `ios-apns-forensic` is retained alongside it is the user's call.
4. Run `flutter analyze`, present the full diff, and stop again for explicit approval before any
   git operation or build.

### Explicitly not to be touched

`lib/core/services/push_notification_service.dart`, `ios/Runner/Info.plist`,
`ios/Runner/Runner.entitlements`, `ios/Runner.xcodeproj/project.pbxproj`,
`supabase/functions/alerts-fcm/index.ts`, the FCM/APNs payload, signing configuration, and any
unrelated file.

### Verification for Build 21

- Native console output (Console.app or Xcode Devices) must show, in order:
  `requestAuthorization` → granted/error → notification-settings dump →
  `registerForRemoteNotifications` → `didRegister…` or `didFailToRegister…` → APNs device token →
  Firebase Messaging handoff.
- Confirm the `device_tokens` row for this `user_id` with `platform = 'ios'` matches the FCM
  token the device actually reports (addresses H4).
- TEST B (backgrounded) and TEST C (locked) must each produce a user-visible alert. TEST A is
  informational. TEST D (force-quit) is info only and is not an acceptance criterion.
- `flutter analyze` clean.
