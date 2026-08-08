// Yuh Blockin' Premium Configuration
// Caribbean-style premium features for app store versions

class PremiumConfig {
  // Build-time constants
  static const bool isPremium = bool.fromEnvironment('CARIBBEAN_PREMIUM', defaultValue: false);
  static const String flavor = String.fromEnvironment('FLAVOR', defaultValue: 'development');
  static const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

  // Premium Features
  static const bool caribbeanPremium = bool.fromEnvironment('CARIBBEAN_PREMIUM', defaultValue: false);
  static const bool manimAnimations = bool.fromEnvironment('MANIM_PREMIUM', defaultValue: false);
  static const bool realTimeEta = true;
  static const bool voiceAlerts = isPremium;
  static const bool darkMode = isPremium;
  static const bool unlimitedMessages = isPremium;
  static const bool prioritySupport = isPremium;
  static const bool advancedAnalytics = isPremium;

  // App Information
  static const String appName = isPremium ? 'Yuh Blockin\' Premium' : 'Yuh Blockin\'';
  static const String tagline = isPremium
      ? 'Premium Caribbean parking alerts with mathematical precision'
      : 'Caribbean-style parking alerts with island respect';

  // Caribbean Branding
  static const String motto = isPremium
      ? 'Walk good with premium island vibes! 🏝️'
      : 'Easy nuh! Keep parking smooth with Caribbean respect! 🏝️';

  // Premium Limits
  static const int maxAlertsPerDay = isPremium ? 200 : 50;
  static const int maxCustomMessages = isPremium ? -1 : 10; // -1 = unlimited
  static const int escalationIntervalSeconds = isPremium ? 5 : 10;
  static const int maxPlatesPerUser = isPremium ? 10 : 3;

  // Premium Messages
  static const List<String> premiumOnlyMessages = [
    'Premium bredrin checking in! 🏝️',
    'VIP island vibes - move with respect! ⭐',
    'Premium user requesting assistance 🎯',
    'Big up premium community! 👑',
    'Island royalty needs passage! 👑🏝️',
  ];

  // Voice Alert Settings (Premium only)
  static const bool voiceAlertsEnabled = isPremium;
  static const String voiceLanguage = 'caribbean_english';
  static const double voiceSpeed = 1.0;
  static const String voiceGender = 'mixed'; // Authentic Caribbean voices

  // Dark Mode Theme (Premium only)
  static const bool darkModeAvailable = isPremium;
  static const String darkThemeName = 'caribbean_sunset';

  // Analytics Settings
  static const bool advancedAnalyticsEnabled = isPremium;
  static const bool personalizedInsights = isPremium;
  static const bool exportData = isPremium;

  // Priority Support
  static const bool prioritySupportEnabled = isPremium;
  static const String supportEmail = isPremium
      ? 'premium@yuhblockin.com'
      : 'support@yuhblockin.com';
  static const String supportUrl = 'https://deze-tingz.github.io/yuh-blockin/support.html';
  static const String supportLevel = isPremium ? 'premium' : 'standard';

  // Feature Availability Checks
  static bool get canUseVoiceAlerts => isPremium && voiceAlertsEnabled;
  static bool get canUseDarkMode => isPremium && darkModeAvailable;
  static bool get canUseUnlimitedMessages => isPremium;
  static bool get canAccessAdvancedAnalytics => isPremium && advancedAnalyticsEnabled;
  static bool get canGetPrioritySupport => isPremium && prioritySupportEnabled;

  // Premium Message Validation
  static bool canUseMessage(String message) {
    if (!isPremium && premiumOnlyMessages.contains(message)) {
      return false;
    }
    return true;
  }

  // Premium Feature Descriptions
  static const Map<String, String> premiumFeatureDescriptions = {
    'voice_alerts': 'Authentic Caribbean voice alerts with island accent',
    'dark_mode': 'Beautiful Caribbean sunset dark theme',
    'unlimited_messages': 'Express yourself with unlimited custom messages',
    'real_time_eta': 'Precise ETA tracking with mathematical accuracy',
    'priority_support': 'Personal island-style customer care',
    'advanced_analytics': 'Deep insights into your parking karma',
    'manim_animations': 'Premium mathematical animations at 60fps',
    'extended_limits': 'Higher daily limits and more license plates',
  };

