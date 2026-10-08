import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'premium_theme.dart';

/// Home-screen styling used only when the BVI Pride theme is active.
///
/// Every other theme keeps the existing home-screen treatment; callers check
/// [BviPrideHome.isActive] before using anything in this file.
///
/// Image sources:
/// - assets/images/bvi_map.png: island outlines from geoBoundaries
///   (gbOpen VGB ADM0, CC BY 4.0, traced from 2021 Sentinel-2 imagery).
///   CC BY 4.0 requires a credit line in the app.
/// - assets/images/bvi_flag.png: "Flag of the British Virgin Islands.svg"
///   from Wikimedia Commons (public domain).
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

  // Gold accents on the Add your vehicle card
  static const Color goldBorder = Color(0xFFB8932E);
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

  /// Largest text scale used inside the fixed-size hero ring. Android lets
  /// users raise font size to 200%, which would push the ring's text past
  /// the circle's edge.
  static const double heroMaxTextScale = 1.3;
}

/// Faint map of the British Virgin Islands across the top of the home
/// screen. Sized so the whole archipelago, Anegada included, fits between
/// the status bar and the hero button; the image's transparent margin and
/// built-in glow mean no edge of it shows.
class BviPrideWatermark extends StatelessWidget {
  const BviPrideWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topInset = MediaQuery.of(context).padding.top;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    // Proportioned to a 412 dp wide reference screen and capped so tablets
    // don't get an oversized map.
    final w = math.min(size.width, 520.0);
    final scale = w / 412.0;
    final mapWidth = 316 * scale;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: (size.width - mapWidth) / 2,
            top: topInset - 14 * scale,
            width: mapWidth,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/bvi_map.png',
                fit: BoxFit.contain,
                // Decode at display size rather than the full 1356 px.
                cacheWidth: (mapWidth * pixelRatio).round(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium marker for BVI Pride: a miniature BVI flag set in the same glass
/// capsule as the History and Alerts buttons, with a soft blue edge and glow
/// matching the island map.
class BviPremiumPin extends StatelessWidget {
  const BviPremiumPin({super.key, this.isTablet = false});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final flagWidth = isTablet ? 42.0 : 36.0;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    return Semantics(
      label: 'Premium',
      child: Container(
        width: isTablet ? 76 : 68,
        height: isTablet ? 42 : 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: BviPrideHome.glassFill,
          borderRadius: BorderRadius.circular(isTablet ? 21 : 19),
          border: Border.all(color: BviPrideHome.glassBorder, width: 1.5),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3.5),
            boxShadow: const [
              BoxShadow(color: Color(0x8CC8D6EE), spreadRadius: 1),
              BoxShadow(color: Color(0x6696B4E6), blurRadius: 12),
              BoxShadow(
                color: Color(0x73000000),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3.5),
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/bvi_flag.png',
                  width: flagWidth,
                  height: flagWidth / 2,
                  fit: BoxFit.cover,
                  // Decode at display size rather than the full 1200 px.
                  cacheWidth: (flagWidth * pixelRatio).round(),
                ),
                // Soft gloss, like an enamel pin.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: const Alignment(-0.6, -1),
                        end: const Alignment(0.6, 1),
                        colors: [
                          Colors.white.withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0.06),
                          Colors.white.withValues(alpha: 0.0),
                          const Color(0x1496B4E6),
                        ],
                        stops: const [0.0, 0.40, 0.42, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: BviPrideHome.heroMaxTextScale,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the BVI Pride hero ring is showing for the user's latest sent alert.
enum BviLiveKind { waiting, seen, fiveMinutes, moving, cantMove, wrongCar }

/// A live state for the hero ring, built from the most recent sent alert.
class BviLiveStatus {
  const BviLiveStatus({
    required this.kind,
    required this.start,
    required this.window,
    this.plate,
  });

  final BviLiveKind kind;
  final DateTime start;
  final Duration window;

  /// Plate text, only known when the alert was sent from this device during
  /// the current session (alerts themselves only store a plate hash).
  final String? plate;

  /// The app's own reply window for a sent alert (see UnacknowledgedAlertService).
  static const Duration replyWindow = Duration(minutes: 10);
  static const Duration fiveMinuteWindow = Duration(minutes: 5);
  static const Duration replyFlash = Duration(seconds: 6);

  bool get isCountdown =>
      kind == BviLiveKind.waiting ||
      kind == BviLiveKind.seen ||
      kind == BviLiveKind.fiveMinutes;

  DateTime get endsAt => start.add(window);

  bool isActiveAt(DateTime now) => now.isBefore(endsAt);

  /// Picks the ring state for the latest sent alert, or null when nothing is
  /// live and the normal "Tap to alert" button should show.
  ///
  /// [responseSeenAt] is when this device first received the reply; replies
  /// that arrived in an earlier session have none and are not shown.
  static BviLiveStatus? fromLatestAlert({
    required DateTime createdAt,
    DateTime? readAt,
    String? response,
    DateTime? responseSeenAt,
    String? plate,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    BviLiveStatus? status;

    if (response == null) {
      status = BviLiveStatus(
        kind: readAt != null ? BviLiveKind.seen : BviLiveKind.waiting,
        start: createdAt.toLocal(),
        window: replyWindow,
        plate: plate,
      );
    } else if (responseSeenAt != null) {
      final kind = switch (response) {
        '5_minutes' => BviLiveKind.fiveMinutes,
        'moving_now' => BviLiveKind.moving,
        'cant_move' => BviLiveKind.cantMove,
        'wrong_car' => BviLiveKind.wrongCar,
        _ => null,
      };
      if (kind != null) {
        status = BviLiveStatus(
          kind: kind,
          start: responseSeenAt,
          window:
              kind == BviLiveKind.fiveMinutes ? fiveMinuteWindow : replyFlash,
          plate: plate,
        );
      }
    }

    if (status == null || !status.isActiveAt(current)) return null;
    return status;
  }
}

/// BVI Pride hero ring in a live state: the rainbow rim becomes a countdown
/// (or a full ring for a reply), with the status shown inside the circle.
/// Ticks itself once a second and calls [onExpired] when the state ends so
/// the home screen can return to the normal button.
class BviPrideLiveRing extends StatefulWidget {
  const BviPrideLiveRing({
    super.key,
    required this.size,
    required this.pressed,
    required this.status,
    required this.onExpired,
  });

  final double size;
  final bool pressed;
  final BviLiveStatus status;
  final VoidCallback onExpired;

  @override
  State<BviPrideLiveRing> createState() => _BviPrideLiveRingState();
}

class _BviPrideLiveRingState extends State<BviPrideLiveRing> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    if (!widget.status.isActiveAt(DateTime.now())) {
      _ticker?.cancel();
      widget.onExpired();
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final remaining = status.endsAt.difference(DateTime.now());
    final clamped = remaining.isNegative ? Duration.zero : remaining;
    final progress = status.isCountdown
        ? (clamped.inMilliseconds / status.window.inMilliseconds)
            .clamp(0.0, 1.0)
        : 1.0;
    const rim = 2.5;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BviArcRingPainter(
                  progress: progress,
                  rimWidth: rim,
                  glowOpacity: status.isCountdown ? 0.45 : 0.75,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(rim),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(0, -0.56),
                  radius: 0.95,
                  colors: widget.pressed
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
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: BviPrideHome.heroMaxTextScale,
                child: Center(child: _buildContent(status, clamped)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BviLiveStatus status, Duration remaining) {
    final mm = remaining.inMinutes;
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    String? label;
    IconData? labelIcon;
    String headline;
    String caption;
    IconData? bigIcon;

    switch (status.kind) {
      case BviLiveKind.waiting:
        label = 'SENT · WAITING';
        labelIcon = Icons.send_rounded;
        headline = '$mm:$ss';
        caption = 'Waiting for reply';
      case BviLiveKind.seen:
        label = 'SEEN';
        labelIcon = Icons.visibility_outlined;
        headline = '$mm:$ss';
        caption = "They've seen your alert";
      case BviLiveKind.fiveMinutes:
        label = '5-MINUTE COUNTDOWN';
        headline = '$mm:$ss';
        caption = 'Give them 5 minutes';
      case BviLiveKind.moving:
        bigIcon = Icons.check_circle_outline_rounded;
        headline = "They're moving!";
        caption = 'Replied just now';
      case BviLiveKind.cantMove:
        bigIcon = Icons.do_not_disturb_on_outlined;
        headline = "Can't move right now";
        caption = 'Replied just now';
      case BviLiveKind.wrongCar:
        bigIcon = Icons.help_outline_rounded;
        headline = 'Wrong car!';
        caption = 'Replied just now';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null)
            // Shrinks rather than overflowing the circle at large font sizes.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (labelIcon != null) ...[
                    Icon(labelIcon, size: 14, color: BviPrideHome.mutedText),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: BviPrideHome.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          if (bigIcon != null) Icon(bigIcon, size: 52, color: Colors.white),
          const SizedBox(height: 6),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: status.isCountdown ? 44 : 21,
              fontWeight: FontWeight.w700,
              height: 1.05,
              color: Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: BviPrideHome.mutedText,
            ),
          ),
          if (status.plate != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Text(
                status.plate!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Rainbow rim drawn as an arc for [progress] (1.0 = full ring), with a dim
/// track for the elapsed part, a soft glow and a bright dot at the arc's end.
class _BviArcRingPainter extends CustomPainter {
  _BviArcRingPainter({
    required this.progress,
    required this.rimWidth,
    required this.glowOpacity,
  });

  final double progress;
  final double rimWidth;
  final double glowOpacity;

  static const Color _track = Color(0xFF2A2F3D);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - rimWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final shader = BviPrideHome.rimGradient.createShader(rect);
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;

    if (progress < 1.0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rimWidth
          ..color = _track,
      );
    }
    if (sweep <= 0) return;

    // Glow
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..shader = shader
        ..color = Colors.white.withValues(alpha: glowOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    // Crisp rim
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rimWidth
        ..strokeCap = progress < 1.0 ? StrokeCap.round : StrokeCap.butt
        ..shader = shader,
    );

    if (progress < 1.0) {
      final end = start + sweep;
      final tip = center + Offset(math.cos(end), math.sin(end)) * radius;
      canvas.drawCircle(
        tip,
        7,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(tip, 4, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_BviArcRingPainter old) =>
      old.progress != progress ||
      old.rimWidth != rimWidth ||
      old.glowOpacity != glowOpacity;
}
