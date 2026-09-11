-- Drop the dead ATH Móvil tables.
--
-- The ATH Móvil integration was removed in "Remove the ATH Movil payment
-- system". Its migration deliberately left these tables in place because it
-- could not verify they held no payment records. That check has now been run
-- against production:
--
--   ath_movil_transactions      0 rows
--   ath_monthly_subscriptions   0 rows
--
-- Both empty, so there is nothing to export and nothing to lose.
--
-- Nothing reads them: the Dart service and the three ath-* Edge Functions are
-- deleted, and validate_alert_permission() stopped referencing
-- ath_monthly_subscriptions in 20260910.

drop table if exists public.ath_monthly_subscriptions;
drop table if exists public.ath_movil_transactions;

-- The app_config row that held the ATH business path is dead too. The table
-- itself is general-purpose infrastructure and stays; only the row goes.
-- (app_config may not exist - the ATH service's reads always fell through to a
-- hardcoded default, which is why this is guarded.)
do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'app_config'
  ) then
    delete from public.app_config where key = 'ath_movil_path';
  end if;
end $$;
