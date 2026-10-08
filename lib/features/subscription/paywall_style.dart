import 'package:flutter/material.dart';

import '../../config/payment_config.dart';

/// Shared look for the paywall (UpgradeScreen) and its upsell dialog
/// (PaywallDialog).
///
/// The paywall deliberately does not follow the user's chosen app theme: it
/// is the app's storefront, so it always uses the brand colors from the logo
/// (teal #0D7899 and coral #FF7A74) on a clean light background, the same
/// treatment as the app icon.
class PaywallStyle {
  PaywallStyle._();

  // Brand
  static const Color teal = Color(0xFF0D7899);
  static const Color tealSoft = Color(0xFFE3F1F6);
  static const Color coral = Color(0xFFFF7A74);
  static const Color coralDeep = Color(0xFFF2545B);

  // Surfaces
  static const Color background = Color(0xFFF6FAFC);
  static const Color heroTint = Color(0xFFE2F1F6);
  static const Color card = Colors.white;
  static const Color cardBorder = Color(0xFFE1EBEF);
  static const Color selectedFill = Color(0xFFF1F9FB);

  // Text
  static const Color ink = Color(0xFF0F2A36);
  static const Color inkSecondary = Color(0xFF4F6672);
  static const Color inkTertiary = Color(0xFF8497A1);

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [coral, coralDeep],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [heroTint, background],
    stops: [0.0, 0.42],
  );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F2A36).withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get ctaShadow => [
        BoxShadow(
          color: coralDeep.withValues(alpha: 0.22),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}

/// One Premium benefit. Each one is something Premium actually unlocks in
/// the app today (see PaymentConfig and the premium checks in main.dart and
/// theme_settings_screen.dart); keep it that way.
class PremiumBenefit {
  const PremiumBenefit(this.icon, this.title);

  final IconData icon;
  final String title;
}

const List<PremiumBenefit> premiumBenefits = [
  PremiumBenefit(Icons.all_inclusive_rounded, 'Unlimited alerts'),
  PremiumBenefit(Icons.campaign_rounded, "Tell drivers you're blocking"),
  PremiumBenefit(Icons.directions_car_filled_rounded, 'Up to ${PaymentConfig.premiumMaxPlates} vehicles'),
  PremiumBenefit(Icons.palette_rounded, '4 premium themes'),
];

/// Full-width coral gradient button used for the paywall's main actions.
class PaywallCtaButton extends StatelessWidget {
  const PaywallCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null || loading;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: PaywallStyle.ctaGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: PaywallStyle.ctaShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
