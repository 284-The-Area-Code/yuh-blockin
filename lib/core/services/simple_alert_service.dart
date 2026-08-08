import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../config/supabase_config.dart';

/// Simple and secure alert service
/// - Privacy-first: Only stores SHA256 hashes of license plates
/// - Real-time alerts between users
/// - Minimal complexity, maximum security
class SimpleAlertService {
  static final SimpleAlertService _instance = SimpleAlertService._internal();
  factory SimpleAlertService() => _instance;
  SimpleAlertService._internal();

  late SupabaseClient _supabase;
  bool _isInitialized = false;
  
  // Realtime stability tracking
  bool _isRealtimeConnected = false;

  // Hash cache to avoid recomputing SHA256 for the same plates
  final Map<String, String> _hashCache = {};

  /// Initialize Supabase connection
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Reuse global instance if available (initialized in main.dart)
      try {
        _supabase = Supabase.instance.client;
        if (kDebugMode) {
          debugPrint('✅ Simple Alert Service: Reusing global Supabase instance');
        }
      } catch (e) {
        // Fallback for isolated tests or if main.dart init failed
        if (kDebugMode) {
          debugPrint('🔧 Simple Alert Service: Initializing dedicated Supabase instance...');
        }
        await Supabase.initialize(
          url: SupabaseConfig.url,
          anonKey: SupabaseConfig.anonKey,
          realtimeClientOptions: const RealtimeClientOptions(
            eventsPerSecond: 10,
          ),
        );
        _supabase = Supabase.instance.client;
      }

      // 2. Optimized Authentication Liveness check
      // If we have a session that is NOT expired, we are already "logged in"
      final currentSession = _supabase.auth.currentSession;
      final isSessionValid = currentSession != null && 
          !currentSession.isExpired;

      if (isSessionValid) {
        if (kDebugMode) {
          debugPrint('🔐 Simple Alert Service: Valid session found (no re-auth needed)');
        }
      } else {
        // Only sign in anonymously if we don't have a valid session
        if (kDebugMode) {
          debugPrint('🔐 Simple Alert Service: No valid session, signing in anonymously...');
        }
        await _signInWithRetry();
      }

