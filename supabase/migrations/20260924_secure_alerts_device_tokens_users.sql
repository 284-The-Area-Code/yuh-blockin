-- Close three "Allow all" RLS policies found by the Database Advisor.
--
-- Found live in production (verified via pg_policies before writing this):
--   public.alerts         | Allow all | {public} | ALL | using true
--   public.device_tokens  | "Users can manage their own tokens" | {public} | ALL | using true, with check true
--   public.users          | Allow all | {public} | ALL | using true
--
-- Same shape as the public.plates vulnerability closed in
-- 20260914_secure_plates_table.sql: ALL + public + qual true means any client
-- holding only the app's public API key - no session required - can read,
-- insert, update, or delete every row in these tables directly over
-- PostgREST, regardless of any RPC-level hardening.
--
-- device_tokens' policy is a good example of why USING/WITH CHECK must be
-- read, not just the policy name: it is literally named "Users can manage
-- their own tokens" but its actual expression is `true` - the name describes
-- the intent, not the enforcement. Nothing currently enforces it.
--
-- alerts is the most serious of the three: with INSERT open to `true`, a
-- client can insert directly into public.alerts and completely bypass
-- send_alert()'s quota enforcement and sender-identity check added in
-- 20260911_enforce_quota_in_send_alert.sql. That hardening has been moot
-- for as long as this policy allowed a direct insert around it.
--
-- SCOPE, confirmed by reading every direct public.alerts / public.users
-- client call site in lib/ before writing this:
--   - send_alert() RPC (already hardened) does the real send. Its own
--     INSERT runs as the function's SECURITY DEFINER owner and is not
--     subject to these table-level policies either way.
--   - sendReminderAlert() (simple_alert_service.dart:415, called only from
--     alert_history_screen.dart:789) inserts directly as the sender.
--     senderUserId there is a widget-cached id, not guaranteed identical to
--     auth.uid() every time (same drift risk already documented for
--     send_alert's callers) - a strict sender_id = auth.uid() check can
--     occasionally reject a stale-cache reminder. Treated as acceptable:
--     matches this project's own established preference (see
--     20260911_enforce_quota_in_send_alert.sql) for surfacing an identity
--     mismatch rather than silently trusting a client-supplied id.
--   - _recordAlertResponse() (push_notification_service.dart:97) updates
--     response/response_at/read_at as the receiver. This is the only live
--     client UPDATE path on alerts.
--   - deleteAlert() (simple_alert_service.dart:625) has zero callers
--     anywhere in lib/ - dead code. No DELETE policy is granted; add one
--     with real product intent behind it if this is ever wired up.
--   - push_sent / push_sent_at are read client-side but never written
--     client-side - written by the alerts-fcm Edge Function via
--     service_role, which bypasses RLS regardless of these policies.
--   - getOrCreateUser() (simple_alert_service.dart:205) does exactly
--     `supabase.from('users').upsert({'id': authUserId})` - own id only.
--     Nothing in lib/ deletes a public.users row.
--
-- ---------------------------------------------------------------------------
-- alerts
-- ---------------------------------------------------------------------------
drop policy if exists "Allow all" on public.alerts;

create policy alerts_select_own on public.alerts
    for select to public
    using (sender_id = (auth.uid())::text or receiver_id = (auth.uid())::text);

create policy alerts_insert_as_sender on public.alerts
    for insert to public
    with check (sender_id = (auth.uid())::text);

create policy alerts_update_as_receiver on public.alerts
    for update to public
    using (receiver_id = (auth.uid())::text)
    with check (receiver_id = (auth.uid())::text);

-- No DELETE policy: deleteAlert() is unreachable dead code (see above).

-- ---------------------------------------------------------------------------
-- device_tokens
-- ---------------------------------------------------------------------------
drop policy if exists "Users can manage their own tokens" on public.device_tokens;

create policy device_tokens_manage_own on public.device_tokens
    for all to public
    using (user_id = (auth.uid())::text)
    with check (user_id = (auth.uid())::text);

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
drop policy if exists "Allow all" on public.users;

create policy users_select_own on public.users
    for select to public
    using (id = (auth.uid())::text);

create policy users_insert_own on public.users
    for insert to public
    with check (id = (auth.uid())::text);

create policy users_update_own on public.users
    for update to public
    using (id = (auth.uid())::text)
    with check (id = (auth.uid())::text);

-- No DELETE policy: nothing in lib/ deletes a users row, and subscriptions
-- references it ON DELETE CASCADE - deletion should stay a deliberate,
-- privileged action (e.g. via the admin-manage-user Edge Function, which
-- uses service_role and is unaffected by this policy), not open client access.

-- ---------------------------------------------------------------------------
-- ROLLBACK - restores the exact policies that were live before this migration.
-- Run this alone if alerts, device tokens, or account creation regresses.
-- ---------------------------------------------------------------------------
-- drop policy if exists alerts_select_own on public.alerts;
-- drop policy if exists alerts_insert_as_sender on public.alerts;
-- drop policy if exists alerts_update_as_receiver on public.alerts;
-- create policy "Allow all" on public.alerts for all to public using (true);
--
-- drop policy if exists device_tokens_manage_own on public.device_tokens;
-- create policy "Users can manage their own tokens" on public.device_tokens
--     for all to public using (true) with check (true);
--
-- drop policy if exists users_select_own on public.users;
-- drop policy if exists users_insert_own on public.users;
-- drop policy if exists users_update_own on public.users;
-- create policy "Allow all" on public.users for all to public using (true);
