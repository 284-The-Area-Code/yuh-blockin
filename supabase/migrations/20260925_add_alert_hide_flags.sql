-- Soft-hide for alerts (Apple Guideline 1.2 "immediately remove content from
-- feed" remediation).
--
-- Replaces the hard-DELETE "Clear Received/Sent/All" actions in
-- alert_history_screen.dart (deleteReceivedAlerts/deleteSentAlerts/
-- deleteAllAlerts, simple_alert_service.dart) and the dead deleteAlert(),
-- none of which can be kept: evidence must survive a hard delete for
-- reports to mean anything. Two independent columns because Clear Sent and
-- Clear Received are independent actions on the SAME row from two
-- different users' perspectives - hiding it from the receiver must not
-- also make it vanish from the sender's own sent history.
--
-- The filter lives in the SELECT policy itself, not client-side, so every
-- existing read path (getReceivedAlerts, getSentAlerts, getAlertsStream,
-- getSentAlertsStream, getAlertById) is covered with zero Dart changes and
-- cannot be bypassed by a client that "forgets" to filter.
--
-- Admin (admin-manage-user, service_role) bypasses RLS entirely and
-- continues to see hidden rows - this is what "evidence survives" means in
-- practice.

alter table public.alerts
    add column hidden_by_sender   boolean not null default false,
    add column hidden_by_receiver boolean not null default false;

drop policy if exists alerts_select_own on public.alerts;

create policy alerts_select_own on public.alerts
    for select to public
    using (
        (sender_id = (auth.uid())::text and hidden_by_sender is not true)
        or
        (receiver_id = (auth.uid())::text and hidden_by_receiver is not true)
    );

-- alerts_update_as_receiver (20260924) already allows the receiver to write
-- any column on their own received row, so it already legally covers
-- hidden_by_receiver with no change. There is no equivalent sender-side
-- update policy yet - add one, same shape, so a sender can set
-- hidden_by_sender ("Clear Sent"). Same row-level (not column-level)
-- granularity as the existing receiver policy already accepts - consistent
-- with, not a regression from, current practice.
create policy alerts_update_as_sender on public.alerts
    for update to public
    using (sender_id = (auth.uid())::text)
    with check (sender_id = (auth.uid())::text);

-- ---------------------------------------------------------------------------
-- ROLLBACK
-- ---------------------------------------------------------------------------
-- drop policy if exists alerts_update_as_sender on public.alerts;
-- drop policy if exists alerts_select_own on public.alerts;
-- create policy alerts_select_own on public.alerts
--     for select to public
--     using (sender_id = (auth.uid())::text or receiver_id = (auth.uid())::text);
-- alter table public.alerts drop column if exists hidden_by_sender;
-- alter table public.alerts drop column if exists hidden_by_receiver;
