-- In-app feedback: tap-to-answer questions plus 1-5 star theme ratings, with
-- an optional short comment (200 characters max) on each question and on the
-- theme ratings.
--
-- Safe to run more than once: it creates what is missing and replaces the
-- function and views, so it also upgrades a database where an earlier
-- version of this file (without comments) was already run.
--
-- Clients never touch the table directly. RLS is enabled with no policies at
-- all, and the only way in is submit_app_feedback(), a SECURITY DEFINER
-- function that stamps the caller's own auth.uid(), checks the shape of what
-- was sent, and caps submissions per user. Results are read in the Supabase
-- dashboard (service_role), e.g. from app_feedback_theme_ratings below.
--
-- Question and option ids are defined in the app
-- (lib/features/feedback/feedback_questions.dart). The server checks only
-- their format, not the exact list, so questions can change in an app update
-- without a new migration.
--
-- Deliberately no FK to public.users(id), same reasoning as blocked_users:
-- admin-manage-user's delete action must not be blocked by feedback rows.

create table if not exists public.app_feedback (
    id            uuid primary key default gen_random_uuid(),
    user_id       text not null,
    answers       jsonb not null default '{}'::jsonb,
    theme_ratings jsonb not null default '{}'::jsonb,
    comments      jsonb not null default '{}'::jsonb,
    current_theme text,
    platform      text check (platform in ('android', 'ios')),
    created_at    timestamptz not null default now()
);

alter table public.app_feedback
    add column if not exists comments jsonb not null default '{}'::jsonb;

create index if not exists app_feedback_user_created_idx on public.app_feedback (user_id, created_at desc);
create index if not exists app_feedback_created_idx on public.app_feedback (created_at desc);

alter table public.app_feedback enable row level security;
-- No policies: no direct client reads or writes.

-- ---------------------------------------------------------------------------
-- submit_app_feedback
-- ---------------------------------------------------------------------------
-- p_answers:       {"question_id": "option_id" | ["option_id", ...], ...}
-- p_theme_ratings: {"theme_id": 1..5, ...}
-- p_comments:      {"question_id" | "themes": "short text", ...}
-- Ids must match ^[a-z0-9_]{1,40}$. At most 20 questions, 6 picks per
-- question and 20 themes. Comments are trimmed, at most 200 characters each,
-- and empty ones are dropped. At least one answer, rating or comment is
-- required.
-- Limit: 3 submissions per user per 24 hours.
drop function if exists public.submit_app_feedback(jsonb, jsonb, text, text);

