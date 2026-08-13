import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';
import '../../config/supabase_config.dart';
import 'user_alias_service.dart';

// Regex for emoji extraction (shared with main app)
final RegExp _emojiRegex = RegExp(
    '[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
    unicode: true);

/// Background Alert Service
///
/// ARCHITECTURE NOTES:
/// - This service runs as a SEPARATE ISOLATE (Android foreground service)
/// - It works independently from the main app's NotificationService
/// - Purpose: Ensure alerts are received even when app is KILLED or in deep background
///
/// RELATIONSHIP TO NotificationService:
/// - NotificationService: Handles notifications when app is running (foreground/light background)
/// - BackgroundAlertService: Handles notifications when app is fully killed or suspended
/// - Both use the same notification channel ID to prevent duplicates
/// - The same alert ID is used (alertId.hashCode) to deduplicate system notifications
///
/// This dual-service approach ensures reliable alert delivery across all app states.
class BackgroundAlertService {
  static final BackgroundAlertService _instance = BackgroundAlertService._internal();
  factory BackgroundAlertService() => _instance;
  BackgroundAlertService._internal();

  static const String _userIdKey = 'user_id';
  static const String _notificationChannelId = 'yuh_blockin_alerts';
  static const String _notificationChannelName = 'Yuh Blockin Alerts';

  // Helper for platform checking that works on web
  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Initialize and start the background service
  Future<void> initializeService() async {
    if (kIsWeb) return;

    final service = FlutterBackgroundService();

    // Configure notification channel for foreground service with custom sound
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: 'Critical parking alert notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('alert_sound'),
      enableLights: true,
      ledColor: Color(0xFF4CAF50),
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (_isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        autoStartOnBoot: true,
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: 'Yuh Blockin',
        initialNotificationContent: 'Ready for alerts',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// Start the background service
  Future<void> startService() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
  }

  /// Stop the background service
  Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  /// Check if service is running
  Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  /// Update user ID for alert monitoring
  Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);

    // Notify running service of user change
    final service = FlutterBackgroundService();
    service.invoke('updateUser', {'userId': userId});
  }
}

/// iOS background handler
/// Note: iOS has strict background execution limits (~30 seconds)
/// For reliable background alerts on iOS, push notifications (FCM/APNs) are required
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
  } catch (e) {
    debugPrint('Background service registration warning (iOS): $e');
  }

  // On iOS, we have limited background execution time
  // The main onStart handler will be called, but may be suspended by iOS
  // For reliable delivery when app is backgrounded on iOS, implement push notifications
  return true;
}

/// Global handler for notification button taps (actions) in background
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) async {
  final actionId = response.actionId;
  final alertId = response.payload;

  if (actionId == null || alertId == null) return;
  if (actionId == 'respond') return; // Ignore legacy generic respond button

  if (kDebugMode) {
    debugPrint('📩 Background Action Received: $actionId for alert $alertId');
  }

  try {
    // 1. Initialize Supabase in this response isolate
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
    } catch (_) {
      // Already initialized or fallback
    }

    final supabase = Supabase.instance.client;

    // 2. Send response to database
    final timestamp = DateTime.now().toIso8601String();
    await supabase
        .from('alerts')
        .update({
          'response': actionId,
          'response_at': timestamp,
          'read_at': timestamp,
        })
        .eq('id', alertId);

    if (kDebugMode) {
      debugPrint('✅ Background response sent successfully: $actionId');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Failed to send background response: $e');
    }
  }
}

