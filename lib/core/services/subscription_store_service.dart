import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../config/payment_config.dart';

/// Service for displaying Apple's native SubscriptionStoreView
/// Provides App Store compliant subscription UI on iOS 17+
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

  /// Show native SubscriptionStoreView
  /// Returns a result map with 'success', 'productId', or 'cancelled'
  static Future<SubscriptionStoreResult> show() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'showSubscriptionStoreView',
        {
          'productIds': [
            PaymentConfig.monthlyProductId,
            PaymentConfig.lifetimeProductId,
          ],
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
        debugPrint('SubscriptionStoreService: Platform error: ${e.message}');
      }
      return SubscriptionStoreResult(success: false, error: e.message);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SubscriptionStoreService: Error showing store: $e');
      }
      return SubscriptionStoreResult(success: false, error: e.toString());
    }
  }
}

/// Result from showing SubscriptionStoreView
class SubscriptionStoreResult {
  final bool success;
  final String? productId;
  final bool cancelled;
  final String? error;

  SubscriptionStoreResult({
    required this.success,
    this.productId,
    this.cancelled = false,
    this.error,
  });
}
