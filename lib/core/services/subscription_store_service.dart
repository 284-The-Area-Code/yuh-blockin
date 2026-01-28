import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../config/payment_config.dart';

/// Service for displaying Apple's native SubscriptionStoreView
/// Provides App Store compliant subscription UI on iOS 17+
///
/// IMPORTANT: SubscriptionStoreView ONLY supports auto-renewable subscriptions.
/// For one-time purchases (like lifetime), use [purchaseNonSubscription] which
/// uses StoreKit 2's direct purchase API.
class SubscriptionStoreService {
  static const _channel = MethodChannel('com.dezetingz.yuhBlockin/subscription_store');

  /// Check if native SubscriptionStoreView is available (iOS 17+)
  static Future<bool> isAvailable() async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isSubscriptionStoreViewAvailable');
      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SubscriptionStoreService: Failed to check availability: $e');
      }
      return false;
    }
  }

  /// Check if a product is a subscription (vs one-time purchase)
  static bool isSubscriptionProduct(String productId) {
    return productId.contains('monthly') ||
           productId.contains('yearly') ||
           productId.contains('annual') ||
           productId.contains('weekly');
  }

  /// Show native SubscriptionStoreView for SUBSCRIPTION products only
  /// IMPORTANT: This only shows subscription products, NOT lifetime/one-time purchases
  /// Returns a result map with 'success', 'productId', or 'cancelled'
  static Future<SubscriptionStoreResult> showForSubscription() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'showSubscriptionStoreView',
        {
          // ONLY pass subscription products - SubscriptionStoreView doesn't support one-time purchases
          'productIds': [PaymentConfig.monthlyProductId],
        },
      );

      if (result == null) {
        return SubscriptionStoreResult(success: false, cancelled: true);
      }

      return SubscriptionStoreResult(
        success: result['success'] as bool? ?? false,
        productId: result['productId'] as String?,
        cancelled: result['cancelled'] as bool? ?? false,
      );
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('SubscriptionStoreService: Platform error: ${e.code} - ${e.message}');
      }
      // Provide helpful error for common issues
      if (e.code == 'NO_SUBSCRIPTIONS') {
        return SubscriptionStoreResult(
          success: false,
          error: 'No subscription products available. Please try again later.',
        );
      }
      return SubscriptionStoreResult(success: false, error: e.message);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SubscriptionStoreService: Error showing store: $e');
      }
      return SubscriptionStoreResult(success: false, error: e.toString());
    }
  }

  /// Purchase a non-subscription product (like lifetime) using StoreKit 2 direct API
  /// This is separate from SubscriptionStoreView which only handles subscriptions
  static Future<SubscriptionStoreResult> purchaseNonSubscription(String productId) async {
    if (!Platform.isIOS) {
      return SubscriptionStoreResult(
        success: false,
        error: 'Native purchase only available on iOS',
      );
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'purchaseProduct',
        {'productId': productId},
      );

      if (result == null) {
        return SubscriptionStoreResult(success: false, error: 'No response from purchase');
      }

      return SubscriptionStoreResult(
        success: result['success'] as bool? ?? false,
        productId: result['productId'] as String?,
        cancelled: result['cancelled'] as bool? ?? false,
        pending: result['pending'] as bool? ?? false,
        error: result['error'] as String?,
      );
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('SubscriptionStoreService: Purchase error: ${e.code} - ${e.message}');
      }
      return SubscriptionStoreResult(success: false, error: e.message);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SubscriptionStoreService: Error purchasing: $e');
      }
      return SubscriptionStoreResult(success: false, error: e.toString());
    }
  }

  /// Legacy method - shows subscription store
  /// @deprecated Use [showForSubscription] for subscriptions or [purchaseNonSubscription] for lifetime
  static Future<SubscriptionStoreResult> show() async {
    return showForSubscription();
  }
}

/// Result from SubscriptionStoreView or native purchase
class SubscriptionStoreResult {
  final bool success;
  final String? productId;
  final bool cancelled;
  final bool pending;
  final String? error;

  SubscriptionStoreResult({
    required this.success,
    this.productId,
    this.cancelled = false,
    this.pending = false,
    this.error,
  });
}