create or replace function public.submit_app_feedback(
    p_answers jsonb,
    p_theme_ratings jsonb,
    p_current_theme text default null,
    p_platform text default null,
    p_comments jsonb default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid text := (auth.uid())::text;
    v_key text;
    v_val jsonb;
    v_item jsonb;
    v_id uuid;
    v_text text;
    v_comments jsonb := '{}'::jsonb;
    v_id_pattern constant text := '^[a-z0-9_]{1,40}$';
begin
    if v_uid is null then
        raise exception 'not_authenticated';
    end if;

    p_answers := coalesce(p_answers, '{}'::jsonb);
    p_theme_ratings := coalesce(p_theme_ratings, '{}'::jsonb);
    p_comments := coalesce(p_comments, '{}'::jsonb);

    if jsonb_typeof(p_answers) <> 'object'
       or jsonb_typeof(p_theme_ratings) <> 'object'
       or jsonb_typeof(p_comments) <> 'object' then
        raise exception 'invalid_feedback';
    end if;

    if (select count(*) from jsonb_object_keys(p_answers)) > 20
       or (select count(*) from jsonb_object_keys(p_theme_ratings)) > 20
       or (select count(*) from jsonb_object_keys(p_comments)) > 20 then
        raise exception 'invalid_feedback';
    end if;

    for v_key, v_val in select * from jsonb_each(p_comments) loop
        if v_key !~ v_id_pattern or jsonb_typeof(v_val) <> 'string' then
            raise exception 'invalid_feedback';
        end if;
        v_text := btrim(v_val #>> '{}');
        if char_length(v_text) > 200 then
            raise exception 'comment_too_long';
        end if;
        if v_text <> '' then
            v_comments := v_comments || jsonb_build_object(v_key, v_text);
        end if;
    end loop;

    if p_answers = '{}'::jsonb
       and p_theme_ratings = '{}'::jsonb
       and v_comments = '{}'::jsonb then
        raise exception 'empty_feedback';
    end if;

    for v_key, v_val in select * from jsonb_each(p_answers) loop
        if v_key !~ v_id_pattern then
            raise exception 'invalid_feedback';
        end if;
        if jsonb_typeof(v_val) = 'string' then
            if (v_val #>> '{}') !~ v_id_pattern then
                raise exception 'invalid_feedback';
            end if;
        elsif jsonb_typeof(v_val) = 'array' then
            if jsonb_array_length(v_val) < 1 or jsonb_array_length(v_val) > 6 then
                raise exception 'invalid_feedback';
            end if;
            for v_item in select * from jsonb_array_elements(v_val) loop
                if jsonb_typeof(v_item) <> 'string' or (v_item #>> '{}') !~ v_id_pattern then
                    raise exception 'invalid_feedback';
                end if;
            end loop;
        else
            raise exception 'invalid_feedback';
        end if;
    end loop;

    for v_key, v_val in select * from jsonb_each(p_theme_ratings) loop
        if v_key !~ v_id_pattern
           or jsonb_typeof(v_val) <> 'number'
           or (v_val #>> '{}') !~ '^[1-5]$' then
            raise exception 'invalid_feedback';
        end if;
    end loop;

    if p_current_theme is not null and p_current_theme !~ v_id_pattern then
        p_current_theme := null;
    end if;
    if p_platform is not null and p_platform not in ('android', 'ios') then
        p_platform := null;
    end if;

    if (select count(*) from public.app_feedback
        where user_id = v_uid and created_at > now() - interval '24 hours') >= 3 then
        raise exception 'rate_limited';
    end if;

    insert into public.app_feedback (user_id, answers, theme_ratings, comments, current_theme, platform)
    values (v_uid, p_answers, p_theme_ratings, v_comments, p_current_theme, p_platform)
    returning id into v_id;

    return v_id;
end;
$$;

revoke all on function public.submit_app_feedback(jsonb, jsonb, text, text, jsonb) from public, anon;
grant execute on function public.submit_app_feedback(jsonb, jsonb, text, text, jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- Reporting views (dashboard / service_role only)
-- ---------------------------------------------------------------------------
-- Average star rating per theme. Only each person's latest rating of a theme
-- counts, so one person resubmitting can't skew the numbers.
create or replace view public.app_feedback_theme_ratings as
with latest as (
    select distinct on (f.user_id, r.key)
           r.key as theme,
           (r.value #>> '{}')::int as stars
    from public.app_feedback f,
         jsonb_each(f.theme_ratings) r
    order by f.user_id, r.key, f.created_at desc
)
select theme,
       round(avg(stars), 2) as avg_stars,
       count(*) as ratings
from latest
group by theme
order by avg_stars desc;

-- How often each option was picked, per question (all submissions).
create or replace view public.app_feedback_answer_counts as
select a.key as question,
       coalesce(o.value #>> '{}', a.value #>> '{}') as answer,
       count(*) as picks
from public.app_feedback f,
     jsonb_each(f.answers) a
     left join lateral jsonb_array_elements(
         case when jsonb_typeof(a.value) = 'array' then a.value else '[]'::jsonb end
     ) o on true
group by 1, 2
order by 1, 3 desc;

-- Every written comment, newest first, next to the question it was left on.
create or replace view public.app_feedback_comments as
select f.created_at,
       c.key as question,
       c.value #>> '{}' as comment,
       f.answers -> c.key as answer,
       f.current_theme,
       f.platform
from public.app_feedback f,
     jsonb_each(f.comments) c
order by f.created_at desc;

revoke all on public.app_feedback_comments from public, anon, authenticated;
revoke all on public.app_feedback_theme_ratings from public, anon, authenticated;
revoke all on public.app_feedback_answer_counts from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- ROLLBACK
-- ---------------------------------------------------------------------------
-- drop view if exists public.app_feedback_comments;
-- drop view if exists public.app_feedback_answer_counts;
-- drop view if exists public.app_feedback_theme_ratings;
-- drop function if exists public.submit_app_feedback(jsonb, jsonb, text, text, jsonb);
-- drop table if exists public.app_feedback;
