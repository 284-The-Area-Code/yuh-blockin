-- Durable record that an account holder actively agreed to the Terms of
-- Service (Apple Guideline 1.2: EULA must be actively agreed to). The
-- primary enforcement is client-side (see OnboardingFlow's agreement gate)
-- because a brand-new install has no auth session yet when onboarding first
-- shows; this column is an opportunistic, best-effort server stamp written
-- once getOrCreateUser() first runs, for durability across reinstall/device
-- change and so admin-center can show it if ever needed.
--
-- No RLS change needed: users_update_own (20260924) already permits
-- id = auth.uid() to update every column on their own row.

alter table public.users
    add column tos_agreed_at timestamptz,
    add column tos_version   text;

-- ---------------------------------------------------------------------------
-- ROLLBACK
-- ---------------------------------------------------------------------------
-- alter table public.users drop column if exists tos_agreed_at;
-- alter table public.users drop column if exists tos_version;