      // 3. Realtime Resiliency: Listen for disconnects and force reconnect
      _setupRealtimeMonitor();

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize service: $e');
      }
      rethrow;
    }
  }

  void _setupRealtimeMonitor() {
    // 1. Register state change callbacks
    _supabase.realtime.onOpen(() {
      if (kDebugMode) debugPrint('📡 Realtime Status: Connected');
      _isRealtimeConnected = true;
    });

    _supabase.realtime.onClose((_) {
      if (kDebugMode) debugPrint('📡 Realtime Status: Disconnected');
      _isRealtimeConnected = false;
      
      // Auto-reconnect on unexpected close
      if (_isInitialized) {
        Future.delayed(const Duration(seconds: 2), () {
          if (!_isRealtimeConnected) {
            if (kDebugMode) debugPrint('🔄 Realtime reconnecting...');
            // ignore: invalid_use_of_internal_member
            _supabase.realtime.connect();
          }
        });
      }
    });

    _supabase.realtime.onError((error) {
      if (kDebugMode) debugPrint('📡 Realtime Status: Error ($error)');
      _isRealtimeConnected = false;
    });
  }

  /// Explicitly refresh connection - call this on App Lifecycle 'resumed'
  void refreshConnection() {
    if (!_isInitialized) return;
    
    if (kDebugMode) {
      debugPrint('⚡ Refreshing Supabase connection (App Resumed)');
    }
    
    // Ensure auth session is valid (checks local JWT and refreshes if needed)
    final session = _supabase.auth.currentSession;
    if (session != null && session.isExpired) {
      _supabase.auth.refreshSession();
    }
    
    // Ensure realtime is connected
    if (!_isRealtimeConnected || !_supabase.realtime.isConnected) {
      // ignore: invalid_use_of_internal_member
      _supabase.realtime.connect();
    }
  }

  /// Internal retry logic for sign-in
  Future<void> _signInWithRetry() async {
    int retryCount = 0;
    const maxRetries = 3;
    bool signedIn = false;

    while (!signedIn && retryCount < maxRetries) {
      try {
        await _supabase.auth.signInAnonymously();
        signedIn = true;
        if (kDebugMode) {
          debugPrint('🔐 Signed in anonymously (Attempt ${retryCount + 1})');
        }
      } catch (authError) {
        retryCount++;
        if (kDebugMode) {
          debugPrint('⚠️ Anon sign-in attempt $retryCount failed: $authError');
        }
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: math.pow(2, retryCount - 1).toInt()));
        } else {
          // All retries failed
          throw Exception('Authentication failed after $maxRetries attempts: $authError');
        }
      }
    }
  }

  /// Create or get user ID
  Future<String> getOrCreateUser() async {
    if (kDebugMode) {
      debugPrint('🔍 getOrCreateUser() called');
    }

    _ensureInitialized();

    // Use the Supabase Auth UUID as the primary identity
    final authUserId = _supabase.auth.currentUser!.id;

    if (kDebugMode) {
      debugPrint('🔍 Identity (Auth UID): $authUserId');
      debugPrint('🔍 About to register user in profile table...');
    }

    try {
      // Upsert into users table to ensure profile exists for RLS
      await _supabase.from('users').upsert({'id': authUserId});

      if (kDebugMode) {
        debugPrint('👤 ✅ User registered: $authUserId');
      }

      return authUserId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ User registration failed: $e');
      }
      rethrow;
    }
  }

  /// Check if a user exists in the database
  /// Returns:
  /// - true: User definitely exists
  /// - false: User definitely does NOT exist
  /// - null: Error occurred (network/timeout) - existence is unknown
  Future<bool?> userExists(String userId) async {
    try {
      _ensureInitialized();

      // OPTIMIZATION: Trust local JWT claims if session is valid and matches userId
      final currentSession = _supabase.auth.currentSession;
      if (currentSession != null && !currentSession.isExpired) {
        if (currentSession.user.id == userId) {
          if (kDebugMode) {
            debugPrint('⚡ Fast-path: Verified user existence via local JWT claims');
          }
          return true;
        }
      }

      final result = await _supabase
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));

      return result != null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Network error or timeout checking user existence: $e');
      }
      // Return null to indicate we don't know if the user exists
      return null;
    }
  }

  /// Check if a plate is already registered by any user
  Future<PlateCheckResult> checkPlateAvailability({
    required String plateNumber,
    required String userId,
  }) async {
    _ensureInitialized();

    final plateHash = _hashPlate(plateNumber);

    try {
      final result = await _supabase
          .from('plates')
          .select('user_id')
          .eq('plate_hash', plateHash)
          .maybeSingle();

      if (result == null) {
        // Plate not registered - available
        return PlateCheckResult(
          isAvailable: true,
          isOwnedByCurrentUser: false,
        );
      }

      // Plate exists - check if it belongs to current user
      final existingUserId = result['user_id'] as String;
      final isOwned = existingUserId == userId;

      return PlateCheckResult(
        isAvailable: false,
        isOwnedByCurrentUser: isOwned,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Plate availability check failed: $e');
      }
      rethrow;
    }
  }

  /// Register a license plate
  /// Throws PlateAlreadyRegisteredException if plate belongs to another user
  Future<void> registerPlate({
    required String plateNumber,
    required String userId,
    String? ownershipKeyHash,
  }) async {
    _ensureInitialized();

    final plateHash = _hashPlate(plateNumber);

    // Check if plate is already registered
    final availability = await checkPlateAvailability(
      plateNumber: plateNumber,
      userId: userId,
    );

    if (!availability.isAvailable) {
      if (availability.isOwnedByCurrentUser) {
        // User already owns this plate - just return success
        if (kDebugMode) {
          debugPrint('ℹ️ Plate already registered by this user: $plateNumber');
        }
        return;
      } else {
        // Plate belongs to someone else
        if (kDebugMode) {
          debugPrint('❌ Plate already registered by another user: $plateNumber');
        }
        throw PlateAlreadyRegisteredException(
          'This license plate is already registered by another user.',
        );
      }
    }

    try {
      final insertData = {
        'user_id': userId,
        'plate_hash': plateHash,
      };

      // Add ownership key hash if provided (for account recovery)
      if (ownershipKeyHash != null) {
        insertData['ownership_key_hash'] = ownershipKeyHash;
      }

      await _supabase.from('plates').insert(insertData);

      if (kDebugMode) {
        debugPrint('✅ Registered plate: $plateNumber -> $plateHash');
        if (ownershipKeyHash != null) {
          debugPrint('🔐 Ownership key hash stored for recovery');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Registration failed: $e');
      }
      rethrow;
    }
  }

  /// Send alert to all users registered for a plate
  Future<AlertResult> sendAlert({
    required String targetPlateNumber,
    required String senderUserId,
    String? message,
    String? soundPath,
    String urgencyLevel = 'normal',
  }) async {
    _ensureInitialized();

    final plateHash = _hashPlate(targetPlateNumber);

    try {
      final response = await _supabase.rpc('send_alert', params: {
        'sender_user_id': senderUserId,
        'target_plate_hash': plateHash,
        'alert_message': message,
        'alert_sound_path': soundPath,
        'alert_urgency_level': urgencyLevel.toLowerCase(),
      });

      final result = response as Map<String, dynamic>;

      if (result['success'] == true) {
        if (kDebugMode) {
          debugPrint('📢 Alert sent to ${result['recipients']} users');
        }
        return AlertResult(
          success: true,
          recipients: result['recipients'] ?? 0,
          error: null,
          alertId: result['alert_id']?.toString(),
        );
      } else {
        return AlertResult(
          success: false,
          recipients: 0,
          error: result['error']?.toString() ?? 'Unknown error',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Alert failed: $e');
      }
      return AlertResult(
        success: false,
        recipients: 0,
        error: e.toString(),
      );
    }
  }

  /// Send a reminder alert directly to a specific user
  Future<AlertResult> sendReminderAlert({
    required String receiverUserId,
    required String senderUserId,
    required String plateHash,
    String? message,
  }) async {
    _ensureInitialized();

    try {
      // Insert directly into alerts table
      final response = await _supabase.from('alerts').insert({
        'sender_id': senderUserId,
        'receiver_id': receiverUserId,
        'plate_hash': plateHash,
        'message': message ?? '⏰ Reminder: Still waiting',
      }).select().single();

      if (kDebugMode) {
        debugPrint('📢 Reminder sent to user: $receiverUserId');
      }

      return AlertResult(
        success: true,
        recipients: 1,
        error: null,
        alertId: response['id']?.toString(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Reminder failed: $e');
      }
      return AlertResult(
        success: false,
        recipients: 0,
        error: e.toString(),
      );
    }
  }

  /// Get my registered plates
  Future<List<String>> getMyPlates(String userId) async {
    _ensureInitialized();

    try {
      final response = await _supabase
          .from('plates')
          .select('plate_hash')
          .eq('user_id', userId);

      return (response as List)
          .map((row) => row['plate_hash'] as String)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get plates: $e');
      }
      return [];
    }
  }

  /// Get real-time alerts stream for user
  Stream<Alert> getAlertsStream(String userId) {
    _ensureInitialized();

    return _supabase
        .from('alerts')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', userId)
        .expand((data) => data) // Flatten the list of alerts
        .map((item) => Alert.fromJson(item)); // Convert each item to Alert
  }

  /// Mark alert as read
  Future<void> markAlertRead(String alertId) async {
    _ensureInitialized();

    await _supabase
        .from('alerts')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', alertId);
  }

  /// Send response to an alert
  Future<bool> sendResponse({
    required String alertId,
    required String response,
    String? responseMessage,
  }) async {
    _ensureInitialized();

    try {
      await _supabase
          .from('alerts')
          .update({
            'response': response,
            'response_message': responseMessage,
            'response_at': DateTime.now().toIso8601String(),
            'read_at': DateTime.now().toIso8601String(), // Also mark as read
          })
          .eq('id', alertId);

      if (kDebugMode) {
        debugPrint('✅ Response sent: $response for alert: $alertId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to send response: $e');
      }
      return false;
    }
  }

  /// Get real-time stream of alerts I've sent (to see responses)
  Stream<List<Alert>> getSentAlertsStream(String userId) {
    _ensureInitialized();

    return _supabase
        .from('alerts')
        .stream(primaryKey: ['id'])
        .eq('sender_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((item) => Alert.fromJson(item)).toList());
  }

  /// Get snapshot of alerts I've sent (useful for syncing acknowledgments)
  Future<List<Alert>> getSentAlerts(String userId) async {
    _ensureInitialized();

    try {
      final response = await _supabase
          .from('alerts')
          .select()
          .eq('sender_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((item) => Alert.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting sent alerts: $e');
      }
      return [];
    }
  }

  /// Delete a registered plate
  Future<void> deletePlate({
    required String plateNumber,
    required String userId,
  }) async {
    _ensureInitialized();

    final plateHash = _hashPlate(plateNumber);

    await _supabase
        .from('plates')
        .delete()
        .eq('user_id', userId)
        .eq('plate_hash', plateHash);

    if (kDebugMode) {
      debugPrint('🗑️ Deleted plate: $plateNumber');
    }
  }

  /// Delete a single alert by ID
  Future<bool> deleteAlert(String alertId) async {
    _ensureInitialized();

    try {
      await _supabase.from('alerts').delete().eq('id', alertId);

      if (kDebugMode) {
        debugPrint('🗑️ Deleted alert: $alertId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to delete alert: $e');
      }
      return false;
    }
  }

  /// Delete all received alerts for a user
  Future<int> deleteReceivedAlerts(String userId) async {
    _ensureInitialized();

    try {
      final response = await _supabase
          .from('alerts')
          .delete()
          .eq('receiver_id', userId)
          .select();

      final count = (response as List).length;
      if (kDebugMode) {
        debugPrint('🗑️ Deleted $count received alerts for user: $userId');
      }
      return count;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to delete received alerts: $e');
      }
      return 0;
    }
  }

  /// Delete all sent alerts for a user
  Future<int> deleteSentAlerts(String userId) async {
    _ensureInitialized();

    try {
      final response = await _supabase
          .from('alerts')
          .delete()
          .eq('sender_id', userId)
          .select();

      final count = (response as List).length;
      if (kDebugMode) {
        debugPrint('🗑️ Deleted $count sent alerts for user: $userId');
      }
      return count;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to delete sent alerts: $e');
      }
      return 0;
    }
  }

  /// Delete all alerts (both sent and received) for a user
  Future<int> deleteAllAlerts(String userId) async {
    _ensureInitialized();

    try {
      // Delete received alerts
      final receivedResponse = await _supabase
          .from('alerts')
          .delete()
          .eq('receiver_id', userId)
          .select();

      // Delete sent alerts
      final sentResponse = await _supabase
          .from('alerts')
          .delete()
          .eq('sender_id', userId)
          .select();

      final totalCount = (receivedResponse as List).length + (sentResponse as List).length;
      if (kDebugMode) {
        debugPrint('🗑️ Deleted $totalCount total alerts for user: $userId');
      }
      return totalCount;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to delete all alerts: $e');
      }
      return 0;
    }
  }

  // Private helpers

  String _hashPlate(String plateNumber) {
    final normalized = plateNumber.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

    // Check cache first to avoid recomputing hash
    if (_hashCache.containsKey(normalized)) {
      return _hashCache[normalized]!;
    }

    final bytes = utf8.encode(normalized);
    final hash = sha256.convert(bytes).toString();

    // Cache the hash (limit cache size to prevent memory issues)
    if (_hashCache.length > 100) {
      _hashCache.remove(_hashCache.keys.first);
    }
    _hashCache[normalized] = hash;

    return hash;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('Service not initialized');
    }
  }
}

