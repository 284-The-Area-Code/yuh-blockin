-- Block mechanism (Apple Guideline 1.2 remediation).
--
-- New table only - plain own-row RLS, no SECURITY DEFINER function needed,
-- because creating/removing a block never crosses an ownership boundary (a
-- caller only ever writes a row keyed by their own blocker_id, exactly like
-- alerts_insert_as_sender already allowed writing a row that names another
-- user's id in receiver_id). The part of "blocking" that DOES cross a
-- boundary - actually suppressing a blocked sender's future alerts,
-- silently - is enforced separately inside send_alert()/send_reminder_alert(),
-- see 20260926_enforce_block_in_send_alert.sql.
--
-- Deliberately no FK to public.users(id): every other per-user table in this
-- schema (plates, device_tokens, alerts) uses a bare text id for the same
-- reason - admin-manage-user's delete action must be able to delete a users
-- row without a foreign key from an unrelated table blocking it.

create table public.blocked_users (
    blocker_id text not null,
    blocked_id text not null,
    created_at timestamptz not null default now(),
    primary key (blocker_id, blocked_id)
);

alter table public.blocked_users enable row level security;

create policy blocked_users_select_own on public.blocked_users
    for select to public
    using (blocker_id = (auth.uid())::text);

create policy blocked_users_insert_own on public.blocked_users
    for insert to public
    with check (
        blocker_id = (auth.uid())::text
        and blocked_id <> (auth.uid())::text
    );

create policy blocked_users_delete_own on public.blocked_users
    for delete to public
    using (blocker_id = (auth.uid())::text);

-- No update policy: a block is binary - delete the row to unblock.

-- ---------------------------------------------------------------------------
-- ROLLBACK
-- ---------------------------------------------------------------------------
-- drop table if exists public.blocked_users;
