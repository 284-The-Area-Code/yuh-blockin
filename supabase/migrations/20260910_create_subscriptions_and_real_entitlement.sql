-- Make premium real, and remove the always-allow stubs.
--
-- Written against the DEPLOYED functions, not the migration files in this
-- repo. The two differ: the live validate_alert_permission() was hand-written
-- in the SQL editor, uses a limit of 2, and hardcodes
--   v_is_premium BOOLEAN := FALSE; -- set to TRUE later when you add subscriptions
-- so the premium branch has always been unreachable. public.subscriptions
-- never existed.
--
-- SCOPE: this script does NOT change public.send_alert. That function is the
-- live alert path and enforces no quota at all; hardening it requires a
-- coordinated Dart change (see the note at the bottom) and is deliberately a
-- separate step.

-- ---------------------------------------------------------------------------
-- 1. The entitlement table. Written only by the RevenueCat webhook.
-- ---------------------------------------------------------------------------
create table if not exists public.subscriptions (
    user_id    text primary key references public.users(id) on delete cascade,
    status     text not null default 'free',
    plan_type  text,
    started_at timestamptz default now(),
    expires_at timestamptz,               -- null = lifetime
    is_demo    boolean default false,
    source     text default 'revenuecat',
    updated_at timestamptz default now(),
    constraint subscriptions_status_check
        check (status in ('free', 'premium', 'lifetime', 'expired'))
);

alter table public.subscriptions enable row level security;

-- Read-only to the owner. There is deliberately NO insert/update/delete policy:
-- the only writer is the revenuecat-webhook Edge Function, which uses a secret
-- key and bypasses RLS. A client that can write its own status can grant itself
-- premium.
drop policy if exists subscriptions_select_own on public.subscriptions;
create policy subscriptions_select_own on public.subscriptions
    for select to authenticated
    using ((auth.uid())::text = user_id);

create index if not exists idx_subscriptions_status on public.subscriptions(status);

-- ---------------------------------------------------------------------------
-- 2. Real entitlement check.
--
-- Changes from the deployed version:
--   - v_is_premium is now read from public.subscriptions instead of being a
--     hardcoded FALSE, so the premium branch is finally reachable.
--   - SECURITY DEFINER, so the function can read subscriptions regardless of
--     the caller's RLS.
--   - SET search_path = '' - required now that it is SECURITY DEFINER, so a
--     caller cannot shadow an unqualified name. All references are qualified.
--   - Rejects a NULL auth.uid(). Previously an unauthenticated caller matched
--     no daily_usage row, read usage as 0, and was granted an alert.
--
-- v_limit is set to 1, down from the deployed 2. This is a deliberate product
-- change, and it makes the server agree with PaymentConfig.freeDailyAlertLimit
-- = 1 in the app, which was already blocking at 1 first - so the effective
-- limit users experience does not change.
-- ---------------------------------------------------------------------------
create or replace function public.validate_alert_permission()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id       text := auth.uid()::text;
    v_is_premium    boolean := false;
    v_alerts_sent   integer := 0;
    v_last_alert_at timestamptz;
    v_limit         integer := 1;
begin
    if v_user_id is null then
        return jsonb_build_object(
            'allowed', false, 'is_premium', false, 'remaining', 0,
            'reason', 'Not signed in');
    end if;

    select exists (
        select 1 from public.subscriptions
        where user_id = v_user_id
          and status in ('premium', 'lifetime')
          and (expires_at is null or expires_at > now())
    ) into v_is_premium;

    if v_is_premium then
        return jsonb_build_object(
            'allowed', true, 'is_premium', true, 'remaining', 999, 'reason', null);
    end if;

    select alerts_sent, last_alert_at
      into v_alerts_sent, v_last_alert_at
      from public.daily_usage
     where user_id = v_user_id;

    if v_last_alert_at is null or v_last_alert_at::date < now()::date then
        v_alerts_sent := 0;
    end if;

    if v_alerts_sent < v_limit then
        return jsonb_build_object(
            'allowed', true, 'is_premium', false,
            'remaining', v_limit - v_alerts_sent, 'reason', null);
    end if;

    return jsonb_build_object(
        'allowed', false, 'is_premium', false, 'remaining', 0,
        'reason', 'Daily limit of ' || v_limit ||
                  ' alerts reached. Upgrade to Premium for unlimited access!');
end;
$$;

-- ---------------------------------------------------------------------------
-- 3. Usage increment: SECURITY DEFINER + search_path + NULL guard.
--    Becoming SECURITY DEFINER is what lets step 4 revoke direct client writes.
-- ---------------------------------------------------------------------------
create or replace function public.increment_daily_usage()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id text := auth.uid()::text;
begin
    if v_user_id is null then
        return;
    end if;

    insert into public.daily_usage (user_id, alerts_sent, last_alert_at, updated_at)
    values (v_user_id, 1, now(), now())
    on conflict (user_id) do update set
        alerts_sent = case
            when public.daily_usage.last_alert_at::date < now()::date then 1
            else public.daily_usage.alerts_sent + 1
        end,
        last_alert_at = now(),
        updated_at    = now();
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. Close the self-reset bypass.
--
-- daily_usage_update_own let any user run
--   update daily_usage set alerts_sent = 0
-- on their own row and clear their quota. Writes now go exclusively through
-- increment_daily_usage(), which is SECURITY DEFINER. Reads stay open so the
-- app can still show remaining alerts.
-- ---------------------------------------------------------------------------
drop policy if exists daily_usage_update_own on public.daily_usage;
drop policy if exists daily_usage_insert_own on public.daily_usage;
drop policy if exists "Users can manage their own usage" on public.daily_usage;

-- ---------------------------------------------------------------------------
-- 5. Remove the always-allow stubs.
--
--   validate_alert_permission(text, text) -> jsonb_build_object('allowed', true)
--   validate_alert_permission(text)       -> true   (SECURITY DEFINER)
--
-- Both returned "allowed" unconditionally and were reachable over PostgREST.
-- Neither is called by send_alert or by the app, which uses the 0-arg form.
-- Dropped last so nothing breaks mid-script.
-- ---------------------------------------------------------------------------
drop function if exists public.validate_alert_permission(text, text);
drop function if exists public.validate_alert_permission(text);

-- ---------------------------------------------------------------------------
-- STILL OPEN after this script - public.send_alert
--
-- send_alert is SECURITY DEFINER, takes sender_user_id as a parameter rather
-- than using auth.uid(), and never calls validate_alert_permission. So the
-- daily limit remains enforceable only by the Dart client, and the sender can
-- be spoofed. Fixing it means, in one coordinated change:
--   a) derive the sender from auth.uid() and ignore the passed parameter,
--   b) call validate_alert_permission() and refuse when not allowed,
--   c) call increment_daily_usage() inside send_alert, AND remove the separate
--      client-side call at lib/main.dart:3625 and
--      lib/features/premium_alert/alert_workflow_screen.dart:1160, or usage
--      will be double counted.
-- ---------------------------------------------------------------------------
