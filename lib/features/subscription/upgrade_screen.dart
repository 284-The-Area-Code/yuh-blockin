import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/premium_theme.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/ath_movil_service.dart';
import '../../config/payment_config.dart';
import '../legal/legal_document_screen.dart';
import 'ath_payment_dialog.dart';

/// Full screen upgrade/purchase UI
class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final AthMovilService _athMovilService = AthMovilService();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  bool _isLoading = false;
  String? _selectedPlan; // 'monthly' or 'lifetime'
  String _paymentMethod = 'store'; // 'store' (App Store/Google Play) or 'ath_movil'
  String _athInputMethod = 'phone'; // 'phone' or 'qr'
  String? _phoneError;
  String _athPath = ''; // Loaded from Supabase
  bool _athPathLoaded = false;

  // Dynamic prices from StoreKit/RevenueCat
  String? _monthlyPrice;
  String? _lifetimePrice;
  bool _pricesLoaded = false;
  bool _pricesError = false;
  String? _pricesErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadAthPath();
    _loadPrices();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAthPath() async {
    final path = await _athMovilService.getAthPath();
    if (mounted) {
      setState(() {
        _athPath = path;
        _athPathLoaded = true;
      });
    }
  }

  /// Load dynamic prices from RevenueCat/StoreKit
  Future<void> _loadPrices() async {
    // Reset error state when retrying
    if (mounted) {
      setState(() {
        _pricesError = false;
        _pricesErrorMessage = null;
      });
    }

    try {
      final offerings = await _subscriptionService.getOfferings();
      if (!mounted) return;

      if (offerings?.current != null) {
        final monthly = offerings!.current!.monthly;
        final lifetime = offerings.current!.lifetime;

        // Check if at least one product is available
        if (monthly != null || lifetime != null) {
          setState(() {
            _monthlyPrice = monthly?.storeProduct.priceString;
            _lifetimePrice = lifetime?.storeProduct.priceString;
            _pricesLoaded = true;
            _pricesError = false;
          });
        } else {
          // Products not configured in RevenueCat/App Store
          setState(() {
            _pricesError = true;
            _pricesErrorMessage = 'Products are temporarily unavailable. Tap to retry.';
          });
          if (kDebugMode) {
            debugPrint('⚠️ No products found in offerings');
          }
        }
      } else {
        // No offerings available
        setState(() {
          _pricesError = true;
          _pricesErrorMessage = 'Unable to load prices. Tap to retry.';
        });
        if (kDebugMode) {
          debugPrint('⚠️ No offerings available from RevenueCat');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load prices: $e');
      }
      if (mounted) {
        setState(() {
          _pricesError = true;
          _pricesErrorMessage = 'Connection error. Tap to retry.';
        });
      }
    }
  }

  /// Open Terms of Service
  void _openTermsOfService() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => const LegalDocumentScreen(
          documentType: LegalDocumentType.termsOfService,
        ),
      ),
    );
  }

  /// Open Privacy Policy
  void _openPrivacyPolicy() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => const LegalDocumentScreen(
          documentType: LegalDocumentType.privacyPolicy,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: PremiumTheme.surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: PremiumTheme.dividerColor),
                      ),
                      child: Icon(
                        CupertinoIcons.xmark,
                        size: 18,
                        color: PremiumTheme.secondaryTextColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    onPressed: _isLoading ? null : _restorePurchases,
                    child: Text(
                      'Restore',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: PremiumTheme.accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    // Premium Hero Section
                    _buildPremiumHero(),
                    const SizedBox(height: 28),
                    // Benefits
                    _buildBenefitsSection(),
                    const SizedBox(height: 28),
                    // Pricing cards
                    _buildPricingCards(),
                    const SizedBox(height: 24),
                    // Purchase button
                    _buildPurchaseButton(),
                    const SizedBox(height: 20),
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

  Widget _buildPremiumHero() {
    return Column(
      children: [
        // Hero icon with theme gradient
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: PremiumTheme.heroGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: PremiumTheme.accentColor.withAlpha(60),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            CupertinoIcons.star_fill,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 20),
        // Title with theme accent
        Text(
          'Go Premium',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: PremiumTheme.primaryTextColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Unlock the full power of Yuh Blockin\'',
          style: TextStyle(
            fontSize: 16,
            color: PremiumTheme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = [
      (CupertinoIcons.infinite, 'Unlimited Alerts', 'Send as many as you need'),
      (CupertinoIcons.bell_fill, 'Priority Notifications', 'Never miss an alert'),
      (CupertinoIcons.car_detailed, 'Multiple Vehicles', 'Track up to 10 plates'),
      (CupertinoIcons.heart_fill, 'Support Development', 'Help us grow'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'What you\'ll get',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: PremiumTheme.primaryTextColor,
            ),
          ),
        ),
        ...benefits.map((benefit) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: PremiumTheme.accentColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  benefit.$1,
                  color: PremiumTheme.accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      benefit.$2,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: PremiumTheme.primaryTextColor,
                      ),
                    ),
                    Text(
                      benefit.$3,
                      style: TextStyle(
                        fontSize: 13,
                        color: PremiumTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: PremiumTheme.accentColor,
                size: 22,
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildPaymentMethodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PremiumTheme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPaymentMethodButton(
              id: 'store',
              icon: PremiumTheme.isIOS
                  ? CupertinoIcons.app_badge
                  : CupertinoIcons.device_laptop,
              label: PremiumTheme.isIOS ? 'App Store' : 'Google Play',
            ),
          ),
          Expanded(
            child: _buildPaymentMethodButton(
              id: 'ath_movil',
              icon: CupertinoIcons.creditcard_fill,
              label: 'ATH Móvil',
              comingSoon: true, // ATH Móvil coming soon - using native billing for now
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodButton({
    required String id,
    required IconData icon,
    required String label,
    bool comingSoon = false,
  }) {
    final isSelected = _paymentMethod == id;
    final isDisabled = comingSoon;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                _paymentMethod = id;
                _phoneError = null;
              });
            },
      child: AnimatedContainer(
        duration: PremiumTheme.fastDuration,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected && !isDisabled
              ? PremiumTheme.accentColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isDisabled
                      ? PremiumTheme.tertiaryTextColor
                      : isSelected
                          ? Colors.white
                          : PremiumTheme.secondaryTextColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDisabled
                          ? PremiumTheme.tertiaryTextColor
                          : isSelected
                              ? Colors.white
                              : PremiumTheme.secondaryTextColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (comingSoon) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAthInputTabs() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PremiumTheme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _athInputMethod = 'phone'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _athInputMethod == 'phone'
                      ? PremiumTheme.accentColor.withAlpha(38)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.phone_fill,
                      size: 16,
                      color: _athInputMethod == 'phone'
                          ? PremiumTheme.accentColor
                          : PremiumTheme.secondaryTextColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Phone',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _athInputMethod == 'phone'
                            ? PremiumTheme.accentColor
                            : PremiumTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _athInputMethod = 'qr'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _athInputMethod == 'qr'
                      ? PremiumTheme.accentColor.withAlpha(38)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.qrcode,
                      size: 16,
                      color: _athInputMethod == 'qr'
                          ? PremiumTheme.accentColor
                          : PremiumTheme.secondaryTextColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'QR Code',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _athInputMethod == 'qr'
                            ? PremiumTheme.accentColor
                            : PremiumTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCodeSection() {
    // QR code is preset for monthly payment
    const amount = PaymentConfig.athMonthlyPrice;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PremiumTheme.dividerColor),
      ),
      child: Column(
        children: [
          // QR Code - Cropped to show only the ATH card portion
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive sizing: max 240 width, maintain aspect ratio
              final maxWidth = constraints.maxWidth.clamp(0.0, 240.0);
              final height = maxWidth * (320 / 240); // Maintain 240:320 aspect ratio
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: maxWidth,
                  height: height,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.0, 0.15), // Center on the QR card
                    child: SizedBox(
                      width: 300,
                      height: 650,
                      child: Image.asset(
                        'assets/images/yuhblockin_monthly_qrcode_ath.jpeg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Instructions
          Text(
            'Scan or screenshot this QR code',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: PremiumTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open ATH Móvil and scan to pay \$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              color: PremiumTheme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),

          // Phone input for verification
          Text(
            'After paying, enter your ATH phone to verify:',
            style: TextStyle(
              fontSize: 12,
              color: PremiumTheme.tertiaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(
              fontSize: 15,
              color: PremiumTheme.primaryTextColor,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
              _PhoneNumberFormatter(),
            ],
            placeholder: 'Your ATH phone number',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: Icon(
                CupertinoIcons.phone_fill,
                size: 20,
                color: CupertinoColors.placeholderText,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: _phoneController,
          focusNode: _phoneFocusNode,
          keyboardType: TextInputType.phone,
          style: TextStyle(
            fontSize: 16,
            color: PremiumTheme.primaryTextColor,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
            _PhoneNumberFormatter(),
          ],
          placeholder: 'Enter your ATH phone number',
          prefix: const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Icon(
              CupertinoIcons.phone_fill,
              color: CupertinoColors.placeholderText,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          onChanged: (value) {
            if (_phoneError != null) {
              setState(() => _phoneError = null);
            }
          },
        ),
        if (_phoneError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _phoneError!,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemRed,
              ),
            ),
          ),
        // Helper tip about ATH path
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.lightbulb_fill,
                size: 14,
                color: PremiumTheme.tertiaryTextColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _athPathLoaded
                      ? 'Or search "$_athPath" in ATH Móvil'
                      : 'Or search in ATH Móvil',
                  style: TextStyle(
                    fontSize: 12,
                    color: PremiumTheme.tertiaryTextColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCards() {
    // Show error state with retry if prices failed to load
    if (_pricesError) {
      return _buildPricesErrorCard();
    }

    return Column(
      children: [
        // Lifetime plan - Featured
        _buildPremiumPlanCard(
          planId: 'lifetime',
          icon: CupertinoIcons.star_fill,
          title: 'Lifetime Access',
          subtitle: 'Pay once, own forever',
          price: _lifetimePrice ?? '...',
          period: 'one-time payment',
          badge: 'BEST VALUE',
          isRecommended: true,
        ),
        const SizedBox(height: 12),
        // Monthly plan
        _buildPremiumPlanCard(
          planId: 'monthly',
          icon: CupertinoIcons.calendar,
          title: 'Monthly',
          subtitle: 'Flexible subscription',
          price: _monthlyPrice ?? '...',
          period: 'per month',
          isRecommended: false,
        ),
      ],
    );
  }

  /// Build error card when prices fail to load
  Widget _buildPricesErrorCard() {
    return GestureDetector(
      onTap: _loadPrices,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: PremiumTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CupertinoColors.systemRed.withAlpha(100)),
        ),
        child: Column(
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: CupertinoColors.systemOrange,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              _pricesErrorMessage ?? 'Unable to load products',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: PremiumTheme.primaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: PremiumTheme.accentColor.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.refresh,
                    size: 18,
                    color: PremiumTheme.accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tap to Retry',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: PremiumTheme.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumPlanCard({
    required String planId,
    required IconData icon,
    required String title,
    required String subtitle,
    required String price,
    required String period,
    String? badge,
    String? savingsText,
    bool isRecommended = false,
  }) {
    final isSelected = _selectedPlan == planId;

    // Use theme accent color for gradient
    final gradientColors = [
      PremiumTheme.accentColor,
      PremiumTheme.accentColor.withAlpha(200),
    ];

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = planId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? PremiumTheme.accentColor.withAlpha(15)
              : PremiumTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? PremiumTheme.accentColor
                : PremiumTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: PremiumTheme.accentColor.withAlpha(30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Badge row
            if (badge != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradientColors),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withAlpha(50),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.sparkles,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          badge,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Main content row
            Row(
              children: [
                // Icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: gradientColors)
                        : null,
                    color: isSelected ? null : PremiumTheme.dividerColor.withAlpha(100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : PremiumTheme.secondaryTextColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: PremiumTheme.primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: PremiumTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? PremiumTheme.accentColor
                            : PremiumTheme.primaryTextColor,
                      ),
                    ),
                    Text(
                      period,
                      style: TextStyle(
                        fontSize: 11,
                        color: PremiumTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Selection indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSelected
                        ? LinearGradient(colors: gradientColors)
                        : null,
                    border: isSelected
                        ? null
                        : Border.all(
                            color: PremiumTheme.dividerColor,
                            width: 2,
                          ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: gradientColors[0].withAlpha(50),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(
                          CupertinoIcons.check_mark,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
              ],
            ),

            // Savings text
            if (savingsText != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.tag_fill,
                      color: CupertinoColors.systemGreen,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      savingsText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.systemGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton() {
    final isEnabled = _selectedPlan != null && !_isLoading && _pricesLoaded;
    final isLifetime = _selectedPlan == 'lifetime';

    return GestureDetector(
      onTap: isEnabled ? _purchase : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isEnabled ? PremiumTheme.heroGradient : null,
          color: isEnabled ? null : PremiumTheme.dividerColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: PremiumTheme.accentColor.withAlpha(50),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CupertinoActivityIndicator(color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_selectedPlan != null) ...[
                      Icon(
                        isLifetime ? CupertinoIcons.star_fill : CupertinoIcons.calendar,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      _selectedPlan == null
                          ? 'Select a Plan'
                          : isLifetime
                              ? 'Get Lifetime Access${_lifetimePrice != null ? ' - $_lifetimePrice' : ''}'
                              : 'Subscribe${_monthlyPrice != null ? ' for $_monthlyPrice/month' : ''}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isEnabled ? Colors.white : PremiumTheme.tertiaryTextColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Column(
      children: [
        Text(
          'Subscriptions auto-renew unless cancelled.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: PremiumTheme.tertiaryTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoButton(
              onPressed: _openTermsOfService,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Terms',
                style: TextStyle(
                  fontSize: 11,
                  color: PremiumTheme.secondaryTextColor,
                ),
              ),
            ),
            Text(
              '|',
              style: TextStyle(
                fontSize: 11,
                color: PremiumTheme.tertiaryTextColor,
              ),
            ),
            CupertinoButton(
              onPressed: _openPrivacyPolicy,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Privacy',
                style: TextStyle(
                  fontSize: 11,
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

    // Route to appropriate payment method
    if (_paymentMethod == 'ath_movil') {
      // ATH Móvil is coming soon - shouldn't reach here but just in case
      _showErrorSnackbar('ATH Móvil coming soon! Please use ${PremiumTheme.isIOS ? "App Store" : "Google Play"}.');
      return;
    } else {
      await _purchaseWithNativeBilling();
    }
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
      } else if (result.isPending) {
        // Payment pending (e.g., "Ask to Buy" approval needed)
        _showPendingDialog(result.error ?? 'Your purchase is being processed.');
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

  Future<void> _purchaseWithAthMovil() async {
    // Validate phone number
    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final validPhone = _athMovilService.validatePhoneNumber(phone);

    if (validPhone == null) {
      setState(() {
        _phoneError = 'Enter a valid 10-digit phone number';
      });
      _phoneFocusNode.requestFocus();
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get user ID
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _showErrorSnackbar('Please sign in to continue');
        return;
      }

      // Determine product type
      final productType = _selectedPlan == 'lifetime'
          ? AthProductType.lifetime
          : AthProductType.monthly;

      // Create payment
      final result = await _athMovilService.createPayment(
        userId: userId,
        productType: productType,
        phoneNumber: validPhone,
      );

      if (!mounted) return;

      if (!result.success) {
        _showErrorSnackbar(result.error ?? 'Failed to create payment');
        return;
      }

      // Show payment dialog
      final paymentResult = await AthPaymentDialog.show(
        context: context,
        transactionId: result.transactionId!,
        amount: result.amount!,
        productType: productType,
      );

      if (!mounted) return;

      if (paymentResult == true) {
        // Payment successful - refresh subscription status
        await _subscriptionService.refreshEntitlements(force: true);
        _showSuccessDialog();
      }
    } catch (e) {
      if (kDebugMode) {
        print('ATH Móvil purchase error: $e');
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
            Icon(CupertinoIcons.check_mark_circled_solid, color: CupertinoColors.systemGreen),
            SizedBox(width: 8),
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

  /// Show dialog for pending purchases (e.g., "Ask to Buy" approval)
  void _showPendingDialog(String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.clock_fill, color: CupertinoColors.systemBlue),
            SizedBox(width: 8),
            Text('Purchase Pending'),
          ],
        ),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
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

/// Phone number formatter for Puerto Rico numbers (787-XXX-XXXX)
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Just return digits as-is for the internal value
    // The display formatting is handled by the hint
    if (text.isEmpty) {
      return newValue;
    }

    // Format as XXX-XXX-XXXX for display
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) {
        buffer.write('-');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
