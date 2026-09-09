/// Supabase Configuration for Yuh Blockin'
///
/// Uses the NEW Supabase API key format (`sb_publishable_...`).
/// The legacy `anon` JWT key is no longer used: legacy API keys have been
/// disabled on this project. Supabase is deprecating `anon` / `service_role`
/// keys by the end of 2026.
///
/// IMPORTANT: For production, set these values via environment variables:
///
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co
///   flutter run --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
///
/// For development, the default values below are used.
class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase Project URL
  ///
  /// Set via environment variable for production:
  /// --dart-define=SUPABASE_URL=https://your-project.supabase.co
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://oazxwglbvzgpehsckmfb.supabase.co',
  );

  /// Supabase Publishable Key (`sb_publishable_...`)
  ///
  /// This is the public, browser-safe key that replaces the legacy `anon` key.
  /// It relies on Row Level Security, so it is safe to ship inside the app —
  /// but prefer providing it via environment variable:
  ///
  /// --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
  ///
  /// Note: this key is NOT a JWT. The Supabase Dart SDK sends it on the
  /// `apikey` header (and, for auth/database calls, also as a Bearer token,
  /// which the server tolerates — verified against /auth/v1/settings and
  /// /rest/v1 before migrating).
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_xxOljXZiqvnQJYpFetJg9Q_cZpKOB5D',
  );

  /// Check if using environment-provided credentials (more secure)
  static bool get isConfiguredViaEnvironment {
    // Check if URL was overridden from default
    const defaultUrl = 'https://oazxwglbvzgpehsckmfb.supabase.co';
    return url != defaultUrl ||
           const bool.hasEnvironment('SUPABASE_URL') ||
           const bool.hasEnvironment('SUPABASE_PUBLISHABLE_KEY');
  }

  /// Validate configuration
  static bool get isValid {
    return url.isNotEmpty &&
           publishableKey.isNotEmpty &&
           publishableKey != 'PASTE_YOUR_SB_PUBLISHABLE_KEY_HERE' &&
           publishableKey.startsWith('sb_publishable_') &&
           url.startsWith('https://') &&
           url.contains('supabase.co');
  }
}