/// Main background service entry point
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Ensure Flutter bindings are initialized
  try {
    DartPluginRegistrant.ensureInitialized();
  } catch (e) {
    debugPrint('Background service registration warning: $e');
  }

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await notificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: onBackgroundNotificationResponse,
    onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationResponse,
  );

  // Get stored user ID
  final prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('user_id');

  StreamSubscription? alertSubscription;
  SupabaseClient? supabase;
  Timer? reconnectTimer;
  
  // Track if main app is in foreground to suppress system notifications
  bool isAppInForeground = false;

  // Track shown alert IDs to prevent duplicate notifications
  final Set<String> shownAlertIds = {};

  // Initialize Supabase
  Future<SupabaseClient?> initializeSupabase() async {
    try {
      // 1. Check if already initialized in this isolate
      try {
        return Supabase.instance.client;
      } catch (_) {}

      // 2. Background isolates need their own initialization
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        realtimeClientOptions: const RealtimeClientOptions(
          eventsPerSecond: 10,
        ),
      );
      
      final client = Supabase.instance.client;
      if (kDebugMode) {
        debugPrint('Background service: Supabase initialized');
      }
      return client;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Background service: Supabase init error: $e');
      }
      return null;
    }
  }

  supabase = await initializeSupabase();

  // Sign in anonymously for authenticated role
  if (supabase != null && supabase.auth.currentUser == null) {
    try {
      await supabase.auth.signInAnonymously();
      if (kDebugMode) {
        debugPrint('Background service: Signed in anonymously');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Background service: Anonymous sign-in failed: $e');
      }
    }
  }

  /// Subscribe to alerts for user with auto-reconnect
  void subscribeToAlerts(String uid) {
    alertSubscription?.cancel();
    reconnectTimer?.cancel();

    if (supabase == null) {
      if (kDebugMode) {
        debugPrint('Background service: No Supabase client, cannot subscribe');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('Background service: Subscribing to alerts for user: $uid');
    }

    alertSubscription = supabase
        .from('alerts')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', uid)
        .listen((data) async {
          for (final alert in data) {
            final alertId = alert['id'] as String?;
            if (alertId == null) continue;

            // Skip if already shown
            if (shownAlertIds.contains(alertId)) continue;

            // Check if this is a new unread alert
            if (alert['read_at'] == null && alert['response'] == null && alert['push_sent'] != true) {
              // Use UTC for all background comparisons to avoid clock drift issues
              final createdAt = DateTime.tryParse(alert['created_at'] ?? '')?.toUtc();
              final now = DateTime.now().toUtc();

              // INCREASED WINDOW: Notify for alerts created in the last 15 minutes (was 60s)
              if (createdAt != null && now.difference(createdAt).inMinutes < 15) {
                shownAlertIds.add(alertId);

                if (kDebugMode) {
                  debugPrint('🔔 Background: Processing recent alert $alertId');
                }

                // Limit cache size
                if (shownAlertIds.length > 100) {
                  shownAlertIds.remove(shownAlertIds.first);
                }

                // Get urgency level and sender from alert data
                final urgencyLevel = alert['urgency_level'] ?? 'normal';
                final senderId = alert['sender_id'] as String?;

                // UNIFIED RULE: Only show system notification if app is NOT in foreground
                if (!isAppInForeground) {
                  // Fetch alias in background isolate
                  String senderAlias = 'Someone';
                  if (senderId != null) {
                    try {
                      senderAlias = await UserAliasService().getAliasForUser(senderId);
                    } catch (e) {
                      if (kDebugMode) debugPrint('⚠️ Background: Failed to get alias: $e');
                    }
                  }

                  await _showAlertNotification(
                    notificationsPlugin,
                    alertId,
                    alert['message'] ?? 'Please move your vehicle',
                    senderAlias: senderAlias,
                    urgencyLevel: urgencyLevel,
                    alertSoundPath: alert['sound_path'] as String?,
                  );
                } else {
                  if (kDebugMode) {
                    debugPrint('ℹ️ Background: Skipping system notification (app is in foreground)');
                  }
                }
              } else if (createdAt != null) {
                if (kDebugMode) {
                  debugPrint('ℹ️ Background: Alert $alertId is too old (${now.difference(createdAt).inMinutes} min)');
                }
                shownAlertIds.add(alertId);
              }
            }
          }
        }, onError: (error) {
          if (kDebugMode) {
            debugPrint('Background service: Alert stream error: $error');
          }
          // Auto-reconnect after error
          reconnectTimer?.cancel();
          reconnectTimer = Timer(const Duration(seconds: 5), () {
            if (userId != null && userId!.isNotEmpty) {
              subscribeToAlerts(userId!);
            }
          });
        });
  }

  // Initial subscription if user ID exists
  if (userId != null && userId.isNotEmpty) {
    subscribeToAlerts(userId);
  }

  // Periodic keep-alive to ensure connection stays active
  Timer.periodic(const Duration(minutes: 5), (timer) async {
    // Refresh user ID from prefs in case it changed
    final currentUserId = prefs.getString('user_id');
    if (currentUserId != null && currentUserId != userId) {
      userId = currentUserId;
      subscribeToAlerts(userId!);
    }
  });

  // Handle user updates from main app
  service.on('updateUser').listen((event) {
    if (event != null && event['userId'] != null) {
      userId = event['userId'];
      subscribeToAlerts(userId!);
    }
  });

  // Handle foreground/background status updates from main app
  service.on('setForeground').listen((event) {
    if (event != null && event['foreground'] != null) {
      isAppInForeground = event['foreground'] as bool;
      if (kDebugMode) {
        debugPrint('📱 Background: App foreground status updated: $isAppInForeground');
      }
    }
  });

  // Handle stop request
  service.on('stopService').listen((event) {
    reconnectTimer?.cancel();
    alertSubscription?.cancel();
    service.stopSelf();
  });
}

