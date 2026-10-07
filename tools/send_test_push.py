#!/usr/bin/env python3
"""
Send a test push notification to a single device, using the EXACT payload that
supabase/functions/alerts-fcm/index.ts builds.

Authenticates directly to FCM HTTP v1 with the Firebase service account, so it does
not depend on Supabase keys and is unaffected by the legacy-key deprecation.

Requirements: python3, pyjwt  (pip install pyjwt cryptography)

Service account is located in this order:
  1. --service-account <path>
  2. $YUHBLOCKIN_SERVICE_ACCOUNT
  3. ~/Documents/lab/credentials/firebase-priv-key/*firebase-adminsdk*.json

Examples:
  tools/send_test_push.py --token-file ~/.yuhblockin_ios_token
  tools/send_test_push.py --token 'eg3N8...' --urgency high
  tools/send_test_push.py --token-file ~/.tok --platform android --urgency low
  tools/send_test_push.py --token-file ~/.tok --validate-only
  tools/send_test_push.py --token-file ~/.tok --message 'Custom test text'

Prefer --token-file: a token passed on the command line ends up in shell history.
Neither the device token nor any key material is ever printed in full.
"""
import argparse, glob, json, os, sys, time
import urllib.error, urllib.parse, urllib.request

SOUND_MAP = {"low": "low_alert_1.wav", "normal": "normal_alert.wav", "high": "high_alert_1.wav"}
DEFAULT_MESSAGE = "Someone needs you to move your car!"
# Must match the UNNotificationCategory registered in ios/Runner/AppDelegate.swift
# and the aps.category sent by supabase/functions/alerts-fcm/index.ts.
ALERT_CATEGORY = "yuh_blockin_alert"
# Not a real row in `alerts`. Tapping a notification carrying this id makes the app
# look it up, find nothing, and silently do nothing - which reads as a broken feature.
PLACEHOLDER_ALERT_ID = "manual-test-push"
TITLE = "Yuh Blockin'"


def find_service_account(explicit):
    if explicit:
        return explicit
    env = os.environ.get("YUHBLOCKIN_SERVICE_ACCOUNT")
    if env:
        return env
    pattern = os.path.expanduser(
        "~/Documents/lab/credentials/firebase-priv-key/*firebase-adminsdk*.json")
    hits = sorted(glob.glob(pattern))
    if not hits:
        sys.exit("No service account found. Use --service-account or set "
                 "$YUHBLOCKIN_SERVICE_ACCOUNT.")
    return hits[0]


