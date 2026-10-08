import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Every Android notification channel the app uses, in one place.
///
/// v3: all channels are created with showBadge: false, so the launcher never
/// draws a counter on the app icon (Samsung One UI and others count
/// notifications from badge-enabled channels). Android never lets an app
/// change an existing channel's badge setting, so the v3 channels have new
/// ids and the old ones are deleted by [deleteRetired].
///
/// The alerts-fcm Edge Function sends pushes on [alert] channels, so its
/// channel_id must use the same `_v3` suffix.
class NotificationChannels {
  NotificationChannels._();

  /// Sound files in android/app/src/main/res/raw, one alert channel each.
  static const List<String> alertSounds = [
    'low_alert_1', 'low_alert_2', 'low_alert_3',
    'normal_alert',
    'high_alert_1', 'high_alert_2',
    'alert_sound',
  ];

  /// Alert channel for one sound.
  static String alert(String soundFileName) => 'yuh_blockin_alert_${soundFileName}_v3';

  /// General alert channel (alert_sound).
  static const String general = 'yuh_blockin_alerts_v3';

  /// Fallbacks used when posting on a sound channel fails.
  static const String safeFallback = 'yuh_blockin_alerts_safe_v3';
  static const String systemFallback = 'yuh_blockin_alerts_system_v3';

  /// App warnings such as "No Internet Connection".
  static const String warnings = 'yuh_blockin_warnings_v3';

  /// The background service's ongoing "Ready for alerts" notification. Low
  /// importance: no sound, no pop-up, and not counted anywhere.
  static const String service = 'yuh_blockin_service';

  /// Channel ids from before v3, all created with the badge on.
  static List<String> get retired => [
        'yuh_blockin_alerts',
        'yuh_blockin_alerts_safe',
        'yuh_blockin_alerts_system',
        'yuh_blockin_warnings',
        for (final sound in alertSounds) ...[
          'yuh_blockin_alert_$sound',
          'yuh_blockin_alert_${sound}_v2',
        ],
      ];

  /// Deletes the pre-v3 channels. Safe to call on every start: deleting a
  /// channel that doesn't exist does nothing.
  static Future<void> deleteRetired(AndroidFlutterLocalNotificationsPlugin plugin) async {
    for (final id in retired) {
      try {
        await plugin.deleteNotificationChannel(id);
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Could not delete channel $id: $e');
      }
    }
  }
}
