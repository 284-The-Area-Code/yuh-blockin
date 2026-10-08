import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' show Package;
import 'package:url_launcher/url_launcher.dart';

import '../../config/payment_config.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/premium_theme.dart';
import 'paywall_style.dart';

/// Full screen upgrade/purchase UI
///
/// Purchases go through the platform store only (StoreKit on iOS, Google Play
/// Billing on Android), brokered by RevenueCat. App Store Review Guideline
/// 3.1.1 requires in-app purchase to unlock features, so no alternative
/// in-app payment collection is offered here.
///
/// Prices come from the store (RevenueCat offerings) so they show in the
/// buyer's own currency; the fallbacks below are only used until the
/// offerings load, or if they can't be loaded at all.
class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

enum _Plan { lifetime, monthly }

class _UpgradeScreenState extends State<UpgradeScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  static const String _fallbackMonthlyPrice = '\$2.99';
  static const String _fallbackLifetimePrice = '\$19.99';

  bool _isLoading = false;
  bool _purchased = false;
  bool _restored = false;

  // Lifetime is preselected: it's the better deal and the one we want to lead
  // with. Monthly is one tap away.
  _Plan _selectedPlan = _Plan.lifetime;

  Package? _monthlyPackage;
  Package? _lifetimePackage;

  String get _monthlyPrice =>
      _monthlyPackage?.storeProduct.priceString ?? _fallbackMonthlyPrice;
  String get _lifetimePrice =>
      _lifetimePackage?.storeProduct.priceString ?? _fallbackLifetimePrice;

  /// How many months of Monthly cost the same as Lifetime, rounded up.
  int get _lifetimePaysOffInMonths {
    final monthly = _monthlyPackage?.storeProduct.price ?? 2.99;
    final lifetime = _lifetimePackage?.storeProduct.price ?? 19.99;
    if (monthly <= 0) return 0;
    return (lifetime / monthly).ceil();
  }

  String get _storeName => PremiumTheme.isIOS ? 'App Store' : 'Google Play';

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    final offerings = await _subscriptionService.getOfferings();
    final current = offerings?.current;
    if (!mounted || current == null) return;
    setState(() {
      _monthlyPackage = current.monthly;
      _lifetimePackage = current.lifetime;
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error launching $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: PaywallStyle.background,
        body: Container(
          decoration: const BoxDecoration(gradient: PaywallStyle.backgroundGradient),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _purchased ? _buildSuccess() : _buildPaywall(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaywall() {
    return Column(
      key: const ValueKey('paywall'),
      children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                _buildHero(),
                const SizedBox(height: 24),
                _buildBenefits(),
                const SizedBox(height: 24),
                _buildPlanCard(_Plan.lifetime),
                const SizedBox(height: 12),
                _buildPlanCard(_Plan.monthly),
                const SizedBox(height: 16),
                _buildDisclosure(),
              ],
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            tooltip: 'Close',
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(color: PaywallStyle.cardBorder),
              ),
              child: const Icon(Icons.close_rounded, size: 18, color: PaywallStyle.inkSecondary),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _isLoading ? null : _restorePurchases,
            style: TextButton.styleFrom(foregroundColor: PaywallStyle.teal),
            child: const Text(
              'Restore',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo_transparent.png',
          height: 104,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        const Text(
          'Move without limits',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: PaywallStyle.ink,
            letterSpacing: -0.4,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Everything Yuh Blockin. can do, with no daily cap.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: PaywallStyle.inkSecondary, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildBenefits() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: PaywallStyle.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PaywallStyle.cardBorder),
        boxShadow: PaywallStyle.cardShadow,
      ),
      child: Column(
        children: [
          for (final benefit in premiumBenefits)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: PaywallStyle.tealSoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(benefit.icon, size: 20, color: PaywallStyle.teal),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          benefit.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: PaywallStyle.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          benefit.detail,
                          style: const TextStyle(
                            fontSize: 13,
                            color: PaywallStyle.inkSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(_Plan plan) {
    final selected = _selectedPlan == plan;
    final isLifetime = plan == _Plan.lifetime;
    final months = _lifetimePaysOffInMonths;

    final title = isLifetime ? 'Lifetime' : 'Monthly';
    final price = isLifetime ? _lifetimePrice : _monthlyPrice;
    final period = isLifetime ? 'once' : '/ month';
    final detail = isLifetime
        ? (months > 0
            ? 'Pay once, keep it forever. Costs the same as $months months.'
            : 'Pay once, keep it forever.')
        : 'Billed monthly. Cancel anytime.';

    return Semantics(
      button: true,
      selected: selected,
      label: '$title plan, $price $period',
      child: GestureDetector(
        onTap: _isLoading
            ? null
            : () {
                HapticFeedback.selectionClick();
                setState(() => _selectedPlan = plan);
              },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: PremiumTheme.fastDuration,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              decoration: BoxDecoration(
                color: selected ? PaywallStyle.selectedFill : PaywallStyle.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? PaywallStyle.teal : PaywallStyle.cardBorder,
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected ? PaywallStyle.cardShadow : null,
              ),
              child: Row(
                children: [
                  _RadioDot(selected: selected),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: PaywallStyle.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          detail,
                          style: const TextStyle(
                            fontSize: 13,
                            color: PaywallStyle.inkSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: PaywallStyle.ink,
                        ),
                      ),
                      Text(
                        period,
                        style: const TextStyle(fontSize: 12, color: PaywallStyle.inkTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isLifetime)
              Positioned(
                top: -10,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: PaywallStyle.ctaGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'BEST VALUE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Store disclosure. Apple and Google both require the price, the billing
  /// period and how renewal and cancellation work to be visible before
  /// purchase. Lifetime is a one-time purchase and must not be described as
  /// renewing.
  Widget _buildDisclosure() {
    final String text;
    if (_selectedPlan == _Plan.lifetime) {
      text = 'Lifetime is a one-time purchase of $_lifetimePrice charged to your '
          '$_storeName account. It does not renew.';
    } else if (PremiumTheme.isIOS) {
      text = 'Monthly is $_monthlyPrice per month, charged to your Apple ID at '
          'confirmation. It renews automatically unless cancelled at least 24 '
          'hours before the end of the current period. Manage or cancel any time '
          'in your App Store account settings.';
    } else {
      text = 'Monthly is $_monthlyPrice per month, charged to your Google Play '
          'account. It renews automatically until you cancel. Cancel any time in '
          'Google Play > Payments & subscriptions.';
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 11.5, color: PaywallStyle.inkTertiary, height: 1.45),
    );
  }

  Widget _buildBottomBar() {
    final label = _selectedPlan == _Plan.lifetime
        ? 'Get Lifetime for $_lifetimePrice'
        : 'Subscribe for $_monthlyPrice / month';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      decoration: const BoxDecoration(
        color: PaywallStyle.background,
        border: Border(top: BorderSide(color: PaywallStyle.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PaywallCtaButton(
            label: label,
            loading: _isLoading,
            onPressed: _isLoading ? null : _purchase,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, size: 13, color: PaywallStyle.inkTertiary),
              const SizedBox(width: 5),
              Text(
                'Secure payment through $_storeName',
                style: const TextStyle(fontSize: 12, color: PaywallStyle.inkTertiary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegalLink('Terms', () => _openUrl(PaymentConfig.termsOfServiceUrl)),
              const _LegalDot(),
              _LegalLink('Privacy', () => _openUrl(PaymentConfig.privacyPolicyUrl)),
              const _LegalDot(),
              _LegalLink('Support', () => _openUrl(PaymentConfig.supportUrl)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      key: const ValueKey('success'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                gradient: PaywallStyle.ctaGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, size: 46, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              _restored ? 'Premium restored' : "You're Premium",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: PaywallStyle.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _restored
                  ? 'Your Premium access is back on this device.'
                  : 'Thanks for supporting Yuh Blockin. Everything is unlocked.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: PaywallStyle.inkSecondary, height: 1.4),
            ),
            const SizedBox(height: 32),
            PaywallCtaButton(
              label: 'Continue',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchase() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final PurchaseResult result = _selectedPlan == _Plan.monthly
          ? await _subscriptionService.purchaseMonthly()
          : await _subscriptionService.purchaseLifetime();

      if (!mounted) return;

      if (result.success) {
        _showSuccess();
      } else if (result.error != 'Purchase cancelled') {
        // Backing out of the store sheet is not an error worth shouting about.
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
        _showSuccess(isRestore: true);
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

  void _showSuccess({bool isRestore = false}) {
    HapticFeedback.heavyImpact();
    setState(() {
      _purchased = true;
      _restored = isRestore;
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: PaywallStyle.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PremiumTheme.fastDuration,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? PaywallStyle.teal : Colors.transparent,
        border: Border.all(
          color: selected ? PaywallStyle.teal : PaywallStyle.cardBorder,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: PaywallStyle.inkSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 32),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _LegalDot extends StatelessWidget {
  const _LegalDot();

  @override
  Widget build(BuildContext context) {
    return const Text('·', style: TextStyle(fontSize: 12, color: PaywallStyle.inkTertiary));
  }
}