/// Get receiver's selected sound path for a given urgency level
String _getReceiverSoundForLevel(SharedPreferences prefs, String level) {
  switch (level.toLowerCase()) {
    case 'low':
      return prefs.getString('alert_sound_low') ?? 'sounds/low/low_alert_1.wav';
    case 'high':
      return prefs.getString('alert_sound_high') ?? 'sounds/high/high_alert_1.wav';
    default: // normal
      return prefs.getString('alert_sound_normal') ?? 'sounds/normal/normal_alert.wav';
  }
}

/// Show alert notification with premium vibration pattern
/// urgencyLevel: 'low', 'normal', 'high' - determines which sound to play
Future<void> _showAlertNotification(
  FlutterLocalNotificationsPlugin plugin,
  String alertId,
  String message, {
  required String senderAlias,
  String urgencyLevel = 'normal',
  String? alertSoundPath,
}) async {
  // Get the user's selected sound for this urgency level from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  String soundFileName;
  String iosSoundFileName;

  // Use sender's sound if provided, otherwise use receiver's preference
  final selectedSoundPath = alertSoundPath ?? _getReceiverSoundForLevel(prefs, urgencyLevel);
  
  soundFileName = selectedSoundPath.split('/').last.replaceAll('.wav', '');
  iosSoundFileName = selectedSoundPath.split('/').last;

  if (kDebugMode) {
    debugPrint('Background notification sound: $soundFileName (urgency: $urgencyLevel)');
    debugPrint('iOS sound file: $iosSoundFileName');
  }

  // Android: Use a channel ID that includes action support and sound
  // IMPORTANT: We append '_v2' to the channel ID to force Android to re-register the channel
  // and show the new action buttons (Moving Now, etc.) if they were cached previously.
  final channelId = 'yuh_blockin_alert_${soundFileName}_v2';

  // Create the notification channel for this specific sound (Android only)
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final androidPlugin = plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final channel = AndroidNotificationChannel(
        channelId,
        'Yuh Blockin Alerts',
        description: 'Parking alert notifications with actions',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(soundFileName),
        enableVibration: true,
        enableLights: true,
        ledColor: const Color(0xFF4CAF50),
      );
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  // Premium rhythm vibration pattern: da-da-da-DAAAA (attention-grabbing)
  final vibrationPattern = Int64List.fromList([
    0, 200, 100, 200, 100, 200, 200, 600, 300, 200, 100, 200, 100, 600,
  ]);

  // Extract emoji from message for title visibility
  String? emoji;
  final match = _emojiRegex.firstMatch(message);
  if (match != null) {
    emoji = match.group(0);
  }
  
  final title = emoji != null ? '$emoji Move Request' : 'New Move Request';
  
  // DEDUPLICATE EMOJIS: If we put emoji in title, remove it from the start of message
  String body = message;
  if (emoji != null && body.startsWith(emoji)) {
    body = body.replaceFirst(emoji, '').trim();
  }
  
  // If body is empty after removing emoji, use default message with Alias
  if (body.isEmpty) {
    body = '$senderAlias needs you to move.';
  } else {
    // Append alias if not present
    body = '$senderAlias: $body';
  }

  final androidDetails = AndroidNotificationDetails(
    channelId,
    'Yuh Blockin Alerts',
    channelDescription: 'Critical parking alert notifications',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound(soundFileName),
    enableVibration: true,
    vibrationPattern: vibrationPattern,
    enableLights: true,
    ledColor: const Color(0xFF4CAF50),
    ledOnMs: 500,
    ledOffMs: 250,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    ticker: title,
    tag: alertId, // Use alert_id as tag to deduplicate with FCM
    styleInformation: BigTextStyleInformation(
      body,
      contentTitle: title,
      summaryText: "Yuh Blockin'",
    ),
    actions: [
      const AndroidNotificationAction(
        'moving_now',
        'Moving Now',
        showsUserInterface: true,
        cancelNotification: true,
      ),
      const AndroidNotificationAction(
        '5_minutes',
        '5 Minutes',
        showsUserInterface: true,
        cancelNotification: true,
      ),
      const AndroidNotificationAction(
        'cant_move',
        "Can't Move",
        showsUserInterface: true,
        cancelNotification: true,
      ),
    ],
  );

  // iOS notification details with custom sound
  final iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: iosSoundFileName,
    interruptionLevel: InterruptionLevel.active,
    threadIdentifier: 'yuh_blockin_alerts',
    categoryIdentifier: 'yuh_blockin_alerts_category',
  );

  final details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  // CRITICAL FIX: Trigger vibration BEFORE attempting notification
  // This ensures even if the notification engine has a slight delay or sound failure,
  // the user gets immediate haptic feedback.
  await _vibrateRhythm();

  try {
    await plugin.show(
      alertId.hashCode,
      title,
      body,
      details,
      payload: alertId,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ Background notification failed with custom sound: $e');
      debugPrint('🔄 Falling back to known-good alert_sound...');
    }
    
    // FALLBACK 1: Try using the standard 'alert_sound' we know exists
    try {
      final fallbackDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'yuh_blockin_alerts_safe',
          'Yuh Blockin Alerts',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('alert_sound'),
          enableVibration: true,
          actions: androidDetails.actions,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          sound: 'alert_sound.wav',
        ),
      );
      
      await plugin.show(
        alertId.hashCode,
        title,
        body,
        fallbackDetails,
        payload: alertId,
      );
    } catch (e2) {
      // FALLBACK 2: Standard system notification
      if (kDebugMode) debugPrint('🔄 Falling back to system default...');
      
      final systemDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'yuh_blockin_alerts_system',
          'Yuh Blockin Alerts',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          actions: androidDetails.actions,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      );
      
      await plugin.show(
        alertId.hashCode,
        title,
        body,
        systemDetails,
        payload: alertId,
      );
    }
  }
}