// Simple data models

class AlertResult {
  final bool success;
  final int recipients;
  final String? error;
  final String? alertId; // Added for unacknowledged alert tracking

  AlertResult({
    required this.success,
    required this.recipients,
    this.error,
    this.alertId,
  });
}

class Alert {
  final String id;
  final String senderId;
  final String receiverId;
  final String plateHash;
  final String? message;
  final String? soundPath; // Sound to play on receiver's phone
  final String urgencyLevel; // low, normal, high - determines notification sound
  final String? response; // moving_now, 5_minutes, cant_move, wrong_car
  final String? responseMessage; // optional custom response
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? responseAt;

  Alert({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.plateHash,
    this.message,
    this.soundPath,
    this.urgencyLevel = 'normal',
    this.response,
    this.responseMessage,
    required this.createdAt,
    this.readAt,
    this.responseAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      plateHash: json['plate_hash'],
      message: json['message'],
      soundPath: json['sound_path'],
      urgencyLevel: json['urgency_level'] ?? 'normal',
      response: json['response'],
      responseMessage: json['response_message'],
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      responseAt: json['response_at'] != null ? DateTime.parse(json['response_at']) : null,
    );
  }

  /// Check if alert has been responded to
  bool get hasResponse => response != null;

  /// Create a copy of Alert with updated fields
  Alert copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? plateHash,
    String? message,
    String? soundPath,
    String? urgencyLevel,
    String? response,
    String? responseMessage,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? responseAt,
  }) {
    return Alert(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      plateHash: plateHash ?? this.plateHash,
      message: message ?? this.message,
      soundPath: soundPath ?? this.soundPath,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      response: response ?? this.response,
      responseMessage: responseMessage ?? this.responseMessage,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      responseAt: responseAt ?? this.responseAt,
    );
  }

  /// Get human-readable response text
  String get responseText {
    switch (response) {
      case 'moving_now':
        return 'Moving now';
      case '5_minutes':
        return 'Give me 5 minutes';
      case 'cant_move':
        return 'Can\'t move right now';
      case 'wrong_car':
        return 'Wrong car';
      default:
        return 'No response';
    }
  }
}

/// Result of checking plate availability
class PlateCheckResult {
  final bool isAvailable;
  final bool isOwnedByCurrentUser;

  PlateCheckResult({
    required this.isAvailable,
    required this.isOwnedByCurrentUser,
  });
}

/// Exception thrown when trying to register a plate that belongs to another user
class PlateAlreadyRegisteredException implements Exception {
  final String message;

  PlateAlreadyRegisteredException(this.message);

  @override
  String toString() => message;
}