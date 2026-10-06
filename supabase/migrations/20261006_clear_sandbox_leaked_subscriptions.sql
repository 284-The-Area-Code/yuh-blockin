-- Data correction: revenuecat-webhook (fixed in
-- fix/revenuecat-webhook-sandbox-leak) synced RevenueCat sandbox
-- subscriptions/purchases into this production table as real premium,
-- because readSubscription()/readPurchase() never checked the item's
-- `environment` field. Verified against RevenueCat (app.revenuecat.com):
-- each of these 4 app_user_ids shows "No current entitlements" under
-- production but "This Customer has sandbox purchases." No real customer
-- purchase is affected by this correction.
--
-- One of the four (84471f10-...) is additionally confirmed via the
-- revenuecat-webhook function logs: a TRANSFER event explicitly tagged
-- `env SANDBOX` immediately preceded the `synced status=lifetime` write.
update public.subscriptions
set status = 'free',
    plan_type = null,
    expires_at = null,
    updated_at = now()
where user_id in (
    'e8a672f3-4d50-42a1-9538-9053c8866383',
    'c0bf0ba0-12f7-450f-b164-7ece2ba248ba',
    '5965c767-dddd-4ebb-8192-30204fc2e9c8',
    '84471f10-1df8-41de-a2f9-56ab0565e08c'
);