  // Premium Upgrade Benefits
  static const List<String> upgradeReasons = [
    '🎵 Authentic Caribbean voice alerts',
    '🌅 Beautiful Caribbean sunset dark mode',
    '💬 Unlimited custom Caribbean messages',
    '⏱️ Real-time ETA with mathematical precision',
    '⭐ Priority customer support with island care',
    '📊 Advanced analytics and parking insights',
    '🎬 Premium Manim animations at 60fps',
    '🚗 Support up to 10 license plates',
    '📈 200 alerts per day (vs 50 free)',
    '👑 VIP Caribbean community status',
  ];

  // Store Information (must match actual bundle IDs in build configs)
  static const String bundleId = 'com.dezetingz.yuhBlockin';

  // Version Information (keep in sync with pubspec.yaml)
  static const String version = '1.0.0';
  static const int buildNumber = 87;
  static String get fullVersion => isPremium ? '$version Premium' : '$version Free';

  // Caribbean Premium Expressions
  static const List<String> premiumExpressions = [
    'Big up premium vibes! 👑',
    'VIP island treatment! ⭐',
    'Premium bredrin checking in! 🏝️',
    'Royal Caribbean service! 👑🏝️',
    'Premium island excellence! 🎯',
    'Top-shelf Caribbean respect! 🥃',
    'First-class island vibes! ✈️🏝️',
    'Premium community strong! 💪👑',
  ];

  // Premium Status Display
  static String get buildInfo {
    return isPremium ? 'Premium Edition' : 'Community Edition';
  }

  // logPremiumStatus is intentionally left empty for production
  // Use debugPrint in debug mode if logging is needed
}


// Premium Feature Enums
enum PremiumFeature {
  voiceAlerts,
  darkMode,
  unlimitedMessages,
  realTimeEta,
  prioritySupport,
  advancedAnalytics,
  manimAnimations,
  extendedLimits,
}

// Premium tier helper
class PremiumTier {
  static bool hasFeature(PremiumFeature feature) {
    if (!PremiumConfig.isPremium) return false;

    switch (feature) {
      case PremiumFeature.voiceAlerts:
        return PremiumConfig.canUseVoiceAlerts;
      case PremiumFeature.darkMode:
        return PremiumConfig.canUseDarkMode;
      case PremiumFeature.unlimitedMessages:
        return PremiumConfig.canUseUnlimitedMessages;
      case PremiumFeature.realTimeEta:
        return PremiumConfig.realTimeEta;
      case PremiumFeature.prioritySupport:
        return PremiumConfig.canGetPrioritySupport;
      case PremiumFeature.advancedAnalytics:
        return PremiumConfig.canAccessAdvancedAnalytics;
      case PremiumFeature.manimAnimations:
        return PremiumConfig.manimAnimations;
      case PremiumFeature.extendedLimits:
        return true; // All premium users get extended limits
    }
  }

  static String getFeatureDescription(PremiumFeature feature) {
    switch (feature) {
      case PremiumFeature.voiceAlerts:
        return PremiumConfig.premiumFeatureDescriptions['voice_alerts']!;
      case PremiumFeature.darkMode:
        return PremiumConfig.premiumFeatureDescriptions['dark_mode']!;
      case PremiumFeature.unlimitedMessages:
        return PremiumConfig.premiumFeatureDescriptions['unlimited_messages']!;
      case PremiumFeature.realTimeEta:
        return PremiumConfig.premiumFeatureDescriptions['real_time_eta']!;
      case PremiumFeature.prioritySupport:
        return PremiumConfig.premiumFeatureDescriptions['priority_support']!;
      case PremiumFeature.advancedAnalytics:
        return PremiumConfig.premiumFeatureDescriptions['advanced_analytics']!;
      case PremiumFeature.manimAnimations:
        return PremiumConfig.premiumFeatureDescriptions['manim_animations']!;
      case PremiumFeature.extendedLimits:
        return PremiumConfig.premiumFeatureDescriptions['extended_limits']!;
    }
  }
}