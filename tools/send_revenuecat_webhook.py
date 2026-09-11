#!/usr/bin/env python3
"""
Send a correctly-signed RevenueCat webhook to the revenuecat-webhook Edge
Function, so the entitlement sync can be exercised without a store purchase.

The dashboard's own TEST event only proves the signature check: the function
short-circuits on type == 'TEST' before it touches the RevenueCat REST API or
the database. This sends a real event type, which drives the whole path:

    HMAC verify -> GET /v2/.../active_entitlements -> upsert public.subscriptions

Signing matches supabase/functions/revenuecat-webhook/index.ts exactly:
  header  X-RevenueCat-Webhook-Signature: t=<unix_seconds>,v1=<hmac_sha256_hex>
  signed  the bytes of "<t>." followed by the RAW request body

Requirements: python3 only (no third-party packages).

The signing secret is read, in this order:
  1. --secret-file <path>
  2. $REVENUECAT_WEBHOOK_SECRET
  3. an interactive prompt (not echoed)

Never pass the secret as an argument - it would land in shell history and in
the process list. It is never printed by this script.

Examples:
  tools/send_revenuecat_webhook.py --app-user-id <supabase-user-uuid>
  tools/send_revenuecat_webhook.py --app-user-id <uuid> --event-type EXPIRATION
  tools/send_revenuecat_webhook.py --app-user-id <uuid> --skew 400   # expect 401
  tools/send_revenuecat_webhook.py --app-user-id <old> --transferred-to <new>
"""
import argparse
import getpass
import hashlib
import hmac
import json
import os
import sys
import time
import urllib.error
import urllib.request
import uuid

PROJECT_REF = 'oazxwglbvzgpehsckmfb'
DEFAULT_URL = f'https://{PROJECT_REF}.supabase.co/functions/v1/revenuecat-webhook'

# Must match PREMIUM_ENTITLEMENT in the Edge Function and the entitlement
# identifier in the RevenueCat dashboard.
ENTITLEMENT = 'premium'

GRANTING = ['INITIAL_PURCHASE', 'RENEWAL', 'UNCANCELLATION',
            'NON_RENEWING_PURCHASE', 'PRODUCT_CHANGE']
REVOKING = ['EXPIRATION', 'CANCELLATION']
OTHER = ['TRANSFER', 'BILLING_ISSUE', 'SUBSCRIPTION_PAUSED', 'TEST']


def read_secret(path):
    if path:
        with open(os.path.expanduser(path)) as fh:
            return fh.read().strip()
    env = os.environ.get('REVENUECAT_WEBHOOK_SECRET')
    if env:
        return env.strip()
    return getpass.getpass('REVENUECAT_WEBHOOK_SECRET: ').strip()


def build_event(args):
    now_ms = int(time.time() * 1000)
    event = {
        'type': args.event_type,
        'id': str(uuid.uuid4()),
        'app_id': 'harness',
        'app_user_id': args.app_user_id,
        'original_app_user_id': args.app_user_id,
        'aliases': [args.app_user_id],
        'product_id': args.product_id,
        'entitlement_ids': [ENTITLEMENT],
        'period_type': 'NORMAL',
        'purchased_at_ms': now_ms,
        'expiration_at_ms': None if args.event_type in REVOKING else now_ms + 30 * 86400 * 1000,
        'store': 'APP_STORE',
        'environment': args.environment,
        'event_timestamp_ms': now_ms,
    }
    if args.transferred_to:
        # RevenueCat sends these as arrays on TRANSFER. The function syncs both
        # sides, otherwise the losing account keeps premium.
        event['transferred_from'] = [args.app_user_id]
        event['transferred_to'] = [args.transferred_to]
    return {'api_version': '1.0', 'event': event}


def sign(body: bytes, secret: str, skew: int):
    t = str(int(time.time()) + skew)
    signed = t.encode() + b'.' + body
    digest = hmac.new(secret.encode(), signed, hashlib.sha256).hexdigest()
    return f't={t},v1={digest}'


def main():
    p = argparse.ArgumentParser(description='Send a signed RevenueCat webhook.')
    p.add_argument('--app-user-id', required=True,
                   help='the Supabase user id RevenueCat knows as app_user_id')
    p.add_argument('--event-type', default='INITIAL_PURCHASE',
                   choices=GRANTING + REVOKING + OTHER)
    p.add_argument('--product-id', default='yuh_blockin_monthly')
    p.add_argument('--environment', default='PRODUCTION', choices=['PRODUCTION', 'SANDBOX'])
    p.add_argument('--transferred-to', help='destination app_user_id, makes this a TRANSFER')
    p.add_argument('--url', default=DEFAULT_URL)
    p.add_argument('--secret-file', help='file containing the HMAC signing secret')
    p.add_argument('--skew', type=int, default=0,
                   help='seconds to offset the signature timestamp. Use >300 to '
                        'prove replay protection rejects it (expect 401).')
    p.add_argument('--tamper', action='store_true',
                   help='sign, then alter the body. Proves the signature covers '
                        'the payload (expect 401).')
    args = p.parse_args()

    secret = read_secret(args.secret_file)
    if not secret:
        sys.exit('Empty signing secret.')

    payload = build_event(args)
    body = json.dumps(payload).encode()

    header = sign(body, secret, args.skew)
    if args.tamper:
        body = json.dumps({**payload, 'tampered': True}).encode()

    print(f'  url        : {args.url}')
    print(f'  event      : {args.event_type}')
    print(f'  app_user_id: {args.app_user_id}')
    if args.transferred_to:
        print(f'  transfer to: {args.transferred_to}')
    print(f'  environment: {args.environment}')
    if args.skew:
        print(f'  skew       : {args.skew}s  (>300 should be REJECTED)')
    if args.tamper:
        print('  tamper     : body altered after signing (should be REJECTED)')
    print()

    req = urllib.request.Request(args.url, data=body, headers={
        'Content-Type': 'application/json',
        'X-RevenueCat-Webhook-Signature': header,
    })

    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            print(f'  HTTP {r.status}')
            print(f'  {r.read().decode()}')
            print('\n  ACCEPTED. Confirm the row:')
            print(f"  select * from public.subscriptions where user_id = '{args.app_user_id}';")
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        print(f'  HTTP {e.code}')
        print(f'  {raw}')
        hints = {
            401: 'Signature rejected. Expected when using --skew >300 or --tamper.\n'
                 '  Otherwise the stored REVENUECAT_WEBHOOK_SECRET does not match.',
            500: 'Missing config - check all three REVENUECAT_* secrets are set.',
            503: 'Upstream failure: the RevenueCat API call or the database write\n'
                 '  failed. Check the function logs in the Supabase dashboard.',
        }
        if e.code in hints:
            print(f'\n  {hints[e.code]}')
        sys.exit(1)


if __name__ == '__main__':
    main()
