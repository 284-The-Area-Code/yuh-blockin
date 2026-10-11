# YuhBlockin — Claude Operating Instructions

These instructions apply to Claude Code (Kali or cloud) and Claude Desktop Cowork.
The shared copy of this file and the handoff files lives on the **`ops/instructions`**
branch. Work branches take their instructions from that branch.

Current project state is recorded in **`HANDOFF_CLAUDE.md`**, not in this file.

## Project rules
- This is a production Flutter app (iOS and Android) with a Supabase backend.
- Preserve the existing architecture unless evidence requires a change.
- Make surgical changes. Never modify unrelated files.
- Avoid unnecessary changes: the app is functional; change only what the user has asked for.
- Distinguish verified facts, hypotheses, assumptions, and unknowns.
- Do not claim something is fixed without evidence at the relevant layer (device-level for
  app behaviour).
- Do not assume source configuration equals the final signed artifact. Verify build
  artifacts when dealing with iOS signing, entitlements, APNs, or provisioning.
- Git operations are manually controlled by the user. Do not create commits, branches,
  merges, rebases, or pushes, and do not discard changes, unless explicitly instructed.

## Frozen files (standing rule)
The push notification pipeline works and is frozen. Do not modify, without the user's
explicit approval for that specific change:
- `lib/core/services/push_notification_service.dart`
- `ios/Runner/Info.plist`
- `ios/Runner/Runner.entitlements`
- `supabase/functions/alerts-fcm/index.ts` and the FCM/APNs payload it builds
- Supabase push trigger code and migrations
- signing configuration
- any Codemagic YAML file (production builds use the Codemagic GUI workflow)

If a frozen file is ever changed with approval, re-run TEST B and TEST C on a real
device before calling the change complete.

## Security rules
- Never put a secret in source, migrations, git, or SQL Editor history. Use Supabase
  Vault (Dashboard) and `supabase secrets set --env-file`.
- Never log a full APNs or FCM device token. Byte count and short prefix only.
- Always deploy `alerts-fcm` with `--no-verify-jwt`. Deploying without it re-enables the
  legacy gate and silently breaks the push trigger.

## Reasoning rules
- Official documentation (Apple, Google, Supabase, Firebase) is the authority. Do not
  attribute requirements to a vendor that it does not state.
- Do not invent undocumented internal mechanisms.
- Prefer one controlled change at a time.
- When new evidence arrives, update the hypothesis before recommending more changes.
- If a test fails, identify which layer failed before proposing a fix.

## Notification testing model
- TEST A — foreground: informational. The app suppresses system notifications in the
  foreground by design.
- TEST B — backgrounded: CRITICAL. User-visible alert expected.
- TEST C — locked device: CRITICAL. User-visible alert on the Lock Screen expected.
- TEST D — force-quit: INFO ONLY. Not an acceptance criterion.

## Reference facts
- Bundle ID: `com.yuhblockin.v1`; signed application identifier
  `KPHP66W43B.com.yuhblockin.v1`.
- `ios/Runner/Runner.entitlements`: `aps-environment = production`, confirmed in the
  signed artifact.
- Push path: `alerts` INSERT → trigger `on_new_alert_send_push` → `notify_alert_push()`
  (reads Vault) → `alerts-fcm` (authenticated by the `alerts_fcm_trigger` secret key,
  privileged client `ctx.supabaseAdmin`) → FCM → device.
- Supabase keys: the app uses a publishable key (`sb_publishable_…`); server functions use
  new-format secret keys. Legacy `anon`/`service_role` keys are disabled on this project.

## Session handoff protocol

Before substantive work:
1. Read this `CLAUDE.md`.
2. Read the **Current State** section of `HANDOFF_CLAUDE.md`.
3. Verify the current branch, HEAD commit, and working-tree state.
4. Compare the actual repository state with the handoff.
5. If there are material discrepancies, report them before acting.
6. Follow the workspace ingestion requirements if that document is accessible in this
   environment. If it is not accessible, say so explicitly; never claim it was read.

Before ending a session:
1. Summarize completed work and verification evidence.
2. Record the actual branch, HEAD commit, and uncommitted changes.
3. Record remaining work, blockers, and approved next steps.
4. Update the **Current State** section of `HANDOFF_CLAUDE.md` without erasing historical
   evidence.
5. Identify any local-only resources required for continuation (by description and
   location; never their contents).

Environments do not share files except through pushed Git commits:
- Claude Code on Kali sees the local workspace, including uncommitted files.
- Claude Desktop Cowork sees only the folder it has been given.
- Claude Code cloud sessions see only what has been pushed, starting from the branch the
  session was given.

Do not assume a file that exists in one environment is present in another. When using
Cowork or a cloud session, first confirm that this repository and its instructions are
accessible.
