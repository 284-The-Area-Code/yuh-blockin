// Admin tool for tester/account management: look up a user's real entitlement
// state, and delete an account outright.
//
// Deliberately does NOT grant or revoke RevenueCat promotional entitlements.
// That's a v1-only endpoint (POST /v1/subscribers/{id}/entitlements/{id}/promotional),
// and this project's secret key is a v2 key - verified directly against the
// live API: `{"code":7723,"message":"You're trying to use a secret API key
// incompatible with RevenueCat API V1."}`, HTTP 403. So plan changes are done
// by hand in the RevenueCat dashboard (Customers -> search by app_user_id);
// this function only reports status and handles deletion, both of which work
// fine against v2 / plain Supabase.
//
// Auth follows the same convention as alerts-fcm and revenuecat-webhook:
// createSupabaseContext(req, { auth: 'secret:admin_manage_user' }) checks the
// `apikey` header against a Supabase Secret API Key of that name (Dashboard ->
// API Keys -> Secret keys). Create it there before deploying this function.
import { createClient } from 'npm:@supabase/supabase-js@2.116.0';
import { createSupabaseContext } from 'npm:@supabase/server@1.6.0';

// Duplicated from revenuecat-webhook/index.ts rather than shared, so this
// function stays fully isolated from the already-verified production
// webhook - no shared module, no risk of an edit here ever touching it.
const RC_API_BASE = 'https://api.revenuecat.com/v2';
const MAX_ENTITLEMENT_PAGES = 5;
const PREMIUM_ENTITLEMENT = 'premium';

interface EntitlementState {
  status: 'free' | 'premium' | 'lifetime';
  planType: string | null;
  expiresAt: string | null;
}

const NO_ACCESS: EntitlementState = { status: 'free', planType: null, expiresAt: null };

function readSubscription(items: any[]): EntitlementState | null {
  const sub = items.find((s) =>
    s?.gives_access === true &&
    Array.isArray(s?.entitlements?.items) &&
    s.entitlements.items.some((e: any) => e?.lookup_key === PREMIUM_ENTITLEMENT)
  );
  if (!sub) return null;

  const endsRaw = sub.ends_at ?? sub.current_period_ends_at;
  if (endsRaw == null) {
    return { status: 'lifetime', planType: 'lifetime', expiresAt: null };
  }
  const endsMs = Number(endsRaw);
  if (!Number.isFinite(endsMs)) return null;
  return { status: 'premium', planType: 'monthly', expiresAt: new Date(endsMs).toISOString() };
}

function readPurchase(items: any[]): EntitlementState | null {
  const purchase = items.find((p) =>
    p?.status === 'owned' &&
    Array.isArray(p?.entitlements?.items) &&
    p.entitlements.items.some(
      (e: any) => e?.lookup_key === PREMIUM_ENTITLEMENT && e?.state === 'active',
    )
  );
  if (!purchase) return null;
  return { status: 'lifetime', planType: 'lifetime', expiresAt: null };
}

async function fetchCustomerList(
  projectId: string,
  appUserId: string,
  apiKey: string,
  resource: 'subscriptions' | 'purchases',
): Promise<any[] | null> {
  let url =
    `${RC_API_BASE}/projects/${encodeURIComponent(projectId)}` +
    `/customers/${encodeURIComponent(appUserId)}/${resource}`;

  const items: any[] = [];
  for (let page = 0; page < MAX_ENTITLEMENT_PAGES; page++) {
    const res = await fetch(url, { headers: { Authorization: `Bearer ${apiKey}` } });
    if (res.status === 404) return null;
    if (!res.ok) throw new Error(`${resource} fetch failed with HTTP ${res.status}`);

    const body = await res.json();
    if (Array.isArray(body?.items)) items.push(...body.items);
    if (!body?.next_page) return items;
    url = body.next_page.startsWith('http')
      ? body.next_page
      : `https://api.revenuecat.com${body.next_page}`;
  }
  return items;
}

