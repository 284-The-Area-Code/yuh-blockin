-- Enforce blocking silently inside every alert-send path (Apple Guideline
-- 1.2 remediation, decision: a blocked sender's future sends must not
-- reveal that a block occurred).
--
-- Two write paths reach public.alerts today:
--   1. send_alert() RPC - the normal send.
--   2. sendReminderAlert() (simple_alert_service.dart) - a raw
--      `.from('alerts').insert(...)`, confirmed via grep to be the ONLY
--      other insert call site in lib/. It bypasses send_alert() entirely,
--      so patching send_alert() alone leaves the block trivially
--      bypassable via the "remind" button.
--
-- Fix: add is_blocked(), call it from inside send_alert(), AND move
-- sendReminderAlert onto a new send_reminder_alert() RPC with the same
-- check - then drop alerts_insert_as_sender entirely, since after this
-- migration there is no remaining legitimate reason for a client to insert
-- into public.alerts directly. This also permanently closes the exact
-- direct-insert bypass the 20260911 migration flagged as a risk for quota
-- enforcement - it's now structurally impossible, not just discouraged.
--
-- Silence, precisely: on a blocked send, the caller still gets
-- {success: true, alert_id: null, recipients: 1} - identical in shape to a
-- real send. Quota is still charged for non-premium callers on the blocked
-- path too, so a sender cannot infer a block exists by noticing their daily
-- count stops moving for one specific plate while it keeps moving for
-- others.

create or replace function public.is_blocked(p_sender text, p_receiver text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1 from public.blocked_users
        where blocker_id = p_receiver and blocked_id = p_sender
    );
$$;

create or replace function public.send_alert(
    sender_user_id      text,
    target_plate_hash   text,
    alert_message       text default null::text,
    alert_sound_path    text default null::text,
    alert_urgency_level text default 'normal'::text
)
returns json
language plpgsql
security definer
set search_path = ''
as $function$
DECLARE
    v_caller     TEXT := auth.uid()::text;
    receiver_id  TEXT;
    new_alert_id UUID;
    v_perm       JSONB;
BEGIN
    IF v_caller IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Not signed in', 'recipients', 0);
    END IF;

    IF sender_user_id IS DISTINCT FROM v_caller THEN
        RETURN json_build_object('success', false, 'error', 'Session mismatch. Please restart the app.', 'recipients', 0);
    END IF;

    v_perm := public.validate_alert_permission();
    IF (v_perm->>'allowed')::boolean IS NOT TRUE THEN
        RETURN json_build_object('success', false, 'error', COALESCE(v_perm->>'reason', 'Daily alert limit reached'), 'recipients', 0);
    END IF;

    SELECT user_id INTO receiver_id FROM public.plates WHERE plate_hash = target_plate_hash LIMIT 1;

    IF receiver_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Plate not registered', 'recipients', 0);
    END IF;

    IF receiver_id = v_caller THEN
        RETURN json_build_object('success', false, 'error', 'Cannot alert your own vehicle', 'recipients', 0);
    END IF;

    -- Silent block check. Placed after the self-alert check (a self-block
    -- is impossible anyway per blocked_users_insert_own) and before the
    -- insert, so quota accounting below is identical on both branches.
    IF public.is_blocked(v_caller, receiver_id) THEN
        IF (v_perm->>'is_premium')::boolean IS NOT TRUE THEN
            PERFORM public.increment_daily_usage();
        END IF;
        RETURN json_build_object('success', true, 'alert_id', NULL, 'recipients', 1);
    END IF;

    IF alert_urgency_level NOT IN ('low', 'normal', 'high') THEN
        alert_urgency_level := 'normal';
    END IF;

    INSERT INTO public.alerts (sender_id, receiver_id, plate_hash, message, sound_path, urgency_level, created_at)
    VALUES (v_caller, receiver_id, target_plate_hash, alert_message, alert_sound_path, alert_urgency_level, NOW())
    RETURNING id INTO new_alert_id;

    IF (v_perm->>'is_premium')::boolean IS NOT TRUE THEN
        PERFORM public.increment_daily_usage();
    END IF;

    RETURN json_build_object('success', true, 'alert_id', new_alert_id, 'recipients', 1);
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM, 'recipients', 0);
END;
$function$;

-- New: send_reminder_alert() replaces sendReminderAlert()'s raw insert.
-- Deliberately does NOT call increment_daily_usage() - the original raw
-- insert never counted against quota either, and changing that now would be
-- an unrelated behavior change bundled into a security fix.
create or replace function public.send_reminder_alert(
    sender_user_id     text,
    receiver_user_id   text,
    target_plate_hash  text,
    alert_message      text default '⏰ Reminder: Still waiting'
)
returns json
language plpgsql
security definer
set search_path = ''
as $function$
DECLARE
    v_caller     TEXT := auth.uid()::text;
    new_alert_id UUID;
BEGIN
    IF v_caller IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Not signed in', 'recipients', 0);
    END IF;

    IF sender_user_id IS DISTINCT FROM v_caller THEN
        RETURN json_build_object('success', false, 'error', 'Session mismatch. Please restart the app.', 'recipients', 0);
    END IF;

    IF public.is_blocked(v_caller, receiver_user_id) THEN
        RETURN json_build_object('success', true, 'alert_id', NULL, 'recipients', 1);
    END IF;

    INSERT INTO public.alerts (sender_id, receiver_id, plate_hash, message, created_at)
    VALUES (v_caller, receiver_user_id, target_plate_hash, alert_message, NOW())
    RETURNING id INTO new_alert_id;

    RETURN json_build_object('success', true, 'alert_id', new_alert_id, 'recipients', 1);
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM, 'recipients', 0);
END;
$function$;

-- Close the direct-insert path permanently: after this migration, both
-- legitimate send paths go through a SECURITY DEFINER RPC, so no policy
-- needs to grant INSERT to public clients at all.
drop policy if exists alerts_insert_as_sender on public.alerts;

-- ---------------------------------------------------------------------------
-- ROLLBACK
-- ---------------------------------------------------------------------------
-- create policy alerts_insert_as_sender on public.alerts
--     for insert to public with check (sender_id = (auth.uid())::text);
-- drop function if exists public.send_reminder_alert(text, text, text, text);
-- -- (then re-run the 20260911 send_alert() body verbatim)
-- drop function if exists public.is_blocked(text, text);
