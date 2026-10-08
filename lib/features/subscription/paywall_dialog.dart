import 'package:flutter/material.dart';

import 'paywall_style.dart';
import 'upgrade_screen.dart';

/// Paywall dialog shown when free user hits daily alert limit, or taps a
/// Premium-only feature. Leads into [UpgradeScreen], where the plans and
/// prices are; prices are not repeated here so they can never disagree with
/// the store.
class PaywallDialog extends StatelessWidget {
  final int remainingAlerts;
  final VoidCallback? onDismiss;
  final String? customMessage;

  const PaywallDialog({
    super.key,
    this.remainingAlerts = 0,
    this.onDismiss,
    this.customMessage,
  });

  /// Show the paywall dialog
  static Future<void> show(
    BuildContext context, {
    int remainingAlerts = 0,
    String? customMessage,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) => PaywallDialog(
        remainingAlerts: remainingAlerts,
        customMessage: customMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFeatureGate = customMessage != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: PaywallStyle.card,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: soft brand tint behind the Premium mark.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: const BoxDecoration(gradient: PaywallStyle.backgroundGradient),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: PaywallStyle.ctaGradient,
                        shape: BoxShape.circle,
                        boxShadow: PaywallStyle.ctaShadow,
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isFeatureGate ? 'A Premium feature' : "You've used today's free alert",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: PaywallStyle.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      customMessage ?? 'Go Premium to keep sending alerts today, and every day.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: PaywallStyle.inkSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // The first three benefits; the full list is on the paywall.
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                child: Column(
                  children: [
                    for (final benefit in premiumBenefits.take(3))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: PaywallStyle.tealSoft,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(benefit.icon, size: 17, color: PaywallStyle.teal),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                benefit.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: PaywallStyle.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: PaywallCtaButton(
                  label: 'See Premium plans',
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDismiss?.call();
                  },
                  style: TextButton.styleFrom(foregroundColor: PaywallStyle.inkSecondary),
                  child: const Text(
                    'Not now',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