async function resolveLiveEntitlement(
  projectId: string,
  appUserId: string,
  apiKey: string,
): Promise<EntitlementState | 'not_found'> {
  const subs = await fetchCustomerList(projectId, appUserId, apiKey, 'subscriptions');
  if (subs === null) return 'not_found';

  const fromSubs = readSubscription(subs);
  if (fromSubs) return fromSubs;

  const purchases = await fetchCustomerList(projectId, appUserId, apiKey, 'purchases');
  if (purchases === null) return NO_ACCESS;

  return readPurchase(purchases) ?? NO_ACCESS;
}

// This function is only ever meant to be called with a valid `apikey` secret
// (checked below), so an open CORS origin does not widen what an unauthenticated
// caller can do - it only lets a browser page read the response instead of
// blocking it client-side. Needed because the admin web page calls this via
// fetch(), unlike the curl-based testing done so far, which never enforces CORS.
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'apikey, Content-Type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'method not allowed' }, 405);
  }

  const { data: ctx, error: authError } = await createSupabaseContext(req, {
    auth: 'secret:admin_manage_user',
  });
  if (authError) {
    console.warn('admin-manage-user: rejected unauthorized caller');
    return jsonResponse({ error: 'forbidden' }, 403);
  }
  const supabase = ctx.supabaseAdmin;

  let body: Record<string, any>;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'invalid JSON body' }, 400);
  }

  const action = body?.action;
  const VALID_ACTIONS = ['view', 'delete', 'list_reports', 'update_report'];
  if (!VALID_ACTIONS.includes(action)) {
    return jsonResponse({ error: `action must be one of: ${VALID_ACTIONS.join(', ')}` }, 400);
  }

  // Only view/delete act on a specific user and need app_user_id.
  // list_reports/update_report act on the reports queue instead.
  let appUserId: string | undefined;
  if (action === 'view' || action === 'delete') {
    appUserId = body?.app_user_id;
    if (typeof appUserId !== 'string' || appUserId.trim().length === 0) {
      return jsonResponse({ error: 'app_user_id is required' }, 400);
    }
  }

  if (action === 'list_reports') {
    const status = typeof body?.status === 'string' ? body.status : 'open';
    const { data: reports, error } = await supabase
      .from('reports')
      .select('*')
      .eq('status', status)
      .order('created_at', { ascending: false });

    if (error) {
      console.error(`admin-manage-user: list_reports failed: ${error.message}`);
      return jsonResponse({ error: 'failed to list reports' }, 500);
    }

    const alertIds = (reports ?? [])
      .map((r) => r.alert_id)
      .filter((id): id is string => typeof id === 'string');

    let alertsById: Record<string, any> = {};
    if (alertIds.length > 0) {
      const { data: alerts } = await supabase
        .from('alerts')
        .select('id, message, urgency_level, created_at, hidden_by_receiver')
        .in('id', alertIds);
      alertsById = Object.fromEntries((alerts ?? []).map((a) => [a.id, a]));
    }

    const enriched = (reports ?? []).map((r) => ({
      ...r,
      alert: r.alert_id ? (alertsById[r.alert_id] ?? null) : null,
    }));

    return jsonResponse({ status, reports: enriched });
  }

  if (action === 'update_report') {
    const reportId = body?.report_id;
    const status = body?.status;
    const VALID_STATUSES = ['open', 'reviewed', 'actioned', 'dismissed'];
    if (typeof reportId !== 'string' || reportId.trim().length === 0) {
      return jsonResponse({ error: 'report_id is required' }, 400);
    }
    if (!VALID_STATUSES.includes(status)) {
      return jsonResponse({ error: `status must be one of: ${VALID_STATUSES.join(', ')}` }, 400);
    }

    const { error } = await supabase
      .from('reports')
      .update({
        status,
        reviewed_at: new Date().toISOString(),
        resolution_note: typeof body?.resolution_note === 'string' ? body.resolution_note : null,
      })
      .eq('id', reportId);

    if (error) {
      console.error(`admin-manage-user: update_report failed: ${error.message}`);
      return jsonResponse({ error: 'failed to update report' }, 500);
    }

    return jsonResponse({ ok: true, report_id: reportId, status });
  }

  // Reaching here means action is 'view' or 'delete' (list_reports/update_report
  // already returned above), and appUserId was validated as a non-empty string
  // earlier - this guard just gives TypeScript's control-flow analysis that fact.
  if (!appUserId) {
    return jsonResponse({ error: 'internal: app_user_id missing' }, 500);
  }

  if (action === 'view') {
    const [usersRes, subsRes, platesRes, usageRes, tokensRes] = await Promise.all([
      supabase.from('users').select('id, created_at').eq('id', appUserId).maybeSingle(),
      supabase.from('subscriptions').select('*').eq('user_id', appUserId).maybeSingle(),
      supabase
        .from('plates')
        .select('id, plate_hash, verification_status, created_at, verified_at')
        .eq('user_id', appUserId),
      supabase.from('daily_usage').select('*').eq('user_id', appUserId).maybeSingle(),
      supabase.from('device_tokens').select('id, platform, created_at, updated_at').eq('user_id', appUserId),
    ]);

    const rcApiKey = Deno.env.get('REVENUECAT_API_KEY');
    const rcProjectId = Deno.env.get('REVENUECAT_PROJECT_ID');
    let revenueCatLive: EntitlementState | 'not_found' | 'unavailable' = 'unavailable';
    if (rcApiKey && rcProjectId) {
      try {
        revenueCatLive = await resolveLiveEntitlement(rcProjectId, appUserId, rcApiKey);
      } catch (e) {
        console.error(`admin-manage-user: RevenueCat lookup failed: ${e instanceof Error ? e.message : e}`);
        revenueCatLive = 'unavailable';
      }
    }

    return jsonResponse({
      app_user_id: appUserId,
      user: usersRes.data ?? null,
      subscription: subsRes.data ?? null,
      revenuecat_live: revenueCatLive,
      plates: platesRes.data ?? [],
      daily_usage: usageRes.data ?? null,
      device_tokens: tokensRes.data ?? [],
      note:
        'To change this user\'s plan, use the RevenueCat dashboard (Customers -> ' +
        'search by app_user_id) - this project\'s API key cannot call the v1 ' +
        'promotional-entitlement endpoint (see comment at top of this file).',
    });
  }

  // action === 'delete'
  if (body?.confirm !== true) {
    return jsonResponse({ error: 'delete requires confirm: true in the request body' }, 400);
  }

  const deleted: Record<string, boolean> = {};

  for (const [table, column] of [
    ['device_tokens', 'user_id'],
    ['plates', 'user_id'],
    ['daily_usage', 'user_id'],
    ['subscriptions', 'user_id'],
    ['users', 'id'],
  ] as const) {
    const { error } = await supabase.from(table).delete().eq(column, appUserId);
    if (error) {
      console.error(`admin-manage-user: failed deleting from ${table}: ${error.message}`);
      return jsonResponse({ error: `failed deleting from ${table}`, deleted }, 500);
    }
    deleted[table] = true;
  }

  // auth.users deletion needs the full admin auth API, which the
  // createSupabaseContext client is not guaranteed to expose - built
  // separately with the service-role key rather than assumed.
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceRoleKey) {
    console.error('admin-manage-user: missing SUPABASE_URL/SUPABASE_SERVICE_ROLE_KEY for auth deletion');
    return jsonResponse(
      { error: 'app data deleted, but auth user deletion is not configured', deleted },
      500,
    );
  }
  const adminAuthClient = createClient(supabaseUrl, serviceRoleKey);
  const { error: authDeleteError } = await adminAuthClient.auth.admin.deleteUser(appUserId);
  if (authDeleteError) {
    console.error(`admin-manage-user: failed deleting auth user: ${authDeleteError.message}`);
    return jsonResponse(
      { error: 'app data deleted, but auth user deletion failed', message: authDeleteError.message, deleted },
      500,
    );
  }
  deleted['auth_user'] = true;

  console.log(`admin-manage-user: deleted account ${appUserId}`);
  return jsonResponse({ ok: true, app_user_id: appUserId, deleted });
});
