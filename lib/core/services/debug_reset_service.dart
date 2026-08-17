import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// INTERNAL-ONLY Debug Utility
/// 
/// Used to clear all local application state to simulate a true clean install.
/// This service is strictly for developer usage and should not be reachable
/// from any production UI.
class DebugResetService {
  static const List<String> _keysToClear = [
    'user_id',
    'user_id_backup',
    'yuh_plates_secure_data',
    'onboarding_completed',
    'unseen_alerts_count',
    'unseen_impact_count',
    'yuh_subscription_status',
    'yuh_daily_alerts_used',
    'yuh_last_usage_date',
    'yuh_last_synced_user_id',
    'alert_sound_low',
    'alert_sound_normal',
    'alert_sound_high',
  ];

  /// Perform a full local state reset
  /// Returns the number of keys successfully removed
  static Future<int> clearLocalTestData() async {
    if (!kDebugMode) {
      debugPrint('⚠️ DebugResetService: Refusing to clear data in non-debug mode');
      return 0;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      int clearedCount = 0;

      for (final key in _keysToClear) {
        if (prefs.containsKey(key)) {
          final success = await prefs.remove(key);
          if (success) {
            clearedCount++;
            debugPrint('✅ DebugReset: Removed $key');
          }
        }
      }

      debugPrint('✨ DebugReset: Full local reset complete ($clearedCount items).');
      return clearedCount;
    } catch (e) {
      debugPrint('❌ DebugReset: Error clearing data: $e');
      return 0;
    }
  }
}
