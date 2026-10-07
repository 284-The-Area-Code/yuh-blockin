-- Close the "Allow all" RLS policy on public.plates.
--
-- Found live in production:
--   policyname | cmd | roles    | qual
--   Allow all  | ALL | {public} | true
--
-- ALL + public + qual true means every unauthenticated client with nothing
-- more than the app's public API key can, via a direct REST call that never
-- touches the app:
--   - SELECT the owner (user_id) of any plate, by computing SHA-256 of a
--     plate number they already know - trivial, since plate_hash carries no
--     per-user salt
--   - DELETE any plate row - de-registering someone else's car with no proof
--     of ownership
--   - UPDATE ownership_key_hash on any row to a value of their choosing, then
--     "verify" ownership with a key they made up and steal the plate through
--     the app's own legitimate-looking transfer flow
--   - INSERT rows directly, bypassing every check the app's Dart code
--     performs
--
-- This migration replaces it with real row-level restriction, and moves the
-- two operations that legitimately need to cross ownership boundaries
-- (checking whether a plate is taken, and verifying/transferring ownership
-- with a key) into SECURITY DEFINER functions that enforce those rules
-- internally - the same pattern already used for send_alert() and
-- validate_alert_permission() elsewhere in this project.
--
-- SCOPE: only the two call sites that are actually reachable from the app are
-- touched. Confirmed by grep across lib/ before writing this:
--   checkPlateAvailability (simple_alert_service.dart)  - called by registerPlate,
--     which IS the live registration path used by plate_registration_screen.dart
--   verifyOwnership (plate_verification_service.dart)   - called by
--     account_recovery_service.dart and plate_registration_screen.dart
--
-- Deliberately NOT touched, because none of them have any caller in lib/:
--   registerPlateWithKey, initiateDispute, rotateOwnershipKey,
--   recoverPlateWithKey (a thin wrapper around verifyOwnership, itself unused -
--   the two live callers call verifyOwnership directly)
-- rotateOwnershipKey also writes a column (updated_at) that does not exist on
-- plates - a real but currently unreachable bug, left alone since fixing dead
-- code is out of scope here.

-- ---------------------------------------------------------------------------
-- 1. Replace the RLS policy set.
-- ---------------------------------------------------------------------------
alter table public.plates enable row level security;

drop policy if exists "Allow all" on public.plates;

create policy plates_select_own on public.plates
    for select to public
    using (user_id = (auth.uid())::text);

create policy plates_insert_own on public.plates
    for insert to public
    with check (user_id = (auth.uid())::text);

create policy plates_update_own on public.plates
    for update to public
    using (user_id = (auth.uid())::text)
    with check (user_id = (auth.uid())::text);

create policy plates_delete_own on public.plates
    for delete to public
    using (user_id = (auth.uid())::text);

-- ---------------------------------------------------------------------------
-- 2. check_plate_availability - replaces the cross-ownership read inside
--    checkPlateAvailability(). Never returns the actual owner's user_id to
--    the caller, matching what the Dart wrapper already exposed to the UI
--    (PlateCheckResult only ever carried two booleans) - this closes the
--    direct-REST bypass without changing what the app itself could already
--    see.
--
--    Uses auth.uid() rather than a passed-in user id, for the same reason
--    send_alert() does: a client-cached id can drift from the live session
--    (confirmed independently for THIS exact caller - account_recovery_service.dart
--    reads user_id from SharedPreferences, not fresh from auth). Deriving
--    identity server-side means a stale cache can only produce a wrong
--    "is this mine" answer locally, never a wrong database write.
-- ---------------------------------------------------------------------------
create or replace function public.check_plate_availability(p_plate_hash text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_caller text := auth.uid()::text;
    v_owner  text;
begin
    if v_caller is null then
        return jsonb_build_object(
            'is_available', false, 'is_owned_by_caller', false,
            'error', 'Not signed in');
    end if;

    select user_id into v_owner
    from public.plates
    where plate_hash = p_plate_hash
    limit 1;

    if v_owner is null then
        return jsonb_build_object('is_available', true, 'is_owned_by_caller', false);
    end if;

    return jsonb_build_object(
        'is_available', false,
        'is_owned_by_caller', v_owner = v_caller);
end;
$$;

-- ---------------------------------------------------------------------------
-- 3. verify_and_transfer_plate_ownership - replaces the cross-ownership
--    read+write inside verifyOwnership(): read ownership_key_hash for a plate
--    the caller may not yet own, and if it matches, transfer user_id to the
--    caller. This is the one operation on this table that must legitimately
--    cross the ownership boundary - which is exactly why "Allow all" existed
--    in the first place, and exactly why it was wrong: the WHOLE table was
--    opened up to make ONE narrow, key-gated case work.
--
--    Mirrors verifyOwnership()'s three branches exactly: not found, invalid
--    key, transfer-or-already-owner. Same auth.uid() reasoning as above.
-- ---------------------------------------------------------------------------
create or replace function public.verify_and_transfer_plate_ownership(
    p_plate_hash        text,
    p_ownership_key_hash text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_caller text := auth.uid()::text;
    v_id     uuid;
    v_owner  text;
    v_stored_hash text;
begin
    if v_caller is null then
        return jsonb_build_object('success', false, 'error', 'Not signed in');
    end if;

    select id, user_id, ownership_key_hash
      into v_id, v_owner, v_stored_hash
      from public.plates
     where plate_hash = p_plate_hash
     limit 1;

    if v_id is null then
        return jsonb_build_object('success', false, 'error', 'Plate not found in registry');
    end if;

    if v_stored_hash is distinct from p_ownership_key_hash then
        return jsonb_build_object('success', false, 'error', 'Invalid ownership key');
    end if;

    if v_owner = v_caller then
        return jsonb_build_object(
            'success', true, 'ownership_transferred', false,
            'message', 'Ownership verified! You are the rightful owner.');
    end if;

    update public.plates
       set user_id = v_caller,
           verification_status = 'verified',
           verified_at = now()
     where id = v_id;

    return jsonb_build_object(
        'success', true, 'ownership_transferred', true,
        'message', 'Ownership verified and plate transferred to your account!');
end;
$$;

-- ---------------------------------------------------------------------------
-- ROLLBACK - restores the exact policy that was live before this migration.
-- Run this alone if plate registration or recovery regresses.
-- ---------------------------------------------------------------------------
-- drop policy if exists plates_select_own on public.plates;
-- drop policy if exists plates_insert_own on public.plates;
-- drop policy if exists plates_update_own on public.plates;
-- drop policy if exists plates_delete_own on public.plates;
-- drop function if exists public.check_plate_availability(text);
-- drop function if exists public.verify_and_transfer_plate_ownership(text, text);
-- create policy "Allow all" on public.plates for all to public using (true);
