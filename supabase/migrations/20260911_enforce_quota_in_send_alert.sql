-- Enforce identity and quota inside public.send_alert.
--
-- The deployed send_alert is SECURITY DEFINER, takes sender_user_id as a
-- PARAMETER rather than deriving it, and never calls validate_alert_permission.
-- Two consequences, both reachable with a single POST to
-- /rest/v1/rpc/send_alert:
--   1. Unlimited alerts. The daily limit lived only in the Dart client.
--   2. Sender spoofing. Any alert could be attributed to any user id.
--
-- Since the paid tier IS "unlimited alerts", the paid feature was already free
-- to anyone bypassing the app.
--
-- IDENTITY: this does NOT silently switch the sender to auth.uid(). Two of the
-- four Dart call sites pass a SharedPreferences-cached 'user_id' rather than
-- the live session id, and those can drift apart if the auth session is ever
-- recreated. Silently swapping would attribute alerts to an id the app's own
-- history queries do not use, making sent alerts disappear from Activity.
-- Instead the passed id must EQUAL auth.uid(); a mismatch is refused loudly.
-- For a correctly functioning client the inserted sender_id is unchanged.
--
-- ROLLBACK: see the bottom of this file.

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
    -- 1. Identity. Must be signed in.
    IF v_caller IS NULL THEN
        RETURN json_build_object(
            'success', false, 'error', 'Not signed in', 'recipients', 0);
    END IF;

    -- 2. The caller may only send as themselves. Closes sender spoofing.
    --    A mismatch here means the client's cached user_id has drifted from the
    --    auth session; surfacing it beats writing an alert nobody can see.
    IF sender_user_id IS DISTINCT FROM v_caller THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Session mismatch. Please restart the app.',
            'recipients', 0);
    END IF;

    -- 3. Quota. Same function the app calls, so client and server agree.
    v_perm := public.validate_alert_permission();
    IF (v_perm->>'allowed')::boolean IS NOT TRUE THEN
        RETURN json_build_object(
            'success', false,
            'error', COALESCE(v_perm->>'reason', 'Daily alert limit reached'),
            'recipients', 0);
    END IF;

    -- 4. Original logic below, unchanged except for schema qualification
    --    (required by SET search_path = '') and using v_caller as the sender.
    SELECT user_id INTO receiver_id
    FROM public.plates
    WHERE plate_hash = target_plate_hash
    LIMIT 1;

    IF receiver_id IS NULL THEN
        RETURN json_build_object(
            'success', false, 'error', 'Plate not registered', 'recipients', 0);
    END IF;

    IF receiver_id = v_caller THEN
        RETURN json_build_object(
            'success', false, 'error', 'Cannot alert your own vehicle', 'recipients', 0);
    END IF;

    IF alert_urgency_level NOT IN ('low', 'normal', 'high') THEN
        alert_urgency_level := 'normal';
    END IF;

    INSERT INTO public.alerts (
        sender_id, receiver_id, plate_hash,
        message, sound_path, urgency_level, created_at
    ) VALUES (
        v_caller, receiver_id, target_plate_hash,
        alert_message, alert_sound_path, alert_urgency_level, NOW()
    )
    RETURNING id INTO new_alert_id;

    -- 5. Count the usage server-side, only after the insert succeeded, and
    --    only for non-premium callers. This is what actually enforces the
    --    limit: previously the client reported its own usage, so a caller that
    --    simply never reported stayed at zero forever.
    --
    --    The Dart-side SubscriptionService.incrementDailyUsage() must no longer
    --    call the RPC or usage is counted twice. It is now local-only.
    IF (v_perm->>'is_premium')::boolean IS NOT TRUE THEN
        PERFORM public.increment_daily_usage();
    END IF;

    RETURN json_build_object(
        'success', true, 'alert_id', new_alert_id, 'recipients', 1);

EXCEPTION WHEN OTHERS THEN
    -- Preserved from the original. Note it returns SQLERRM to the client,
    -- which leaks internal error text; left as-is to keep this change to one
    -- concern, but worth tightening separately.
    RETURN json_build_object(
        'success', false, 'error', SQLERRM, 'recipients', 0);
END;
$function$;

-- ---------------------------------------------------------------------------
-- ROLLBACK - restores the exact function that was deployed before this script.
-- Run this alone if alert sending regresses.
-- ---------------------------------------------------------------------------
-- CREATE OR REPLACE FUNCTION public.send_alert(sender_user_id text, target_plate_hash text, alert_message text DEFAULT NULL::text, alert_sound_path text DEFAULT NULL::text, alert_urgency_level text DEFAULT 'normal'::text)
--  RETURNS json
--  LANGUAGE plpgsql
--  SECURITY DEFINER
-- AS $function$
-- DECLARE
--     receiver_id TEXT;
--     new_alert_id UUID;
--     recipients_count INTEGER := 0;
-- BEGIN
--     SELECT user_id INTO receiver_id
--     FROM plates
--     WHERE plate_hash = target_plate_hash
--     LIMIT 1;
--     IF receiver_id IS NULL THEN
--         RETURN json_build_object('success', false, 'error', 'Plate not registered', 'recipients', 0);
--     END IF;
--     IF receiver_id = sender_user_id THEN
--         RETURN json_build_object('success', false, 'error', 'Cannot alert your own vehicle', 'recipients', 0);
--     END IF;
--     IF alert_urgency_level NOT IN ('low', 'normal', 'high') THEN
--         alert_urgency_level := 'normal';
--     END IF;
--     INSERT INTO alerts (sender_id, receiver_id, plate_hash, message, sound_path, urgency_level, created_at)
--     VALUES (sender_user_id, receiver_id, target_plate_hash, alert_message, alert_sound_path, alert_urgency_level, NOW())
--     RETURNING id INTO new_alert_id;
--     recipients_count := 1;
--     RETURN json_build_object('success', true, 'alert_id', new_alert_id, 'recipients', recipients_count);
-- EXCEPTION WHEN OTHERS THEN
--     RETURN json_build_object('success', false, 'error', SQLERRM, 'recipients', 0);
-- END;
-- $function$;
