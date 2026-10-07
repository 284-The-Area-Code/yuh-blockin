# Push Notification Test Tools

How to send a test push to a phone from your PC, and how to tell what happened.

---

## Quick start

```bash
cd ~/Documents/lab/yuh-blockin
./tools/send_test_push.py --token-file ~/.yuhblockin_ios_token --urgency high
```

That sends one real notification to the device that owns that token.

---

## One-time setup

You need three things. Two are already done on this machine.

### 1. Python packages

```bash
pip install pyjwt cryptography
```

### 2. The Firebase service account file

Already present at:

```
~/Documents/lab/credentials/firebase-priv-key/yuh-blockin-8dfa0-firebase-adminsdk-fbsvc-6ecd06f028.json
```

The tool finds it automatically. To use a different one:

```bash
export YUHBLOCKIN_SERVICE_ACCOUNT=/path/to/service-account.json
```

**Never commit this file.** `.gitignore` already blocks `*firebase-adminsdk*.json`.

### 3. A device token

Get one from the database after the app has run on the device:

```sql
select platform, fcm_token, updated_at
from device_tokens
order by updated_at desc;
```

Save it to a private file so it never enters your shell history:

```bash
umask 077
printf '%s' 'PASTE_THE_TOKEN_HERE' > ~/.yuhblockin_ios_token
```

The iOS token is already saved there.

---

## Everyday use

### Send a real notification

```bash
./tools/send_test_push.py --token-file ~/.yuhblockin_ios_token --urgency high
```

### Test without disturbing anyone

`--validate-only` asks FCM to check the token and payload, then throw the message away.
Nothing reaches the device. Use this when you only want to know whether the token is
still alive.

```bash
./tools/send_test_push.py --token-file ~/.yuhblockin_ios_token --validate-only
```

A dry run returns `"name": ".../messages/fake_message_id"` — the `fake_message_id` is
how you know nothing was delivered.

### Android instead of iOS

```bash
./tools/send_test_push.py --token-file ~/.yuhblockin_android_token --platform android
```

### Change the urgency (this picks the sound)

| `--urgency` | sound sent |
|---|---|
| `low` | `low_alert_1.wav` |
| `normal` | `normal_alert.wav` (default) |
| `high` | `high_alert_1.wav` |

### Custom message text

```bash
./tools/send_test_push.py --token-file ~/.yuhblockin_ios_token --message 'Testing build 24'
```

### Test all three sounds in a row

```bash
for u in low normal high; do
  ./tools/send_test_push.py --token-file ~/.yuhblockin_ios_token --urgency $u
  sleep 3
done
```

---

## Reading the result

### Success

```
HTTP 200
response: { "name": "projects/yuh-blockin-8dfa0/messages/bbac5f26-..." }
RESULT: FCM accepted the message.
```

**This means FCM accepted it and handed it to Apple or Google.** It does *not* prove the
phone displayed anything — that is the next leg, and you confirm it by looking at the
device.

### Errors and what they actually mean

| Error | Meaning | What to do |
|---|---|---|
| `UNREGISTERED` | Token is dead: app uninstalled, token rotated, or a BrowserStack session ended and wiped the device | Get a fresh token from `device_tokens` |
| `THIRD_PARTY_AUTH_ERROR` | Apple rejected the APNs credential | Check the APNs auth key in Firebase Console → Project Settings → Cloud Messaging |
| `INVALID_ARGUMENT` | Malformed token or payload | Re-copy the token; check for stray whitespace |
| `SENDER_ID_MISMATCH` | Token belongs to a different Firebase project | Wrong token or wrong service account |
| `OAuth2 exchange failed` | Service account rejected by Google | Key revoked or disabled — regenerate in Firebase Console |

---

## Notification didn't appear on the phone?

FCM said 200 but you saw nothing. Work down this list.

**1. Was the app in the foreground?**
This app deliberately suppresses system notifications while it is open — it shows its own
in-app banner instead (`push_notification_service.dart:360`). **Background the app before
testing.**

**2. Is it in Notification Center?**
Swipe down. If it is there, presentation worked — the banner may simply have come and
gone. On BrowserStack this is normal: **their video stream does not render the banner
overlay**, so Notification Center is the only place you will see it.

**3. Notification appeared but was silent?**
The `.wav` file is not in the app bundle. iOS logs a hard error and plays nothing — it
does **not** fall back to a default sound. Check the device log for:

```
Failed to find sound "high_alert_1.wav"
```

Confirm the sounds actually shipped in the build:

```bash
unzip -l <build.ipa> | grep -E "Payload/Runner.app/[a-z_0-9]+\.wav"
```

Seven `.wav` files must appear at **bundle root**. If they only appear under
`flutter_assets/`, they were never added to the Xcode target.

**4. Still nothing?**
Pull the device log and search for your bundle id. iOS states plainly what it decided:

```
[com.yuhblockin.v1] Delivered user visible push notification ...
[com.yuhblockin.v1] Adding notification ... [ shouldPresentAlert: 1 ]
    destinations: ( NotificationCenter, LockScreen, Alert, ... )
```

`shouldPresentAlert: 1` plus a `LockScreen`/`Alert` destination means iOS displayed it and
the problem is elsewhere. Note that Swift `print()` does **not** appear in device logs —
only `NSLog`, `os_log`, and Flutter's `debugPrint`.

---

## Testing the real path instead

This tool bypasses Supabase and talks to FCM directly, which is what makes it good for
isolating faults. To exercise the **production** path — trigger, Edge Function and all —
insert an alert instead:

```sql
insert into alerts (sender_id, receiver_id, plate_hash, message, urgency_level)
select (select id from public.users limit 1),
       (select user_id from public.device_tokens where platform='ios' limit 1),
       'diag-plate', 'End-to-end test', 'normal'
returning id;
```

Then check what the database actually sent:

```sql
select id, status_code, left(content, 300) as body, created
from net._http_response order by created desc limit 5;
```

`200` means the Edge Function ran. Its logs contain the raw FCM response.

---

## Security

- **Never commit** the service account JSON, or any `sb_secret_` / `service_role` key.
- Device tokens are semi-sensitive — useless without the service account, but keep them in
  `~/.yuhblockin_*_token` (mode `0600`) rather than in commands or chat.
- Prefer `--token-file` over `--token`; the latter lands in `.zsh_history`.
- The tool never prints a token or key in full.

---

## Deprecated tools in this directory

These predate the Supabase legacy-key removal and **no longer work**:

| File | Why it is broken |
|---|---|
| `test_ios_push.js` | Hardcodes a Windows path to a different service account |
| `test_android_push.js` | Uses a disabled legacy Supabase key |
| `query_ios_tokens.js` | Uses a disabled legacy Supabase key |

`send_test_push.py` replaces all three and covers both platforms.
