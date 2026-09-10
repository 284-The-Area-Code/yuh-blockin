-- App Configuration Table
-- Stores dynamic configuration values that can be updated without app releases

CREATE TABLE IF NOT EXISTS app_config (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- No seed rows. The only key this table ever held was 'ath_movil_path', which
-- became dead when the ATH Móvil integration was removed. See
-- supabase/migrations/20260910_remove_ath_movil_subscription_path.sql.

-- Enable RLS
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read config (public data)
CREATE POLICY "Anyone can read app config" ON app_config
    FOR SELECT USING (true);

-- Only service role can modify
CREATE POLICY "Service role can manage config" ON app_config
    FOR ALL USING (auth.role() = 'service_role');

-- Function to get config value
CREATE OR REPLACE FUNCTION get_app_config(p_key TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN (SELECT value FROM app_config WHERE key = p_key);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
