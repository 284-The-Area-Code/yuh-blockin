-- Report mechanism (Apple Guideline 1.2 remediation).
--
-- INSERT-only for authenticated clients. No SELECT/UPDATE/DELETE policy is
-- granted at all: reports are triaged exclusively through the
-- admin-manage-user Edge Function (service_role, bypasses RLS), surfaced in
-- admin-center - not read back by the reporter or anyone else client-side.
--
-- alert_id references public.alerts(id) so admin triage can pull the actual
-- reported message. Nullable because a report may be about a user/pattern of
-- behavior rather than one specific alert. "on delete set null" is
-- defensive only - alerts has no DELETE policy (20260911/20260924) and
-- nothing in this schema ever hard-deletes a row from it.
--
-- Deliberately no FK to public.users(id), same reasoning as blocked_users:
-- admin-manage-user's delete (eject) action must not be blocked by a
-- foreign key from the very report that triggered the ejection. Report rows
-- are the audit trail proving a report was received and acted on, so they
-- are never cleaned up by that action.

create table public.reports (
    id               uuid primary key default gen_random_uuid(),
    reporter_id      text not null,
    reported_user_id text not null,
    alert_id         uuid references public.alerts(id) on delete set null,
    reason           text not null check (reason in (
                          'harassment', 'threats', 'hate_speech',
                          'spam', 'inappropriate_content', 'other')),
    details          text,
    status           text not null default 'open'
                          check (status in ('open', 'reviewed', 'actioned', 'dismissed')),
    created_at       timestamptz not null default now(),
    reviewed_at      timestamptz,
    reviewed_by      text,
    resolution_note  text
);

create index reports_status_created_idx on public.reports (status, created_at desc);

alter table public.reports enable row level security;

create policy reports_insert_own on public.reports
    for insert to public
    with check (reporter_id = (auth.uid())::text);

-- ---------------------------------------------------------------------------
-- ROLLBACK
-- ---------------------------------------------------------------------------
-- drop table if exists public.reports;