/// Premium rhythm vibration pattern
/// Pattern: quick-quick-quick-LONG, quick-quick-LONG
Future<void> _vibrateRhythm() async {
  try {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    final hasAmplitude = await Vibration.hasAmplitudeControl();

    if (hasAmplitude == true) {
      // With amplitude control - more impactful vibration
      await Vibration.vibrate(
        pattern: [
          0,    // Start
          150,  // Quick
          80,   // Pause
          150,  // Quick
          80,   // Pause
          150,  // Quick
          150,  // Pause
          500,  // LONG
          200,  // Pause
          150,  // Quick
          80,   // Pause
          150,  // Quick
          150,  // Pause
          500,  // LONG
        ],
        intensities: [
          0, 200, 0, 200, 0, 200, 0, 255, 0, 200, 0, 200, 0, 255,
        ],
      );
    } else {
      // Without amplitude control
      await Vibration.vibrate(
        pattern: [
          0, 150, 80, 150, 80, 150, 150, 500, 200, 150, 80, 150, 150, 500,
        ],
      );
    }

    // Second wave after a pause for extra urgency
    await Future.delayed(const Duration(milliseconds: 800));

    await Vibration.vibrate(
      pattern: [0, 300, 150, 300, 150, 600],
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Background vibration error: $e');
    }
  }
}
