// RevenueCat -> Supabase entitlement sync.
//
// This is the ONLY writer of public.subscriptions. The app deliberately does
// not write entitlement state (a client that can set its own status can grant
// itself premium), so until this function runs, no user is premium server-side.
//
// Design note - why this does not trust the webhook body:
// RevenueCat event types do not map cleanly onto "grant" and "revoke".
// CANCELLATION means auto-renew was turned off, not that access ended.
// BILLING_ISSUE explicitly "doesn't mean the subscription has expired".
// SUBSCRIPTION_PAUSED is documented as "Don't revoke access on this event."
// There is also no documented ordering guarantee between deliveries. So the
// event is used only as a trigger: after verifying it, we re-read the
// customer's canonical state from the RevenueCat REST API and mirror that.
// This is RevenueCat's own recommendation for webhook consumers.

// NOTE: createClient is not called here. The import pins the version of
// @supabase/supabase-js that the bundler resolves: @supabase/server has a
// non-optional peer dependency on it and imports its `./cors` subpath.
// Pinning 2.28.0 previously caused ERR_MODULE_NOT_FOUND -> BOOT_ERROR in
// alerts-fcm because that version predates subpath exports. Keep in step with
// supabase/functions/alerts-fcm/index.ts.
import { createClient } from 'npm:@supabase/supabase-js@2.116.0';
import { createSupabaseContext } from 'npm:@supabase/server@1.6.0';

// v2, not v1. Secret API keys issued by the dashboard are V2 keys and are
// rejected with HTTP 403 by v1 endpoints - verified against this project's key.
const RC_API_BASE = 'https://api.revenuecat.com/v2';

// Guard against a malformed next_page loop.
const MAX_ENTITLEMENT_PAGES = 5;

// Must match the entitlement identifier in the RevenueCat dashboard and
// PaymentConfig.premiumEntitlement in the app.
const PREMIUM_ENTITLEMENT = 'premium';

const SIGNATURE_HEADER = 'x-revenuecat-webhook-signature';

// Reject signatures whose timestamp is further than this from now, so a
// captured request cannot be replayed later. RevenueCat recomputes `t` and
// `v1` on every delivery attempt including retries, so retries are unaffected.
const TOLERANCE_SECONDS = 300;

// RevenueCat assigns these to customers who purchased before logging in. They
// are not Supabase user ids and have no row in public.users.
const ANONYMOUS_ID_PREFIX = '$RCAnonymousID:';

const encoder = new TextEncoder();

