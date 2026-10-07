import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/premium_theme.dart';
import '../../core/services/subscription_service.dart';
import '../../config/payment_config.dart';

/// Full screen upgrade/purchase UI
///
/// Purchases go through the platform store only (StoreKit on iOS, Google Play
/// Billing on Android), brokered by RevenueCat. App Store Review Guideline
/// 3.1.1 requires in-app purchase to unlock features, so no alternative
/// in-app payment collection is offered here.
class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _isLoading = false;
  String? _selectedPlan; // 'monthly' or 'lifetime'

  /// Open Terms of Service
  Future<void> _openTermsOfService() async {
    final uri = Uri.parse(PaymentConfig.termsOfServiceUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error launching terms: $e');
    }
  }

  /// Open Privacy Policy
  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(PaymentConfig.privacyPolicyUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error launching privacy: $e');
    }
  }

  /// Open Contact Support
  Future<void> _openContactSupport() async {
    final uri = Uri.parse(PaymentConfig.supportUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error launching support: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Go Premium',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: PremiumTheme.primaryTextColor,
          ),
        ),
        backgroundColor: PremiumTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _restorePurchases,
            child: Text(
              'Restore',
              style: TextStyle(color: PremiumTheme.accentColor),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    // Hero icon + Title row
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: PremiumTheme.heroGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: PremiumTheme.accentColor.withAlpha(77),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.star_fill,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Go Premium',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: PremiumTheme.primaryTextColor,
                                ),
                              ),
                              Text(
                                'Unlock unlimited alerts',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: PremiumTheme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Benefits
                    _buildBenefitsSection(),
                    const SizedBox(height: 24),
                    // Pricing cards
                    _buildPricingCards(),
                    const SizedBox(height: 24),
                    // Purchase button
                    _buildPurchaseButton(),
                    const SizedBox(height: 16),
                    // Terms
                    _buildTermsText(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = [
      (CupertinoIcons.infinite, 'Unlimited Alerts'),
      (CupertinoIcons.time_solid, 'No Daily Limits'),
      (CupertinoIcons.heart_fill, 'Support Development'),
      (CupertinoIcons.sparkles, 'Priority Features'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceColor,
        borderRadius: PremiumTheme.mediumRadius,
        border: Border.all(
          color: PremiumTheme.dividerColor,
          width: 1,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: benefits.map((benefit) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                benefit.$1,
                color: PremiumTheme.accentColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                benefit.$2,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: PremiumTheme.primaryTextColor,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                CupertinoIcons.check_mark,
                color: CupertinoColors.systemGreen,
                size: 14,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPricingCards() {
    return Row(
      children: [
        // Monthly plan
        Expanded(
          child: _buildPlanCard(
            planId: 'monthly',
            title: 'Monthly',
            price: '\$2.99',
            period: '/month',
            isPopular: false,
          ),
        ),
        const SizedBox(width: 10),
        // Lifetime plan
        Expanded(
          child: _buildPlanCard(
            planId: 'lifetime',
            title: 'Lifetime',
            price: '\$19.99',
            period: 'one-time',
            isPopular: true,
            badge: 'Best Value',
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String planId,
    required String title,
    required String price,
    required String period,
    bool isPopular = false,
    String? badge,
  }) {
    final isSelected = _selectedPlan == planId;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = planId),
      child: AnimatedContainer(
        duration: PremiumTheme.fastDuration,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? PremiumTheme.accentColor.withAlpha(20)
              : PremiumTheme.surfaceColor,
          borderRadius: PremiumTheme.mediumRadius,
          border: Border.all(
            color: isSelected
                ? PremiumTheme.accentColor
                : PremiumTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: PremiumTheme.accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ] else
              const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: PremiumTheme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              price,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: PremiumTheme.primaryTextColor,
              ),
            ),
            Text(
              period,
              style: TextStyle(
                fontSize: 11,
                color: PremiumTheme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            // Selection indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? PremiumTheme.accentColor
                      : PremiumTheme.dividerColor,
                  width: 2,
                ),
                color: isSelected ? PremiumTheme.accentColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      CupertinoIcons.check_mark,
                      color: Colors.white,
                      size: 12,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton.filled(
        onPressed: _selectedPlan == null || _isLoading ? null : _purchase,
        borderRadius: BorderRadius.circular(14),
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CupertinoActivityIndicator(color: Colors.white),
              )
            : Text(
                _selectedPlan == null
                    ? 'Select a Plan'
                    : _selectedPlan == 'monthly'
                        ? 'Subscribe for \$2.99/month'
                        : 'Get Lifetime Access - \$19.99',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Column(
      children: [
        Text(
          PremiumTheme.isIOS
              ? 'Payment will be charged to your Apple Account at confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period. Account will be charged for renewal within 24-hours prior to the end of the current period. Manage subscriptions in your Account Settings.'
              : 'Payment will be charged to your Google Play Account at confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period. Account will be charged for renewal within 24-hours prior to the end of the current period. Manage subscriptions in your Google Play Store settings.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: PremiumTheme.tertiaryTextColor,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoButton(
              onPressed: _openTermsOfService,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Terms of Service',
                style: TextStyle(
                  fontSize: 10,
                  color: PremiumTheme.secondaryTextColor,
                ),
              ),
            ),
            Text(
              '|',
              style: TextStyle(
                fontSize: 10,
                color: PremiumTheme.tertiaryTextColor,
              ),
            ),
            CupertinoButton(
              onPressed: _openPrivacyPolicy,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 10,
                  color: PremiumTheme.secondaryTextColor,
                ),
              ),
            ),
            Text(
              '|',
              style: TextStyle(
                fontSize: 10,
                color: PremiumTheme.tertiaryTextColor,
              ),
            ),
            CupertinoButton(
              onPressed: _openContactSupport,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Contact Support',
                style: TextStyle(
                  fontSize: 10,
                  color: PremiumTheme.secondaryTextColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _purchase() async {
    if (_selectedPlan == null) return;
    await _purchaseWithNativeBilling();
  }

  Future<void> _purchaseWithNativeBilling() async {
    setState(() => _isLoading = true);

    try {
      PurchaseResult result;
      if (_selectedPlan == 'monthly') {
        result = await _subscriptionService.purchaseMonthly();
      } else {
        result = await _subscriptionService.purchaseLifetime();
      }

      if (!mounted) return;

      if (result.success) {
        _showSuccessDialog();
      } else {
        _showErrorSnackbar(result.error ?? 'Purchase failed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Purchase error: $e');
      }
      if (mounted) {
        _showErrorSnackbar('An error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

    try {
      final result = await _subscriptionService.restorePurchases();

      if (!mounted) return;

      if (result.success) {
        _showSuccessDialog(isRestore: true);
      } else {
        _showErrorSnackbar(result.error ?? 'No purchases to restore');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to restore purchases');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog({bool isRestore = false}) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.check_mark_circled_solid, color: CupertinoColors.systemGreen),
            const SizedBox(width: 8),
            Text(isRestore ? 'Restored!' : 'Welcome to Premium!'),
          ],
        ),
        content: Text(
          isRestore
              ? 'Your premium access has been restored.'
              : 'You now have unlimited alerts!',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Continue'),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close upgrade screen
            },
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CupertinoColors.systemRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