def mint_access_token(sa):
    try:
        import jwt
    except ImportError:
        sys.exit("pyjwt is required:  pip install pyjwt cryptography")
    now = int(time.time())
    assertion = jwt.encode({
        "iss": sa["client_email"],
        "sub": sa["client_email"],
        "aud": "https://oauth2.googleapis.com/token",
        "iat": now,
        "exp": now + 3600,
        "scope": "https://www.googleapis.com/auth/firebase.messaging",
    }, sa["private_key"], algorithm="RS256")

    body = urllib.parse.urlencode({
        "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion": assertion,
    }).encode()
    req = urllib.request.Request(
        "https://oauth2.googleapis.com/token", data=body,
        headers={"Content-Type": "application/x-www-form-urlencoded"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return json.load(r)["access_token"]
    except urllib.error.HTTPError as e:
        sys.exit(f"OAuth2 exchange failed ({e.code}): {e.read().decode()[:300]}")


def build_message(token, platform, urgency, text, alert_id):
    """Mirrors alerts-fcm/index.ts lines ~175-219 exactly."""
    sound = SOUND_MAP.get(urgency, SOUND_MAP["normal"])
    msg = {
        "token": token,
        "notification": {"title": TITLE, "body": text},
        "data": {
            "alert_id": alert_id,
            "urgency_level": urgency,
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
        },
    }
    if platform == "ios":
        msg["apns"] = {
            "headers": {"apns-priority": "10", "apns-push-type": "alert"},
            "payload": {"aps": {
                "alert": {"title": TITLE, "body": text},
                "sound": sound,
                "badge": 1,
                # Required for the Moving Now / 5 Minutes / Can't Move buttons.
                # Must match the UNNotificationCategory registered in
                # ios/Runner/AppDelegate.swift. Without it iOS renders a plain
                # banner with no actions, no matter which build is installed.
                "category": ALERT_CATEGORY,
            }},
        }
    elif platform == "android":
        android_sound = sound.replace(".wav", "")
        msg["android"] = {
            "priority": "high",
            "notification": {
                "sound": android_sound,
                "channel_id": f"yuh_blockin_alert_{android_sound}_v2",
            },
        }
    return msg, sound


def explain(codes):
    if "UNREGISTERED" in codes:
        return ("Token is dead - app uninstalled, token rotated, or a BrowserStack\n"
                "  session ended and wiped the device. Not a credential fault.")
    if "THIRD_PARTY_AUTH_ERROR" in codes:
        return ("APNs credential rejected by Apple. Check the APNs auth key in\n"
                "  Firebase Console > Project Settings > Cloud Messaging.")
    if "INVALID_ARGUMENT" in codes:
        return "Malformed token or payload - see the response body above."
    if "SENDER_ID_MISMATCH" in codes:
        return "Token belongs to a different Firebase project."
    return None


def main():
    p = argparse.ArgumentParser(description="Send a test push via FCM HTTP v1.")
    src = p.add_mutually_exclusive_group(required=True)
    src.add_argument("--token", help="device registration token (ends up in shell history)")
    src.add_argument("--token-file", help="file containing the token (preferred)")
    p.add_argument("--platform", choices=["ios", "android"], default="ios")
    p.add_argument("--urgency", choices=["low", "normal", "high"], default="normal")
    p.add_argument("--message", default=DEFAULT_MESSAGE)
    p.add_argument("--validate-only", action="store_true",
                   help="ask FCM to validate without delivering anything")
    p.add_argument("--alert-id", default=PLACEHOLDER_ALERT_ID,
                   help="a REAL alerts.id UUID. Tapping the notification makes the app "
                        "open that alert; with the placeholder the app finds nothing and "
                        "appears to do nothing.")
    p.add_argument("--service-account", help="path to the Firebase service account JSON")
    args = p.parse_args()

    token = (open(os.path.expanduser(args.token_file)).read().strip()
             if args.token_file else args.token.strip())
    if not token:
        sys.exit("Empty token.")

    sa_path = find_service_account(args.service_account)
    sa = json.load(open(sa_path))
    project_id = sa["project_id"]

    access_token = mint_access_token(sa)
    message, sound = build_message(token, args.platform, args.urgency, args.message,
                                   args.alert_id)

    masked = f"{token[:8]}...{token[-4:]}" if len(token) > 12 else "(short)"
    print(f"  project  : {project_id}")
    print(f"  account  : {os.path.basename(sa_path)}")
    print(f"  target   : {masked}  (len {len(token)})")
    print(f"  platform : {args.platform}   urgency: {args.urgency}   sound: {sound}")
    print(f"  alert_id : {args.alert_id}")
    print(f"  mode     : {'VALIDATE ONLY - nothing delivered' if args.validate_only else 'REAL SEND'}")
    if args.alert_id == PLACEHOLDER_ALERT_ID:
        print("\n  WARNING: placeholder alert_id. The notification and its buttons will")
        print("           work, but TAPPING it will open the app to nothing, because no")
        print("           such alert exists. Pass --alert-id <real uuid> to test tap")
        print("           routing:  select id from alerts order by created_at desc limit 1;")
    print()

    payload = {"message": message}
    if args.validate_only:
        payload["validate_only"] = True

    url = f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"
    req = urllib.request.Request(url, data=json.dumps(payload).encode(), headers={
        "Authorization": f"Bearer {access_token}", "Content-Type": "application/json"})

    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            resp = json.load(r)
            print(f"  HTTP {r.status}")
            print("  response:", json.dumps(resp, indent=2))
            print("\n  RESULT: FCM accepted the message.")
            print("  message id:", resp.get("name", "(none)"))
            if not args.validate_only:
                print("  Delivery is now APNs'/FCM's responsibility - check the device.")
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        print(f"  HTTP {e.code}")
        try:
            parsed = json.loads(raw)
            print("  response:", json.dumps(parsed, indent=2))
            codes = [d.get("errorCode") for d in
                     parsed.get("error", {}).get("details", []) if d.get("errorCode")]
            print("\n  errorCode(s):", codes or "(none)")
            hint = explain(codes)
            if hint:
                print("  RESULT:", hint)
        except json.JSONDecodeError:
            print("  raw:", raw[:600])
        sys.exit(1)


if __name__ == "__main__":
    main()
