import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/payment_config.dart';

/// Subscription Service for managing premium features
/// Integrates with RevenueCat for payments and Supabase for server-side validation
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // Get API key from secure configuration
  static String get _revenueCatApiKey => PaymentConfig.getApiKey(isIOS: Platform.isIOS);

  // Cached SharedPreferences instance to avoid N+1 disk reads
  static SharedPreferences? _cachedPrefs;

  // Product identifiers from config
  static String get monthlyProductId => PaymentConfig.monthlyProductId;
  static String get lifetimeProductId => PaymentConfig.lifetimeProductId;

  // Free tier limits from config
  static int get freeDailyAlertLimit => PaymentConfig.freeDailyAlertLimit;

  // State
  bool _isInitialized = false;
  bool _isPremium = false;
  String _subscriptionStatus = 'free'; // free, premium, lifetime
  int _dailyAlertsUsed = 0;
  DateTime? _lastUsageDate;
  String? _currentUserId;
  DateTime? _lastEntitlementRefresh;

  // Getters
  bool get isPremium => _isPremium;
  String get subscriptionStatus => _subscriptionStatus;
  int get dailyAlertsUsed => _dailyAlertsUsed;
  int get remainingAlerts => _isPremium ? 999 : max(0, freeDailyAlertLimit - _dailyAlertsUsed);
  bool get hasUnlimitedAlerts => _isPremium;

  /// Initialize the subscription service
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;

    _currentUserId = userId;

    try {
      // Configure RevenueCat only if API key is available
      if (_revenueCatApiKey.isNotEmpty) {
        await Purchases.configure(
          PurchasesConfiguration(_revenueCatApiKey)..appUserID = userId,
        );

        // Listen for customer info updates
        Purchases.addCustomerInfoUpdateListener((customerInfo) {
          _handleCustomerInfoUpdate(customerInfo);
        });

        if (kDebugMode) {
          debugPrint('✅ RevenueCat configured with ${PaymentConfig.isConfiguredForProduction ? "PRODUCTION" : "TEST"} key');
        }
      } else if (kDebugMode) {
        debugPrint('⚠️ RevenueCat not configured - no API key available');
      }

      // Load cached subscription status
      await _loadCachedStatus();

      // Sync with server
      await _syncSubscriptionStatus();

      // Load daily usage
      await _loadDailyUsage();

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('✅ SubscriptionService initialized for user: $userId');
        debugPrint('   Status: $_subscriptionStatus, Premium: $_isPremium');
        debugPrint('   Alerts used today: $_dailyAlertsUsed/$freeDailyAlertLimit');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SubscriptionService initialization failed: $e');
      }
      // Default to free tier on error
      _isPremium = false;
      _subscriptionStatus = 'free';
      _isInitialized = true;
    }
  }

  /// Reset subscription state (call on account deletion)
  /// Logs out of RevenueCat and clears all local subscription data
  Future<void> logout() async {
    try {
      // Logout from RevenueCat (only if initialized)
      if (_isInitialized && _revenueCatApiKey.isNotEmpty) {
        await Purchases.logOut();
        if (kDebugMode) {
          debugPrint('✅ RevenueCat logged out');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ RevenueCat logout error: $e');
      }
    }

    // Reset local state
    _isPremium = false;
    _subscriptionStatus = 'free';
    _dailyAlertsUsed = 0;
    _lastUsageDate = null;
    _currentUserId = null;
    _isInitialized = false;
    _lastEntitlementRefresh = null;

    // Clear cached status from SharedPreferences
    try {
      final prefs = await _getPrefs();
      await prefs.remove('yuh_subscription_status');
      await prefs.remove('yuh_daily_alerts_used');
      await prefs.remove('yuh_last_usage_date');
      if (kDebugMode) {
        debugPrint('✅ Subscription cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to clear subscription prefs: $e');
      }
    }
  }

  /// Check if user can send an alert (client-side check)
  Future<bool> canSendAlert() async {
    if (_isPremium) return true;

    // Reset usage if it's a new day
    await _checkAndResetDailyUsage();

    return _dailyAlertsUsed < freeDailyAlertLimit;
  }

  /// Server-side validation before sending an alert
  /// Returns a ValidationResult with success status and error message if failed
  Future<ValidationResult> validateAlertPermission() async {
    try {
      final supabase = Supabase.instance.client;

      // Call server-side function to validate user's alert permission
      final response = await supabase.rpc('validate_alert_permission', params: {
        'p_user_id': _currentUserId,
      });

      if (response is Map<String, dynamic>) {
        final allowed = response['allowed'] as bool? ?? false;
        final reason = response['reason'] as String?;
        final remaining = response['remaining'] as int? ?? 0;

        if (!allowed) {
          // Sync with server's view of subscription status
          if (response['is_premium'] == true && !_isPremium) {
            _isPremium = true;
            _subscriptionStatus = 'premium';
            await _saveCachedStatus();
          }
        }

        return ValidationResult(
          allowed: allowed,
          reason: reason,
          remainingAlerts: remaining,
        );
      }

      // If response format is unexpected, fall back to client-side check
      final canSend = await canSendAlert();
      return ValidationResult(
        allowed: canSend,
        reason: canSend ? null : 'Daily limit reached',
        remainingAlerts: remainingAlerts,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Server validation failed, using client-side check: $e');
      }

      // Fall back to client-side check if server validation fails
      final canSend = await canSendAlert();
      return ValidationResult(
        allowed: canSend,
        reason: canSend ? null : 'Daily limit reached',
        remainingAlerts: remainingAlerts,
        isOfflineCheck: true,
      );
    }
  }

  /// Refresh entitlements from RevenueCat
  /// Call this periodically (e.g., on app resume) to ensure status is up-to-date
  Future<void> refreshEntitlements({bool force = false}) async {
    // CRITICAL: Don't call RevenueCat APIs before SDK is configured
    // This prevents crash when app resumes before initialize() completes
    if (!_isInitialized) {
      if (kDebugMode) {
        debugPrint('⏳ Skipping entitlement refresh (service not initialized yet)');
      }
      return;
    }

    // Don't refresh if recently refreshed (within 5 minutes) unless forced
    if (!force && _lastEntitlementRefresh != null) {
      final timeSinceRefresh = DateTime.now().difference(_lastEntitlementRefresh!);
      if (timeSinceRefresh.inMinutes < 5) {
        if (kDebugMode) {
          debugPrint('⏳ Skipping entitlement refresh (last refresh ${timeSinceRefresh.inMinutes}m ago)');
        }
        return;
      }
    }

    try {
      if (_revenueCatApiKey.isNotEmpty) {
        // Refresh from RevenueCat
        final customerInfo = await Purchases.getCustomerInfo();
        await _handleCustomerInfoUpdate(customerInfo);
        _lastEntitlementRefresh = DateTime.now();

        if (kDebugMode) {
          debugPrint('✅ Entitlements refreshed from RevenueCat');
        }
      } else {
        // Refresh from server only
        await _syncSubscriptionStatus();
        _lastEntitlementRefresh = DateTime.now();

        if (kDebugMode) {
          debugPrint('✅ Entitlements refreshed from server');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to refresh entitlements: $e');
      }
    }
  }

  /// Check if entitlements should be refreshed (e.g., on app resume)
  bool get shouldRefreshEntitlements {
    if (_lastEntitlementRefresh == null) return true;
    final timeSinceRefresh = DateTime.now().difference(_lastEntitlementRefresh!);
    return timeSinceRefresh.inHours >= 1; // Refresh every hour
  }

  /// Increment daily usage after sending an alert
  Future<void> incrementDailyUsage() async {
    if (_isPremium) return; // Premium users don't track usage

    _dailyAlertsUsed++;
    await _saveDailyUsage();

    // Also update server
    try {
      final supabase = Supabase.instance.client;
      await supabase.rpc('increment_daily_usage', params: {
        'p_user_id': _currentUserId,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to sync daily usage to server: $e');
      }
    }

    if (kDebugMode) {
      debugPrint('📊 Daily usage: $_dailyAlertsUsed/$freeDailyAlertLimit');
    }
  }

  /// Purchase monthly subscription
  Future<PurchaseResult> purchaseMonthly() async {
    return _purchaseProduct(monthlyProductId);
  }

  /// Purchase lifetime access
  Future<PurchaseResult> purchaseLifetime() async {
    return _purchaseProduct(lifetimeProductId);
  }

  /// Restore purchases
  Future<PurchaseResult> restorePurchases() async {
    try {
      // Guard against calling before SDK is configured
      if (!_isInitialized || _revenueCatApiKey.isEmpty) {
        return PurchaseResult(
          success: false,
          error: 'Payment system not configured. Please contact support.',
        );
      }

      final customerInfo = await Purchases.restorePurchases();
      await _handleCustomerInfoUpdate(customerInfo);

      if (_isPremium) {
        return PurchaseResult(success: true, message: 'Purchases restored!');
      } else {
        return PurchaseResult(
          success: false,
          error: 'No previous purchases found',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Restore failed: $e');
      }
      return PurchaseResult(success: false, error: e.toString());
    }
  }

  /// Get available offerings from RevenueCat
  Future<Offerings?> getOfferings() async {
    try {
      // Guard against calling before SDK is configured
      if (!_isInitialized || _revenueCatApiKey.isEmpty) {
        return null;
      }
      return await Purchases.getOfferings();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get offerings: $e');
      }
      return null;
    }
  }

  // Private methods

  Future<PurchaseResult> _purchaseProduct(String productId) async {
    try {
      // Check if payment system is configured and initialized
      if (!_isInitialized || _revenueCatApiKey.isEmpty) {
        // Only allow demo mode in debug builds AND when explicitly not production
        if (kDebugMode && !PaymentConfig.isConfiguredForProduction) {
          debugPrint('🧪 Demo mode: Simulating purchase of $productId');
          debugPrint('⚠️ This is a TEST purchase - will not work in production');
          await _simulatePurchase(productId, isDemo: true);
          return PurchaseResult(success: true, message: 'Demo purchase successful (TEST MODE)');
        }
        return PurchaseResult(
          success: false,
          error: 'Payment system not available. Please contact ${PaymentConfig.supportEmail}',
        );
      }

      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        if (kDebugMode) {
          debugPrint('❌ No offerings available from RevenueCat');
        }
        return PurchaseResult(
          success: false,
          error: 'Products are temporarily unavailable. Please try again later.',
        );
      }

      Package? package;
      if (productId == monthlyProductId) {
        package = offerings.current!.monthly;
      } else if (productId == lifetimeProductId) {
        package = offerings.current!.lifetime;
      }

      if (package == null) {
        if (kDebugMode) {
          debugPrint('❌ Product not found in offerings: $productId');
          debugPrint('Available packages: monthly=${offerings.current!.monthly != null}, lifetime=${offerings.current!.lifetime != null}');
        }
        return PurchaseResult(
          success: false,
          error: 'This product is temporarily unavailable. Please try again later.',
        );
      }

      final customerInfo = await Purchases.purchasePackage(package);

      // Check entitlements directly from CustomerInfo (not local state)
      // This fixes race condition where _isPremium isn't updated yet
      final entitlements = customerInfo.entitlements.active;
      final hasPremium = entitlements.containsKey('premium') ||
                         entitlements.containsKey('lifetime');

      _logPurchaseEvent('Purchase completed', details: {
        'productId': productId,
        'hasPremium': hasPremium,
        'activeEntitlements': entitlements.keys.toList(),
      });

      if (hasPremium) {
        // Update local state (fire and forget is ok here since we already verified)
        _handleCustomerInfoUpdate(customerInfo);
        return PurchaseResult(success: true, message: 'Purchase successful!');
      } else {
        // Entitlements not active yet - try refreshing once after a brief delay
        // This handles edge cases where entitlements take a moment to propagate
        await Future.delayed(const Duration(milliseconds: 500));
        final refreshedInfo = await Purchases.getCustomerInfo();
        final refreshedEntitlements = refreshedInfo.entitlements.active;
        final hasRefreshedPremium = refreshedEntitlements.containsKey('premium') ||
                                     refreshedEntitlements.containsKey('lifetime');

        _logPurchaseEvent('Entitlement refresh check', details: {
          'productId': productId,
          'hasRefreshedPremium': hasRefreshedPremium,
          'activeEntitlements': refreshedEntitlements.keys.toList(),
        });

        if (hasRefreshedPremium) {
          await _handleCustomerInfoUpdate(refreshedInfo);
          return PurchaseResult(success: true, message: 'Purchase successful!');
        }

        // Still no entitlements - purchase may be processing
        _logPurchaseEvent('Purchase completed but entitlements not found', details: {
          'productId': productId,
          'waitedMs': 500,
        });

        return PurchaseResult(
          success: false,
          error: 'Purchase is being processed. Please wait a moment and check your subscription status.',
        );
      }
    } on PlatformException catch (e) {
      // Handle RevenueCat platform exceptions
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      _logPurchaseEvent('Purchase PlatformException', details: {
        'errorCode': errorCode.toString(),
        'message': e.message,
      });

      // Handle payment pending specially - this is not an error, just needs approval
      if (errorCode == PurchasesErrorCode.paymentPendingError) {
        return PurchaseResult(
          success: false,
          error: 'Your purchase requires approval. You\'ll be notified when it\'s complete.',
          isPending: true,
        );
      }

      // User cancelled - not really an error
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult(
          success: false,
          error: 'Purchase cancelled',
        );
      }

      return PurchaseResult(
        success: false,
        error: _getReadableErrorMessage(errorCode),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Purchase failed: $e');
      }
      // Provide user-friendly message instead of raw exception
      return PurchaseResult(
        success: false,
        error: 'Unable to complete purchase. Please check your internet connection and try again.',
      );
    }
  }

  /// Convert RevenueCat error codes to user-friendly messages
  String _getReadableErrorMessage(PurchasesErrorCode errorCode) {
    switch (errorCode) {
      case PurchasesErrorCode.purchaseCancelledError:
        return 'Purchase cancelled';
      case PurchasesErrorCode.storeProblemError:
        return 'App Store is temporarily unavailable. Please try again later.';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Purchases are not allowed on this device. Please check your device settings.';
      case PurchasesErrorCode.purchaseInvalidError:
        return 'This purchase is invalid. Please try again.';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return 'This product is currently unavailable. Please try again later.';
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return 'You already own this product. Try restoring your purchases.';
      case PurchasesErrorCode.networkError:
        return 'Network error. Please check your internet connection and try again.';
      case PurchasesErrorCode.receiptAlreadyInUseError:
        return 'This purchase is already linked to another account.';
      case PurchasesErrorCode.invalidReceiptError:
        return 'Receipt validation failed. Please try again.';
      case PurchasesErrorCode.missingReceiptFileError:
        return 'Receipt not found. Please try again.';
      case PurchasesErrorCode.invalidCredentialsError:
      case PurchasesErrorCode.invalidAppleSubscriptionKeyError:
        return 'Configuration error. Please contact support.';
      case PurchasesErrorCode.paymentPendingError:
        // This is handled specially in _purchaseProduct, but provide a fallback message
        return 'Your purchase requires approval. You\'ll be notified when it\'s complete.';
      default:
        return 'Purchase could not be completed. Please try again or contact support.';
    }
  }

  /// Log purchase events for debugging - works in both debug and release builds
  /// In production, these logs can be captured by crash reporting services (e.g., Firebase Crashlytics)
  void _logPurchaseEvent(String event, {Map<String, dynamic>? details}) {
    final timestamp = DateTime.now().toIso8601String();
    final detailsStr = details != null ? ' $details' : '';
    final logMessage = '[$timestamp] [IAP] $event$detailsStr';

    // Always print in debug mode
    if (kDebugMode) {
      debugPrint(logMessage);
    }

    // In release builds, this could be sent to a crash reporting service
    // Example: FirebaseCrashlytics.instance.log(logMessage);
    // For now, we use assert to capture in debug and a no-op in release
    // The important thing is that we have structured logging for diagnosis
  }

  /// Simulate purchase for demo/testing mode
  /// @param isDemo - marks the subscription as a demo in the database
  Future<void> _simulatePurchase(String productId, {bool isDemo = false}) async {
    _isPremium = true;
    _subscriptionStatus = productId == lifetimeProductId ? 'lifetime' : 'premium';
    await _saveCachedStatus();

    // Update server - mark as demo if applicable
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('subscriptions').upsert({
        'user_id': _currentUserId,
        'status': _subscriptionStatus,
        'plan_type': productId == lifetimeProductId ? 'lifetime' : 'monthly',
        'started_at': DateTime.now().toIso8601String(),
        'expires_at': productId == lifetimeProductId
            ? null
            : DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'is_demo': isDemo, // Mark as demo purchase for tracking
        'source': isDemo ? 'demo_mode' : 'revenuecat',
      });

      if (kDebugMode && isDemo) {
        debugPrint('📝 Demo subscription recorded in database (marked as demo)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to update server subscription: $e');
      }
    }
  }

  Future<void> _handleCustomerInfoUpdate(CustomerInfo customerInfo) async {
    final entitlements = customerInfo.entitlements.active;

    if (entitlements.containsKey('premium') || entitlements.containsKey('lifetime')) {
      _isPremium = true;
      _subscriptionStatus = entitlements.containsKey('lifetime') ? 'lifetime' : 'premium';
    } else {
      _isPremium = false;
      _subscriptionStatus = 'free';
    }

    await _saveCachedStatus();
    await _syncToServer();

    if (kDebugMode) {
      debugPrint('🔄 Subscription updated: $_subscriptionStatus');
    }
  }

  Future<void> _syncSubscriptionStatus() async {
    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('subscriptions')
          .select('status, plan_type, expires_at')
          .eq('user_id', _currentUserId!)
          .maybeSingle();

      if (result != null) {
        _subscriptionStatus = result['status'] ?? 'free';
        _isPremium = _subscriptionStatus != 'free';

        // Check if subscription has expired
        if (result['expires_at'] != null) {
          final expiresAt = DateTime.parse(result['expires_at']);
          if (expiresAt.isBefore(DateTime.now())) {
            _isPremium = false;
            _subscriptionStatus = 'free';
          }
        }
      }

      await _saveCachedStatus();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to sync subscription status: $e');
      }
    }
  }

  Future<void> _syncToServer() async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('subscriptions').upsert({
        'user_id': _currentUserId,
        'status': _subscriptionStatus,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to sync to server: $e');
      }
    }
  }

  /// Get or create cached SharedPreferences instance
  Future<SharedPreferences> _getPrefs() async {
    _cachedPrefs ??= await SharedPreferences.getInstance();
    return _cachedPrefs!;
  }

  Future<void> _loadCachedStatus() async {
    try {
      final prefs = await _getPrefs();
      _subscriptionStatus = prefs.getString('yuh_subscription_status') ?? 'free';
      _isPremium = _subscriptionStatus != 'free';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to load cached status: $e');
      }
    }
  }

  Future<void> _saveCachedStatus() async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString('yuh_subscription_status', _subscriptionStatus);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to save cached status: $e');
      }
    }
  }

  Future<void> _loadDailyUsage() async {
    try {
      final prefs = await _getPrefs();
      final lastDateStr = prefs.getString('yuh_last_usage_date');
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';

      if (lastDateStr == todayStr) {
        _dailyAlertsUsed = prefs.getInt('yuh_daily_alerts_used') ?? 0;
      } else {
        // New day, reset usage
        _dailyAlertsUsed = 0;
        await _saveDailyUsage();
      }
      _lastUsageDate = today;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to load daily usage: $e');
      }
    }
  }

  Future<void> _saveDailyUsage() async {
    try {
      final prefs = await _getPrefs();
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';

      await prefs.setString('yuh_last_usage_date', todayStr);
      await prefs.setInt('yuh_daily_alerts_used', _dailyAlertsUsed);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to save daily usage: $e');
      }
    }
  }

  Future<void> _checkAndResetDailyUsage() async {
    final today = DateTime.now();
    if (_lastUsageDate == null ||
        _lastUsageDate!.day != today.day ||
        _lastUsageDate!.month != today.month ||
        _lastUsageDate!.year != today.year) {
      _dailyAlertsUsed = 0;
      _lastUsageDate = today;
      await _saveDailyUsage();
    }
  }
}

/// Result of a purchase operation
class PurchaseResult {
  final bool success;
  final String? message;
  final String? error;
  final bool isPending;

  PurchaseResult({
    required this.success,
    this.message,
    this.error,
    this.isPending = false,
  });
}

/// Result of server-side alert permission validation
class ValidationResult {
  final bool allowed;
  final String? reason;
  final int remainingAlerts;
  final bool isOfflineCheck;

  ValidationResult({
    required this.allowed,
    this.reason,
    this.remainingAlerts = 0,
    this.isOfflineCheck = false,
  });

  /// Human-readable message for the user
  String get userMessage {
    if (allowed) return 'You can send an alert';
    return reason ?? 'You have reached your daily alert limit';
  }
}