/** Hex-encode without allocating a string per byte pair. */
function toHex(buffer: ArrayBuffer): string {
  return Array.from(new Uint8Array(buffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

/** Length-independent, value-constant-time string comparison. */
function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

/**
 * Verify the `X-RevenueCat-Webhook-Signature` header.
 *
 * Header format: `t=<unix_seconds>,v1=<hmac_sha256_hex>`
 * Signed material: the bytes of `<t>.` followed by the RAW request body,
 * exactly as received and before any JSON parsing.
 */
async function verifySignature(
  rawBody: Uint8Array,
  header: string | null,
  secret: string,
): Promise<boolean> {
  if (!header) return false;

  let timestamp: string | undefined;
  let provided: string | undefined;
  for (const part of header.split(',')) {
    const eq = part.indexOf('=');
    if (eq === -1) continue;
    const key = part.slice(0, eq).trim();
    const value = part.slice(eq + 1).trim();
    if (key === 't') timestamp = value;
    else if (key === 'v1') provided = value;
  }
  if (!timestamp || !provided) return false;

  const sent = Number(timestamp);
  if (!Number.isFinite(sent)) return false;
  const skew = Math.abs(Math.floor(Date.now() / 1000) - sent);
  if (skew > TOLERANCE_SECONDS) {
    console.warn(`revenuecat-webhook: signature timestamp skew ${skew}s exceeds tolerance`);
    return false;
  }

  const prefix = encoder.encode(`${timestamp}.`);
  const signed = new Uint8Array(prefix.length + rawBody.length);
  signed.set(prefix, 0);
  signed.set(rawBody, prefix.length);

  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const computed = toHex(await crypto.subtle.sign('HMAC', key, signed));

  return timingSafeEqual(computed, provided.toLowerCase());
}

interface EntitlementState {
  status: 'free' | 'premium' | 'lifetime';
  planType: string | null;
  expiresAt: string | null;
}

/**
 * Reduce the v2 active_entitlements list to the row we store.
 *
 * Each item is `{ object: 'customer.active_entitlement', entitlement_id,
 * expires_at }` where `expires_at` is epoch MILLISECONDS or null. RevenueCat
 * has already applied the "is it active right now" filter, so presence in
 * `items` means active and `expires_at: null` means lifetime - NOT expired.
 * A naive `expires_at < Date.now()` would coerce null to 0 and revoke every
 * lifetime purchase, so the null case is handled first and explicitly.
 *
 * IMPORTANT: this endpoint does not report SANDBOX purchases. Verified against
 * a live sandbox subscription that was active with gives_access true - the
 * customer's active_entitlements came back as an empty list while
 * /subscriptions showed it correctly. So an empty result here is NOT proof of
 * "no access"; readSubscription() below is consulted before concluding 'free'.
 */
function readEntitlement(items: any[]): EntitlementState | null {
  const ent = items.find((e) => e?.entitlement_id === PREMIUM_ENTITLEMENT);
  if (!ent) return null;

  if (ent.expires_at == null) {
    return { status: 'lifetime', planType: 'lifetime', expiresAt: null };
  }

  const expiresMs = Number(ent.expires_at);
  if (!Number.isFinite(expiresMs) || expiresMs <= Date.now()) {
    // Defensive: RevenueCat should not list an expired entitlement as active.
    return null;
  }

  return {
    status: 'premium',
    planType: 'monthly',
    expiresAt: new Date(expiresMs).toISOString(),
  };
}

/**
 * Derive entitlement from the v2 /subscriptions list.
 *
 * This is the path that works for sandbox. Each item carries `gives_access`,
 * which is RevenueCat's own authoritative "does this grant access right now"
 * flag, plus a nested `entitlements.items[].lookup_key`. An expired
 * subscription comes back with gives_access false and an empty entitlements
 * list, so filtering on gives_access alone is sufficient - but the lookup_key
 * is still checked so a future non-premium product cannot grant premium.
 *
 * `ends_at` and `current_period_ends_at` are epoch MILLISECONDS.
 */
function readSubscription(items: any[]): EntitlementState | null {
  const sub = items.find((s) =>
    s?.gives_access === true &&
    Array.isArray(s?.entitlements?.items) &&
    s.entitlements.items.some((e: any) => e?.lookup_key === PREMIUM_ENTITLEMENT)
  );
  if (!sub) return null;

  const endsRaw = sub.ends_at ?? sub.current_period_ends_at;
  if (endsRaw == null) {
    // Non-expiring access granted through a subscription record.
    return { status: 'lifetime', planType: 'lifetime', expiresAt: null };
  }

  const endsMs = Number(endsRaw);
  if (!Number.isFinite(endsMs)) return null;

  return {
    status: 'premium',
    planType: 'monthly',
    expiresAt: new Date(endsMs).toISOString(),
  };
}

const NO_ACCESS: EntitlementState = { status: 'free', planType: null, expiresAt: null };

/**
 * Fetch one paginated customer sub-resource, following next_page.
 * `resource` is 'active_entitlements' or 'subscriptions'.
 *
 * Returns null when RevenueCat does not know this customer (HTTP 404).
 * Throws on a transient upstream failure so the caller can ask for a redelivery.
 */
async function fetchCustomerList(
  projectId: string,
  appUserId: string,
  apiKey: string,
  resource: 'active_entitlements' | 'subscriptions',
): Promise<any[] | null> {
  let url =
    `${RC_API_BASE}/projects/${encodeURIComponent(projectId)}` +
    `/customers/${encodeURIComponent(appUserId)}/${resource}`;

  const items: any[] = [];

  for (let page = 0; page < MAX_ENTITLEMENT_PAGES; page++) {
    const res = await fetch(url, { headers: { Authorization: `Bearer ${apiKey}` } });

    if (res.status === 404) return null;
    if (!res.ok) {
      // Never log the body: it describes the customer and may echo headers.
      throw new Error(`${resource} fetch failed with HTTP ${res.status}`);
    }

    const body = await res.json();
    if (Array.isArray(body?.items)) items.push(...body.items);

    if (!body?.next_page) return items;
    // next_page is returned as a path or absolute URL depending on endpoint.
    url = body.next_page.startsWith('http')
      ? body.next_page
      : `https://api.revenuecat.com${body.next_page}`;
  }

  console.warn(`revenuecat-webhook: hit the ${resource} page cap, using what was read`);
  return items;
}

/**
 * Resolve a customer's entitlement from RevenueCat, reading both routes.
 *
 * active_entitlements is authoritative for production and for non-subscription
 * (lifetime) grants. It does NOT report sandbox purchases, so /subscriptions is
 * consulted before concluding the customer has no access. Only if both say no
 * do we write 'free' - which is still the correct revocation path, because an
 * expired subscription reports gives_access false.
 */
async function resolveEntitlement(
  projectId: string,
  appUserId: string,
  apiKey: string,
): Promise<EntitlementState | null> {
  const ents = await fetchCustomerList(projectId, appUserId, apiKey, 'active_entitlements');
  if (ents === null) return null; // unknown customer

  const fromEntitlements = readEntitlement(ents);
  if (fromEntitlements) return fromEntitlements;

  const subs = await fetchCustomerList(projectId, appUserId, apiKey, 'subscriptions');
  if (subs === null) return NO_ACCESS;

  return readSubscription(subs) ?? NO_ACCESS;
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'method not allowed' }), { status: 405 });
  }

  const signingSecret = Deno.env.get('REVENUECAT_WEBHOOK_SECRET');
  const rcApiKey = Deno.env.get('REVENUECAT_API_KEY');
  const rcProjectId = Deno.env.get('REVENUECAT_PROJECT_ID');
  if (!signingSecret || !rcApiKey || !rcProjectId) {
    // 5xx so RevenueCat retries once the secrets are set.
    console.error(
      'revenuecat-webhook: missing config',
      `[signing=${!!signingSecret}, api=${!!rcApiKey}, project=${!!rcProjectId}]`,
    );
    return new Response(JSON.stringify({ error: 'not configured' }), { status: 500 });
  }

  try {
    // Read the body as bytes BEFORE parsing. The signature covers the exact
    // bytes RevenueCat sent; re-serialising parsed JSON would not reproduce them.
    const rawBody = new Uint8Array(await req.arrayBuffer());

    const ok = await verifySignature(rawBody, req.headers.get(SIGNATURE_HEADER), signingSecret);
    if (!ok) {
      // Deliberately opaque: do not disclose which check failed.
      console.warn('revenuecat-webhook: rejected unverified request');
      return new Response(JSON.stringify({ error: 'unauthorized' }), { status: 401 });
    }

    let payload: Record<string, any>;
    try {
      payload = JSON.parse(new TextDecoder().decode(rawBody));
    } catch {
      // Verified as coming from RevenueCat but unparseable. Retrying will not
      // help, so 200 to stop the retry schedule.
      console.error('revenuecat-webhook: verified request had an unparseable body');
      return new Response(JSON.stringify({ ok: true, ignored: 'unparseable' }), { status: 200 });
    }

    const event = payload?.event ?? {};
    const eventType: string = event.type ?? 'UNKNOWN';

    if (eventType === 'TEST') {
      console.log('revenuecat-webhook: TEST event verified, signature is correct');
      return new Response(JSON.stringify({ ok: true, test: true }), { status: 200 });
    }

    // Every id touched by this event. TRANSFER moves entitlements between
    // customers, so both sides must be re-synced or the loser keeps premium.
    const candidates = new Set<string>();
    for (const id of [
      event.app_user_id,
      ...(Array.isArray(event.transferred_from) ? event.transferred_from : []),
      ...(Array.isArray(event.transferred_to) ? event.transferred_to : []),
    ]) {
      if (typeof id === 'string' && id.length > 0 && !id.startsWith(ANONYMOUS_ID_PREFIX)) {
        candidates.add(id);
      }
    }

    console.log(
      `revenuecat-webhook: ${eventType} (event ${event.id ?? 'n/a'}, ` +
        `env ${event.environment ?? 'n/a'}) -> ${candidates.size} user(s)`,
    );

    if (candidates.size === 0) {
      return new Response(JSON.stringify({ ok: true, synced: 0 }), { status: 200 });
    }

    // auth: 'none' - the caller is RevenueCat, which cannot present a Supabase
    // credential. This endpoint is NOT open: every request is authenticated by
    // the HMAC check above, which also gives replay protection that a static
    // bearer token would not. supabaseAdmin is still available in this mode and
    // bypasses RLS, which is required because public.subscriptions grants
    // writes to service_role only.
    const { data: ctx, error: ctxError } = await createSupabaseContext(req, { auth: 'none' });
    if (ctxError || !ctx) {
      console.error('revenuecat-webhook: failed to build Supabase context');
      return new Response(JSON.stringify({ error: 'context unavailable' }), { status: 500 });
    }
    const supabase = ctx.supabaseAdmin;

    let synced = 0;
    const skipped: string[] = [];

    for (const appUserId of candidates) {
      let state: EntitlementState | null;
      try {
        state = await resolveEntitlement(rcProjectId, appUserId, rcApiKey);
      } catch (e) {
        // Transient upstream failure - 503 so RevenueCat redelivers rather than
        // leaving the row stale.
        console.error(`revenuecat-webhook: ${e instanceof Error ? e.message : e}`);
        return new Response(JSON.stringify({ error: 'upstream unavailable' }), { status: 503 });
      }

      if (state === null) {
        // Unknown to RevenueCat (commonly a dashboard test id). Nothing to mirror.
        skipped.push('not_found');
        continue;
      }

      // started_at is deliberately omitted: the v2 active_entitlements payload
      // carries no purchase date, and PostgREST's merge-duplicates upsert only
      // touches columns present in the body, so an existing value survives.
      const { error: upsertError } = await supabase.from('subscriptions').upsert({
        user_id: appUserId,
        status: state.status,
        plan_type: state.planType,
        expires_at: state.expiresAt,
        is_demo: false,
        source: 'revenuecat',
        updated_at: new Date().toISOString(),
      });

      if (upsertError) {
        // 23503 = foreign key violation: this app_user_id has no row in
        // public.users. Real cause is usually a purchase made before the
        // account row existed. Retrying cannot fix it, so skip and keep going.
        if (upsertError.code === '23503') {
          console.warn('revenuecat-webhook: no matching public.users row, skipping');
          skipped.push('unknown_user');
          continue;
        }
        console.error(`revenuecat-webhook: upsert failed [${upsertError.code}]`);
        return new Response(JSON.stringify({ error: 'write failed' }), { status: 503 });
      }

      synced++;
      console.log(`revenuecat-webhook: synced status=${state.status} plan=${state.planType}`);
    }

    return new Response(
      JSON.stringify({ ok: true, event: eventType, synced, skipped }),
      { status: 200 },
    );
  } catch (err) {
    console.error('revenuecat-webhook: unhandled error:', err instanceof Error ? err.message : err);
    return new Response(JSON.stringify({ error: 'internal error' }), { status: 500 });
  }
});
