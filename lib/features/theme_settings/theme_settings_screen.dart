import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/premium_theme.dart';
import '../../core/theme/bvi_motifs.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/theme_notifier.dart';

/// Premium theme settings screen
/// Allows users to switch between Light, Dark, Caribbean Sunset, and Premium themes
class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  String _selectedTheme = PremiumTheme.currentMode;
  bool _isPremiumUser = false;
  final SubscriptionService _subscriptionService = SubscriptionService();

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  void _checkPremiumStatus() {
    // Use actual subscription service to check premium status
    setState(() {
      _isPremiumUser = _subscriptionService.isPremium;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: PremiumTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            color: PremiumTheme.primaryTextColor,
          ),
        ),
        title: Text(
          'Theme Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: PremiumTheme.primaryTextColor,

          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Use compact spacing on smaller screens
            final isCompact = constraints.maxHeight < 700;
            final itemSpacing = isCompact ? 10.0 : 16.0;
            final sectionSpacing = isCompact ? 16.0 : 24.0;
            final headerSpacing = isCompact ? 20.0 : 32.0;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isCompact ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Choose Your Vibe',
                    style: TextStyle(
                      fontSize: isCompact ? 24 : 28,
                      fontWeight: FontWeight.w400,
                      color: PremiumTheme.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select the perfect theme mode for your experience',
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.w400,
                      color: PremiumTheme.secondaryTextColor,
                    ),
                  ),
                  SizedBox(height: headerSpacing),

                  // Theme options
                  _buildThemeOption(
                    mode: PremiumTheme.lightMode,
                    title: 'Light Mode',
                    subtitle: 'Clean, minimal, and crisp',
                    icon: Icons.wb_sunny_outlined,
                    primaryColor: const Color(0xFF0A84FF),
                    backgroundColor: const Color(0xFFFCFCFC),
                    textColor: const Color(0xFF1C1C1E),
                    isCompact: isCompact,
                  ),

                  SizedBox(height: itemSpacing),

                  _buildThemeOption(
                    mode: PremiumTheme.darkMode,
                    title: 'Dark Mode',
                    subtitle: 'Sophisticated and elegant',
                    icon: Icons.dark_mode_outlined,
                    primaryColor: const Color(0xFF0A84FF),
                    backgroundColor: const Color(0xFF000000),
                    textColor: const Color(0xFFFFFFFF),
                    isCompact: isCompact,
                  ),

                  SizedBox(height: itemSpacing),

                  _buildThemeOption(
                    mode: PremiumTheme.sunsetMode,
                    title: 'Caribbean Sunset',
                    subtitle: 'Warm golden hour vibes',
                    icon: Icons.wb_twilight_outlined,
                    primaryColor: const Color(0xFFFF8C42),
                    backgroundColor: const Color(0xFF2D1B14),
                    textColor: const Color(0xFFFFF5E6),
                    isCompact: isCompact,
                  ),

                  SizedBox(height: sectionSpacing),

                  // Premium themes section header
                  Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 18,
                        color: PremiumTheme.accentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Premium Themes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PremiumTheme.accentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: itemSpacing),

                  _buildThemeOption(
                    mode: PremiumTheme.pinkMode,
                    title: 'Premium Pink',
                    subtitle: 'Elegant rose & blush tones',
                    icon: Icons.favorite_outline_rounded,
                    primaryColor: const Color(0xFFFF6B9D),
                    backgroundColor: const Color(0xFF1A1218),
                    textColor: const Color(0xFFFFF0F5),
                    isPremiumTheme: true,
                    isCompact: isCompact,
                  ),

                  SizedBox(height: itemSpacing),

                  _buildThemeOption(
                    mode: PremiumTheme.cyberpunkMode,
                    title: 'Cyberpunk',
                    subtitle: 'Neon-infused electric vibes',
                    icon: Icons.bolt_rounded,
                    primaryColor: const Color(0xFF00F5FF),
                    backgroundColor: const Color(0xFF0A0A12),
                    textColor: const Color(0xFFE0F7FA),
                    isPremiumTheme: true,
                    secondaryColor: const Color(0xFFFF00FF),
                    isCompact: isCompact,
                  ),

                  SizedBox(height: itemSpacing),

                  _buildThemeOption(
                    mode: PremiumTheme.islandGoldMode,
                    title: 'Island Gold',
                    subtitle: 'Golden Caribbean sunrise vibes',
                    icon: Icons.wb_twilight_rounded,
                    primaryColor: const Color(0xFFF7C700), // Golden Poppy
                    backgroundColor: const Color(0xFF0A1628), // Deep ocean blue
                    textColor: const Color(0xFFFFF8E7), // Warm sunrise white
                    isPremiumTheme: true,
                    secondaryColor: const Color(0xFF00A86B), // Tropical green
                    isCompact: isCompact,
                  ),

                  SizedBox(height: itemSpacing),

                  _buildBviPrideOption(isCompact: isCompact),

                  SizedBox(height: sectionSpacing),

                  // Footer with DezeTingz branding
                  Center(
                    child: Column(
                      children: [
                        Container(
                          height: 1,
                          width: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                PremiumTheme.accentColor.withValues(alpha: 0.0),
                                PremiumTheme.accentColor.withValues(alpha: 0.3),
                                PremiumTheme.accentColor.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'DezeTingz © 2026',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: PremiumTheme.tertiaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Special ultra-premium BVI Pride theme option
  /// Features the 12 golden oil lamps of Saint Ursula from the BVI coat of arms
  ///
  /// Colors are sourced from PremiumTheme's bviPride* constants (not
  /// redeclared locally) so this card and the rest of the app can never
  /// drift apart. Gold is deliberately used only for thin accents/borders -
  /// blue (the flag's dominant color) carries the surface, with a touch of
  /// red for the "strength and valor" accent.
  Widget _buildBviPrideOption({required bool isCompact}) {
    final isSelected = _selectedTheme == PremiumTheme.bviPrideMode;
    final isLocked = !_isPremiumUser;

    const goldenPoppy = PremiumTheme.bviPrideAccentColor;
    const resolutionBlue = PremiumTheme.bviPrideResolutionBlue;
    const deepNavy = PremiumTheme.bviPrideBackgroundColor;
    const cadmiumGreen = PremiumTheme.bviPrideSecondaryAccent;
    const philippineRed = PremiumTheme.bviPrideTertiaryAccent;

    // Responsive sizes
    final circleSize = isCompact ? 52.0 : 64.0;
    final padding = isCompact ? 14.0 : 18.0;
    final titleFontSize = isCompact ? 17.0 : 20.0;
    final subtitleFontSize = isCompact ? 11.0 : 13.0;

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 12),
                  Flexible(
                    child: Text('Subscribe to unlock premium themes'),
                  ),
                ],
              ),
              backgroundColor: goldenPoppy,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }

        HapticFeedback.lightImpact();
        setState(() {
          _selectedTheme = PremiumTheme.bviPrideMode;
        });
        context.read<ThemeNotifier>().setTheme(PremiumTheme.bviPrideMode);

        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) Navigator.of(context).pop();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: EdgeInsets.all(padding),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          // Premium gradient background when selected - Blue dominant,
          // gold held to a faint final stop so it reads as accent, not wash.
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    resolutionBlue.withValues(alpha: 0.4),
                    deepNavy.withValues(alpha: 0.7),
                    goldenPoppy.withValues(alpha: 0.06),
                  ],
                )
              : null,
          color: isSelected ? null : PremiumTheme.surfaceColor,
          borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
          border: Border.all(
            color: isSelected
                ? resolutionBlue.withValues(alpha: 0.8)
                : PremiumTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  // Blue glow - BVI flag, the dominant light
                  BoxShadow(
                    color: resolutionBlue.withValues(alpha: 0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                    spreadRadius: 2,
                  ),
                  // Thin gold rim - accent only, not a wash
                  BoxShadow(
                    color: goldenPoppy.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                  // Faint red presence - "strength and valor" accent
                  BoxShadow(
                    color: philippineRed.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [
                  // Subtle blue glow even when not selected
                  BoxShadow(
                    color: resolutionBlue.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Extremely subtle Union-Jack-inspired geometry - abstracted
            // hairlines, not a literal flag. Only present when selected so
            // the unselected card stays quiet.
            if (isSelected)
              const Positioned.fill(
                child: BviFlagGeometryOverlay(
                  blueLine: resolutionBlue,
                  redLine: philippineRed,
                  whiteLine: Colors.white,
                ),
              ),
            Row(
              children: [
            // Premium BVI flag-inspired preview - Blue background, gold held
            // to thin accents, with a faint eleven-lamp ring Easter egg.
            Stack(
              alignment: Alignment.center,
              children: [
                BviElevenLampRing(
                  diameter: circleSize + 16,
                  lampColor: goldenPoppy,
                  opacity: isSelected ? 0.35 : 0.18,
                ),
                Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    // Resolution Blue - the main BVI flag color
                    gradient: const RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        Color(0xFF002D9C), // Brighter center blue
                        resolutionBlue, // Official Resolution Blue
                        Color(0xFF001654), // Darker edge
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: goldenPoppy,
                      width: 2.5,
                    ),
                    boxShadow: [
                      // Blue glow - representing the flag, the dominant light
                      BoxShadow(
                        color: resolutionBlue.withValues(alpha: 0.6),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                      // Thin gold rim glow - accent only
                      BoxShadow(
                        color: goldenPoppy.withValues(alpha: 0.28),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Thin red ring - layered depth, "strength and valor" accent
                      Container(
                        width: circleSize - 10,
                        height: circleSize - 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: philippineRed.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                      ),
                      // Small green accent ring (coat of arms)
                      Container(
                        width: circleSize - 16,
                        height: circleSize - 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cadmiumGreen.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                      ),
                      // Stylized oil lamp - Saint Ursula's lamps, abstracted
                      BviOilLampIcon(
                        size: isCompact ? 24 : 30,
                        color: goldenPoppy,
                        glowColor: PremiumTheme.bviPrideAccentGlow,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(width: isCompact ? 14 : 18),

            // Theme info with premium styling
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'BVI Pride',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w700,
                            color: PremiumTheme.primaryTextColor,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Ultra premium badge with BVI flag colors - Blue & Gold
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              resolutionBlue,
                              Color(0xFF0033A0), // Brighter blue
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: goldenPoppy.withValues(alpha: 0.6),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: resolutionBlue.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              size: 10,
                              color: goldenPoppy,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'BVI',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: goldenPoppy,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isCompact ? 4 : 6),
                  Text(
                    'Saint Ursula\'s Golden Lamps',
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w500,
                      // Light blue-neutral, not gold - body/subtitle text
                      // staying gold-tinted was the single biggest source
                      // of the "too much yellow" complaint across the app.
                      color: PremiumTheme.bviPrideSecondaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isCompact) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Official BVI coat of arms colors',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: PremiumTheme.secondaryTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Selection indicator or lock
            if (isLocked)
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PremiumTheme.tertiaryTextColor.withValues(alpha: 0.2),
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: PremiumTheme.tertiaryTextColor,
                ),
              )
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [resolutionBlue, Color(0xFF0033A0)],
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? goldenPoppy : PremiumTheme.tertiaryTextColor,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: resolutionBlue.withValues(alpha: 0.6),
                            blurRadius: 10,
                          ),
                          BoxShadow(
                            color: goldenPoppy.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: goldenPoppy,
                      )
                    : null,
              ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color primaryColor,
    required Color backgroundColor,
    required Color textColor,
    bool isPremiumTheme = false,
    Color? secondaryColor,
    bool isCompact = false,
  }) {
    final isSelected = _selectedTheme == mode;
    final isLocked = isPremiumTheme && !_isPremiumUser;

    // Responsive sizes
    final circleSize = isCompact ? 48.0 : 60.0;
    final iconSize = isCompact ? 22.0 : 28.0;
    final padding = isCompact ? 14.0 : 20.0;
    final titleFontSize = isCompact ? 16.0 : 18.0;
    final subtitleFontSize = isCompact ? 12.0 : 14.0;

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          // Show premium required message
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 12),
                  Flexible(
                    child: Text('Subscribe to unlock premium themes'),
                  ),
                ],
              ),
              backgroundColor: primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }

        HapticFeedback.lightImpact();
        setState(() {
          _selectedTheme = mode;
        });

        // Update global theme using Provider
        context.read<ThemeNotifier>().setTheme(mode);

        // Brief delay for user feedback then pop
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: isSelected
              ? (isPremiumTheme ? primaryColor.withValues(alpha: 0.15) : PremiumTheme.accentColor.withValues(alpha: 0.1))
              : PremiumTheme.surfaceColor,
          borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
          border: Border.all(
            color: isSelected
                ? (isPremiumTheme ? primaryColor.withValues(alpha: 0.4) : PremiumTheme.accentColor.withValues(alpha: 0.3))
                : PremiumTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isPremiumTheme ? primaryColor : PremiumTheme.accentColor).withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Theme preview circle with optional gradient for cyberpunk
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  if (secondaryColor != null)
                    BoxShadow(
                      color: secondaryColor.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(-4, 0),
                    ),
                ],
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: iconSize,
              ),
            ),

            SizedBox(width: isCompact ? 12 : 16),

            // Theme info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: PremiumTheme.primaryTextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPremiumTheme) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor,
                                secondaryColor ?? primaryColor.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: isCompact ? 2 : 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w400,
                      color: PremiumTheme.secondaryTextColor,
                    ),
                    maxLines: isCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Selection indicator or lock icon
            if (isLocked)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PremiumTheme.tertiaryTextColor.withValues(alpha: 0.2),
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: PremiumTheme.tertiaryTextColor,
                ),
              )
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? (isPremiumTheme ? primaryColor : PremiumTheme.accentColor)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? (isPremiumTheme ? primaryColor : PremiumTheme.accentColor)
                        : PremiumTheme.tertiaryTextColor,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}