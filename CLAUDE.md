# YuhBlockin — Claude Code Operating Instructions

## Project rules
- This is an active Flutter/iOS production debugging project.
- Preserve the existing architecture unless evidence requires a change.
- Make surgical changes during debugging experiments.
- Never modify unrelated files.
- Distinguish verified facts, hypotheses, assumptions, and unknowns.
- Do not claim something is fixed without device-level evidence.
- Do not assume source configuration equals the final signed artifact.
- Verify build artifacts when dealing with iOS signing, entitlements, APNs, or provisioning.
- Git operations are manually controlled by the user.
- Do not create commits, branches, merges, rebases, or pushes unless explicitly instructed.

## Current investigation
We are debugging iOS APNs delivery for YuhBlockin.

Primary symptom: notifications are not appearing reliably when the app is backgrounded or the iPhone is locked.

Final objective: a production-signed YuhBlockin iOS build receives and displays a user-visible APNs alert while the app is backgrounded and while the iPhone is locked.

## Build 21 experiment
Build 21 tests whether native iOS notification authorization is being requested after APNs registration.

Leading hypothesis: `UNUserNotificationCenter.requestAuthorization(...)` should occur before `registerForRemoteNotifications()`.

Only intended changes:
- `ios/Runner/AppDelegate.swift`
- `pubspec.yaml` build number → `1.0.0+21`

Do not modify during this experiment:
- `lib/core/services/push_notification_service.dart`
- `ios/Runner/Info.plist`
- `ios/Runner/Runner.entitlements`
- Supabase push code
- FCM/APNs payload
- signing configuration
- unrelated files

## Known APNs evidence
Current entitlement file: `ios/Runner/Runner.entitlements`
Expected: `aps-environment = production`

A previous signed-artifact forensic inspection confirmed the final executable contained `aps-environment = production`.
Therefore the missing-APNs-entitlement hypothesis is not the leading hypothesis.

Bundle ID: `com.yuhblockin.v1`
Previously verified signed application identifier: `KPHP66W43B.com.yuhblockin.v1`

## Current architecture
Native `ios/Runner/AppDelegate.swift` initializes Firebase, preserves Flutter application startup, sets the notification center delegate, handles APNs registration callbacks, and passes the APNs device token to Firebase Messaging.

Flutter notification service calls Firebase Messaging `requestPermission(...)`, waits for an APNs token, obtains the FCM token, and saves device tokens to Supabase.

Server push code is `supabase/functions/alerts-fcm/index.ts`. Its current iOS payload includes `apns-priority: 10`, `apns-push-type: alert`, `aps.alert`, `aps.sound`, and `aps.badge`.

Do not rewrite this during Build 21.

## Testing model
- TEST A — foreground: informational/expected application behavior.
- TEST B — background: CRITICAL; expected user-visible APNs alert.
- TEST C — locked iPhone: CRITICAL; expected user-visible APNs alert on Lock Screen.
- TEST D — force-quit: INFO ONLY; do not use this test alone to determine whether Build 21 succeeds.

## Required evidence
Build 21 should establish:
1. Authorization is requested.
2. Authorization result is logged.
3. APNs registration is called after authorization.
4. APNs registration succeeds or fails explicitly.
5. APNs device token is received.
6. APNs token is handed to Firebase Messaging.
7. Correct device/FCM token is available to the server.
8. Controlled push reaches the device in background.
9. Controlled push reaches the locked device.

## Reasoning rules
- Use official Apple documentation as the authority for Apple APNs behavior.
- Do not invent undocumented internal APNs/apsd mechanisms.
- Do not treat `isRegisteredForRemoteNotifications` immediately after calling registration as definitive proof of success; use the registration callback.
- Prefer one controlled change at a time.
- When new evidence arrives, update the hypothesis before recommending more changes.
- If a test fails, identify which layer failed before proposing a fix.

## Immediate state
The AppDelegate authorization-order diff has been reviewed conceptually but must be checked against the actual working tree before implementation.

Before changing anything:
1. Read `HANDOFF.md`.
2. Inspect `git status`.
3. Inspect `git diff`.
4. Inspect `ios/Runner/AppDelegate.swift`.
5. Confirm the actual repository state matches the handoff.

Do not modify anything until the user explicitly approves the next implementation step.
