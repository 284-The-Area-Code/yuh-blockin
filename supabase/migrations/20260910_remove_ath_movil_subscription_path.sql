-- Remove the ATH Móvil entitlement path.
--
-- The ATH Móvil integration has been removed from the app. Purchases now go
-- exclusively through StoreKit / Google Play Billing, brokered by RevenueCat,
-- and `public.subscriptions` is the single source of truth for entitlement.
--
-- This migration changes FUNCTIONS ONLY. It deliberately does not drop
-- `ath_movil_transactions` or `ath_monthly_subscriptions` - see the
-- verification block at the bottom of this file.
--
-- Two changes are made to each function:
--   1. The ATH branch is removed from the premium check.
--   2. `SET search_path = ''` is added. Both functions are SECURITY DEFINER
--      and previously ran with the caller's search_path, which lets a caller
--      shadow an unqualified object name with one in a schema they control.
--      All references below are therefore schema-qualified.

-- 1. Permission check -- reads public.subscriptions only.
CREATE OR REPLACE FUNCTION public.validate_alert_permission()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_user_id TEXT := auth.uid()::text;
    v_is_premium BOOLEAN := FALSE;
    v_alerts_sent INTEGER := 0;
    v_last_alert_at TIMESTAMP WITH TIME ZONE;
    v_limit INTEGER := 1; -- Matches PaymentConfig.freeDailyAlertLimit
BEGIN
    -- Reject unauthenticated callers outright. Previously v_user_id could be
    -- NULL, every lookup missed, and the caller was handed a free-tier grant.
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object(
            'allowed', FALSE,
            'is_premium', FALSE,
            'remaining', 0,
            'reason', 'Not signed in'
        );
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM public.subscriptions
        WHERE user_id = v_user_id
          AND status IN ('premium', 'lifetime')
          AND (expires_at IS NULL OR expires_at > NOW())
    ) INTO v_is_premium;

    -- Premium users get unlimited access
    IF v_is_premium THEN
        RETURN jsonb_build_object(
            'allowed', TRUE,
            'is_premium', TRUE,
            'remaining', 999,
            'reason', NULL
        );
    END IF;

    -- Get current usage for free user
    SELECT alerts_sent, last_alert_at INTO v_alerts_sent, v_last_alert_at
    FROM public.daily_usage
    WHERE user_id = v_user_id;

    -- Reset usage if it's a new day
    IF v_last_alert_at IS NULL OR v_last_alert_at::date < NOW()::date THEN
        v_alerts_sent := 0;
    END IF;

    -- Final permission check
    IF v_alerts_sent < v_limit THEN
        RETURN jsonb_build_object(
            'allowed', TRUE,
            'is_premium', FALSE,
            'remaining', v_limit - v_alerts_sent,
            'reason', NULL
        );
    ELSE
        RETURN jsonb_build_object(
            'allowed', FALSE,
            'is_premium', FALSE,
            'remaining', 0,
            'reason', 'Daily limit of ' || v_limit || ' alerts reached. Upgrade to Premium for unlimited access!'
        );
    END IF;
END;
$$;

-- 2. Usage increment -- unchanged logic, hardened search_path.
CREATE OR REPLACE FUNCTION public.increment_daily_usage()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_user_id TEXT := auth.uid()::text;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN;
    END IF;

    INSERT INTO public.daily_usage (user_id, alerts_sent, last_alert_at, updated_at)
    VALUES (v_user_id, 1, NOW(), NOW())
    ON CONFLICT (user_id) DO UPDATE SET
        alerts_sent = CASE
            WHEN public.daily_usage.last_alert_at::date < NOW()::date THEN 1
            ELSE public.daily_usage.alerts_sent + 1
        END,
        last_alert_at = NOW(),
        updated_at = NOW();
END;
$$;

-- ---------------------------------------------------------------------------
-- 3. Dropping the ATH tables -- MANUAL, NOT PART OF THIS MIGRATION.
--
-- After this migration is applied, nothing in the app or the database reads
-- these tables. They are left in place because this migration cannot verify
-- that they hold no payment records. Run the check first:
--
--   SELECT 'ath_movil_transactions'  AS t, count(*) FROM public.ath_movil_transactions
--   UNION ALL
--   SELECT 'ath_monthly_subscriptions', count(*) FROM public.ath_monthly_subscriptions;
--
-- If BOTH counts are 0, drop them in a follow-up migration:
--
--   DROP TABLE IF EXISTS public.ath_monthly_subscriptions;
--   DROP TABLE IF EXISTS public.ath_movil_transactions;
--
-- If either is non-zero, export the rows before dropping - they are records of
-- real money movement.
--
-- The app_config row that held the ATH business path is also dead and can be
-- removed at the same time:
--
--   DELETE FROM public.app_config WHERE key = 'ath_movil_path';
--
-- Finally, these Edge Functions (if deployed) no longer have any caller and
-- should be deleted along with their ATH_MOVIL_* secrets:
--   ath-create-payment, ath-check-payment, ath-authorize-payment
-- ---------------------------------------------------------------------------
