-- Migration: secure the alerts-fcm trigger call (service-to-service, API-key auth)
--
-- PROBLEM BEING FIXED
-- The previous definition built its authorization header as:
--     'Bearer ' || current_setting('supabase.service_role_key', true)
-- `supabase.service_role_key` is not a standard Supabase GUC and was never set on this
-- database. With missing_ok = true, current_setting() returns NULL, and in Postgres
-- 'Bearer ' || NULL evaluates to NULL — so the Authorization header was absent.
-- Every alert insert therefore produced HTTP 401 UNAUTHORIZED_NO_AUTH_HEADER at the
-- Edge Function gateway, and the alerts-fcm handler never executed. Because pg_net is
-- fire-and-forget (PERFORM net.http_post discards the response), the failure surfaced
-- nowhere except net._http_response.
--
-- NEW DESIGN
-- Current Supabase service-to-service pattern for pg_net callers:
--     named secret key from Vault -> apikey header -> alerts-fcm
--     -> createSupabaseContext(req, { auth: 'secret:alerts_fcm_trigger' })
--
-- The secret key is sent on `apikey` ONLY. It must NOT be sent on Authorization:
-- Bearer, because the platform would attempt to parse it as a JWT and reject the
-- request with "Invalid JWT" (new-style secret keys are not JWTs).
--
-- This file contains NO secret material. Both values are read from Supabase Vault at
-- execution time. Create them via the Dashboard Vault UI, never via the SQL Editor
-- (which retains query history):
--     alerts_fcm_project_url
--     alerts_fcm_secret_key
--
-- The trigger on_new_alert_send_push is intentionally NOT recreated: its timing
-- (AFTER INSERT ON alerts, FOR EACH ROW) and definition are unchanged. Only the
-- function body it already points to is replaced. The request body is byte-identical
-- to the previous definition.

create or replace function public.notify_alert_push()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url    text;
  v_secret text;
begin
  select decrypted_secret into v_url
    from vault.decrypted_secrets
   where name = 'alerts_fcm_project_url';

  select decrypted_secret into v_secret
    from vault.decrypted_secrets
   where name = 'alerts_fcm_secret_key';

  -- Fail visibly instead of dispatching a malformed request. The absence of a guard
  -- like this is precisely why the original defect went undetected for so long.
  -- Logs boolean presence only — never the URL, never the secret.
  if v_url is null or v_secret is null then
    raise warning
      'notify_alert_push: missing Vault secret(s) [url_present=%, secret_present=%]; push NOT sent for alert %',
      (v_url is not null), (v_secret is not null), new.id;
    return new;
  end if;

  perform net.http_post(
    url := v_url || '/functions/v1/alerts-fcm',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey',       v_secret
    ),
    body := jsonb_build_object(
      'alert_id',      new.id::text,
      'receiver_id',   new.receiver_id,
      'message',       coalesce(new.message, 'Someone needs you to move your car!'),
      'sound_path',    new.sound_path,
      'urgency_level', coalesce(new.urgency_level, 'normal')
    )
  );

  return new;
end;
$$;
