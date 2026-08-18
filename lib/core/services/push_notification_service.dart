import 'dart:io';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'sound_preferences_service.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in background isolate
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint('[FCM] Background push message: ${message.messageId}');
  }
}

/// Push Notification Service
///
/// Handles Firebase Cloud Messaging (FCM) for reliable push notifications
/// when the app is closed or in background.
///
/// This service:
/// - Initializes Firebase and requests notification permissions
/// - Saves FCM tokens to Supabase for server-side push delivery
/// - Handles foreground, background, and terminated app states
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  late final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _isAppInForeground = true;

  /// Callback when notification is tapped
  Function(String? alertId)? onNotificationTapped;

  /// Initialize Firebase Messaging and request permissions
  Future<void> initialize({Function(String?)? onTap}) async {
    if (_initialized) return;

    // Initialize messaging after Firebase is ready
    _messaging = FirebaseMessaging.instance;
    onNotificationTapped = onTap;

    try {
      if (kDebugMode) debugPrint('[FCM] Initializing service...');
      
      // Set up the background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permissions (iOS)
      if (kDebugMode) debugPrint('[FCM] Requesting notification permission...');
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
      );

      if (kDebugMode) {
        debugPrint('[FCM] Push permission status: ${settings.authorizationStatus}');
      }

      // Initialize local notifications for foreground display
      await _initializeLocalNotifications();

      // Get and save FCM token
      await _saveToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // Handle notification tap (app in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _initialized = true;
      if (kDebugMode) {
        debugPrint('[FCM] PushNotificationService initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Failed to initialize push notifications: $e');
      }
    }
  }

  /// Initialize local notifications for foreground message display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Already requested via Firebase
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTapped?.call(response.payload);
      },
    );

    // Create notification channels for Android with custom sounds
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // List of all possible alert sounds in assets/sounds
        final alertSounds = [
          'low_alert_1', 'low_alert_2', 'low_alert_3',
          'normal_alert',
          'high_alert_1', 'high_alert_2',
          'alert_sound'
        ];

        for (final soundName in alertSounds) {
          final channel = AndroidNotificationChannel(
            'yuh_blockin_alert_${soundName}_v2',
            'Yuh Blockin Alerts',
            description: 'Critical parking alert notifications',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(soundName),
            enableVibration: true,
            enableLights: true,
          );
          await androidPlugin.createNotificationChannel(channel);
        }
        
        if (kDebugMode) {
          debugPrint('✅ Android: ${alertSounds.length} alert channels pre-created');
        }
      }
    }
  }

  /// Wait for APNs token on iOS with bounded retry
  Future<bool> _waitForAPNSToken() async {
    if (!Platform.isIOS) return true;

    if (kDebugMode) debugPrint('[FCM] Waiting for APNs token...');
    
    int retryCount = 0;
    const maxRetries = 20; // 20 seconds total

    while (retryCount < maxRetries) {
      try {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null) {
          if (kDebugMode) debugPrint('[FCM] APNs token available after ${retryCount}s');
          return true;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[FCM] APNs check error: $e');
      }
      
      retryCount++;
      await Future.delayed(const Duration(seconds: 1));
      if (kDebugMode && retryCount % 5 == 0) {
        debugPrint('[FCM] Still waiting for APNs... ($retryCount/${maxRetries}s)');
      }
    }

    if (kDebugMode) debugPrint('[FCM] ❌ Error: APNs token never appeared after ${maxRetries}s');
    return false;
  }

  /// Save FCM token to Supabase
  Future<void> _saveToken() async {
    try {
      // 1. identity check
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null || userId.isEmpty) {
        if (kDebugMode) debugPrint('[FCM] No user ID available yet, skipping token registration');
        return;
      }

      // 2. iOS APNs handshake
      if (Platform.isIOS) {
        final ready = await _waitForAPNSToken();
        if (!ready) return;
      }

      // 3. Get FCM registration token
      if (kDebugMode) debugPrint('[FCM] Requesting FCM registration token...');
      final token = await _messaging.getToken();
      
      if (token == null) {
        if (kDebugMode) debugPrint('[FCM] ❌ Error: FCM token is null');
        return;
      }

      // ===== FCM TOKEN FOR TESTING =====
      // Print full token so it can be copied for push notification testing
      if (kDebugMode) {
        debugPrint('');
        debugPrint('╔══════════════════════════════════════════════════════════════╗');
        debugPrint('║                    FCM TOKEN FOR TESTING                     ║');
        debugPrint('╠══════════════════════════════════════════════════════════════╣');
        debugPrint('║ $token');
        debugPrint('╚══════════════════════════════════════════════════════════════╝');
        debugPrint('');
      }

      if (kDebugMode) {
        debugPrint('[FCM] FCM token acquired');
        debugPrint('[FCM] Saving ${Platform.isIOS ? "iOS" : "Android"} token to Supabase...');
      }

      final platform = Platform.isIOS ? 'ios' : 'android';

      // 4. Supabase Persistence
      await Supabase.instance.client.from('device_tokens').upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, fcm_token');

      if (kDebugMode) {
        debugPrint('[FCM] ✅ Registration successful for User: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] ❌ Failed to save FCM token: $e');
      }
    }
  }

  /// Handle token refresh
  void _onTokenRefresh(String token) {
    if (kDebugMode) debugPrint('[FCM] Token refreshed');
    _saveToken();
  }

  /// Handle foreground message - show local notification
  void _onForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Foreground push message received: ${message.notification?.title}');
    }

    // IMPORTANT: If app is in foreground, the main app's stream listener 
    // will show the high-fidelity in-app alert banner.
    // We skip the system notification here to prevent duplicates in foreground.
    if (_isAppInForeground) {
      if (kDebugMode) {
        debugPrint('ℹ️ Push: Skipping system notification (app is in foreground)');
      }
      return;
    }

    // Show local notification since app is backgrounded but process is alive
    final notification = message.notification;
    if (notification != null) {
      // Get urgency level from message data, default to 'normal'
      final urgencyLevel = message.data['urgency_level'] ?? 'normal';
      _showLocalNotification(
        title: notification.title ?? 'New Alert',
        body: notification.body ?? 'You have a new alert',
        payload: message.data['alert_id'],
        urgencyLevel: urgencyLevel,
      );
    }
  }

  /// Handle notification tap when app was in background
  void _onMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Notification opened app: ${message.data}');
    }
    _handleNotificationTap(message);
  }

  /// Process notification tap
  void _handleNotificationTap(RemoteMessage message) {
    final alertId = message.data['alert_id'] as String?;
    onNotificationTapped?.call(alertId);
  }

  /// Show a local notification with custom alert sound based on urgency level
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String urgencyLevel = 'normal',
  }) async {
    // Get the user's selected sound for this urgency level
    final soundPrefs = SoundPreferencesService();
    final selectedSoundPath = await soundPrefs.getSoundForLevel(urgencyLevel);

    // Extract sound filename without extension for Android (res/raw)
    // e.g., 'sounds/low/low_alert_1.wav' -> 'low_alert_1'
    final soundFileName = selectedSoundPath.split('/').last.replaceAll('.wav', '');

    // For iOS, just the filename with extension
    final iosSoundFileName = selectedSoundPath.split('/').last;

    if (kDebugMode) {
      debugPrint('Push notification sound: $soundFileName (urgency: $urgencyLevel)');
    }

    // Android: Use a channel ID specific to this sound file
    // This is required because Android caches channel settings including sound
    final channelId = 'yuh_blockin_alert_$soundFileName';

    // Create the notification channel for this specific sound
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final channel = AndroidNotificationChannel(
          channelId,
          'Yuh Blockin Alerts',
          description: 'Parking alert notifications',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundFileName),
          enableVibration: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Yuh Blockin Alerts',
      channelDescription: 'Push notifications for parking alerts',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundFileName),
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      tag: payload, // Use alert_id as tag to deduplicate with BackgroundAlertService
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: iosSoundFileName,
      interruptionLevel: InterruptionLevel.active,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      payload?.hashCode ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Remove FCM token on logout
  Future<void> removeToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await Supabase.instance.client
          .from('device_tokens')
          .delete()
          .eq('fcm_token', token);

      if (kDebugMode) {
        debugPrint('FCM token removed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to remove FCM token: $e');
      }
    }
  }

  /// Update user ID and re-save token
  Future<void> updateUserId(String userId) async {
    await _saveToken();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
           settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Request notification permissions again
  Future<bool> requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Get current FCM token (for debugging)
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Update foreground status to suppress duplicate notifications
  void setAppInForeground(bool isInForeground) {
    _isAppInForeground = isInForeground;
    if (kDebugMode) {
      debugPrint('📱 Push: Foreground status updated: $_isAppInForeground');
    }
  }
}
