import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'premium_theme.dart';

/// Home-screen styling used only when the BVI Pride theme is active.
///
/// Every other theme keeps the existing home-screen treatment; callers check
/// [BviPrideHome.isActive] before using anything in this file.
///
/// Image sources (both public domain, from Wikimedia Commons):
/// - assets/images/bvi_union_canton.png: canton cropped from
///   "Flag of the British Virgin Islands.svg".
/// - assets/images/bvi_coat_of_arms.png: "Coat of arms of the British
///   Virgin Islands.svg" (CC0), including the VIGILATE scroll.
class BviPrideHome {
  BviPrideHome._();

  static bool get isActive =>
      PremiumTheme.currentMode == PremiumTheme.bviPrideMode;

  // Background
  static const Color backgroundTop = Color(0xFF172036);
  static const Color backgroundMid = Color(0xFF121A2D);
  static const Color backgroundBottom = Color(0xFF0B1020);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundTop, backgroundMid, backgroundBottom],
    stops: [0.0, 0.45, 1.0],
  );

  // Frosted glass controls
  static const Color glassFill = Color(0xA6283044); // rgba(40,48,68,.65)
  static const Color glassBorder = Color(0x24FFFFFF); // white 14%
  static const Color iconColor = Color(0xFFC9CDD6);
  static const Color labelColor = Color(0xFFD4D7DE);
  static const Color mutedText = Color(0xFFC4C8D2);

  // Premium gold, kept to thin borders, text and small icons
  static const Color gold = Color(0xFFE8C04A);
  static const Color goldBorder = Color(0xFFB8932E);
  static const Color goldFill = Color(0x73564614); // rgba(86,70,20,.45)
  static const Color goldPlus = Color(0xFFE0B43C);
  static const Color goldPlusFill = Color(0x59967A1E); // rgba(150,120,30,.35)
  static const Color vehicleCardFill = Color(0x8C2A2824); // rgba(42,40,36,.55)

  /// Rainbow rim stops, starting at 12 o'clock and running clockwise.
  static const List<Color> rimColors = [
    Color(0xFFFF4F6D),
    Color(0xFFFF9A4D),
    Color(0xFFFFE35C),
    Color(0xFF8BF06A),
    Color(0xFF3FE3C8),
    Color(0xFF45A6FF),
    Color(0xFF8A6BFF),
    Color(0xFFE05BE8),
    Color(0xFFFF4F6D),
  ];
  static const List<double> rimStops = [
    0.0,
    0.125,
    0.264,
    0.389,
    0.5,
    0.625,
    0.75,
    0.875,
    1.0,
  ];

  static const SweepGradient rimGradient = SweepGradient(
    colors: rimColors,
    stops: rimStops,
    // SweepGradient starts at 3 o'clock; rotate so red sits at the top.
    transform: GradientRotation(-math.pi / 2),
  );
}

/// Faint Union Jack canton (top left, fading into the background) and the
/// BVI coat of arms (top right), drawn behind the home-screen content.
class BviPrideWatermark extends StatelessWidget {
  const BviPrideWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topInset = MediaQuery.of(context).padding.top;
    // Layout is proportioned to a 412 dp wide reference screen and capped so
    // tablets don't get an oversized watermark.
    final w = math.min(size.width, 520.0);
    final scale = w / 412.0;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: -30 * scale,
            top: topInset,
            width: 236 * scale,
            height: 128 * scale,
            child: Opacity(
              opacity: 0.34,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const LinearGradient(
                  // Matches a 120deg CSS fade: solid near the top-left
                  // corner, gone by the lower right.
                  begin: Alignment(-0.87, -0.5),
                  end: Alignment(0.87, 0.5),
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0.0, 0.30, 0.88],
                ).createShader(rect),
                child: Image.asset(
                  'assets/images/bvi_union_canton.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          Positioned(
            left: size.width - (150 * scale),
            top: topInset + 64 * scale,
            width: 124 * scale,
            child: Opacity(
              opacity: 0.5,
              child: Image.asset(
                'assets/images/bvi_coat_of_arms.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted dark-glass circle with a thin rainbow rim and a soft rim glow.
/// Used as the BVI Pride surface of the home hero button.
class BviPrideHeroRing extends StatelessWidget {
  const BviPrideHeroRing({
    super.key,
    required this.size,
    required this.pressed,
    required this.child,
  });

  final double size;
  final bool pressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const rim = 2.5;
    final glowPad = size * 0.023;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Soft glow: a blurred copy of the rim behind the button.
          Positioned(
            left: -glowPad,
            top: -glowPad,
            right: -glowPad,
            bottom: -glowPad,
            child: IgnorePointer(
              child: Opacity(
                opacity: pressed ? 0.4 : 0.55,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: BviPrideHome.rimGradient,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Razor-thin rainbow rim.
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(rim),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: BviPrideHome.rimGradient,
            ),
            // Frosted dark glass interior with a soft top reflection.
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(0, -0.56),
                  radius: 0.95,
                  colors: pressed
                      ? const [
                          Color(0xFF474D5C),
                          Color(0xFF2E3442),
                          Color(0xFF1F2430),
                          Color(0xFF151923),
                        ]
                      : const [
                          Color(0xFF5A6070),
                          Color(0xFF3A4050),
                          Color(0xFF262B38),
                          Color(0xFF1A1E2A),
                        ],
                  stops: const [0.0, 0.32, 0.62, 1.0],
                ),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
