import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Small, reusable BVI Pride visual-identity primitives.
///
/// These are deliberately "dumb" widgets - they take explicit colors from
/// the caller rather than reading PremiumTheme internally, so they stay
/// reusable and are harmless if ever instantiated outside BVI Pride mode
/// (they just paint whatever colors they're given).
///
/// Design intent (see docs on each widget): abstract the flag/lamp/coat-of-
/// arms rather than render them literally. No invented heraldry, no literal
/// flag graphics, no scattering motifs across unrelated screens.

/// A stylized oil-lamp silhouette, replacing the generic flame icon
/// previously used to represent Saint Ursula's lamp. Deliberately abstract -
/// a simple rounded bowl + spout + small glow-colored flame-tip - not an
/// attempt to render the actual coat-of-arms figure.
class BviOilLampIcon extends StatelessWidget {
  const BviOilLampIcon({
    super.key,
    this.size = 24,
    required this.color,
    this.glowColor,
    this.glowOpacity = 0.6,
  });

  final double size;
  final Color color;
  final Color? glowColor;
  final double glowOpacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BviOilLampPainter(
          color: color,
          glowColor: glowColor ?? color,
          glowOpacity: glowOpacity,
        ),
      ),
    );
  }
}

class _BviOilLampPainter extends CustomPainter {
  _BviOilLampPainter({
    required this.color,
    required this.glowColor,
    required this.glowOpacity,
  });

  final Color color;
  final Color glowColor;
  final double glowOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, w * 0.06)
      ..strokeCap = StrokeCap.round
      ..color = color;
    final bodyFill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.15);

    // Lamp bowl: a shallow rounded-bottom vessel occupying the lower ~55%.
    final bowlRect = Rect.fromLTWH(w * 0.14, h * 0.46, w * 0.58, h * 0.34);
    final bowlPath = Path()
      ..moveTo(bowlRect.left, bowlRect.top)
      ..quadraticBezierTo(
        bowlRect.left,
        bowlRect.bottom,
        bowlRect.left + bowlRect.width * 0.5,
        bowlRect.bottom,
      )
      ..quadraticBezierTo(
        bowlRect.right,
        bowlRect.bottom,
        bowlRect.right,
        bowlRect.top,
      );
    canvas.drawPath(bowlPath, bodyFill);
    canvas.drawPath(bowlPath, bodyStroke);

    // Spout: a small triangular nose extending right, classic lamp profile.
    final spout = Path()
      ..moveTo(bowlRect.right - w * 0.04, bowlRect.top + h * 0.03)
      ..lineTo(w * 0.92, h * 0.58)
      ..lineTo(bowlRect.right - w * 0.04, bowlRect.top + h * 0.14)
      ..close();
    canvas.drawPath(spout, bodyFill);
    canvas.drawPath(spout, bodyStroke);

    // Base: a short foot beneath the bowl.
    canvas.drawLine(
      Offset(w * 0.32, bowlRect.bottom),
      Offset(w * 0.32, h * 0.92),
      bodyStroke,
    );
    canvas.drawLine(
      Offset(w * 0.2, h * 0.92),
      Offset(w * 0.44, h * 0.92),
      bodyStroke,
    );

    // Flame-tip: small filled teardrop above the bowl, in the glow color at
    // reduced opacity so it reads as "light" rather than a literal flame.
    final flameCenter = Offset(w * 0.4, h * 0.3);
    final flamePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = glowColor.withValues(alpha: glowOpacity);
    final flame = Path()
      ..moveTo(flameCenter.dx, h * 0.1)
      ..quadraticBezierTo(
        flameCenter.dx + w * 0.1,
        flameCenter.dy,
        flameCenter.dx,
        h * 0.46,
      )
      ..quadraticBezierTo(
        flameCenter.dx - w * 0.1,
        flameCenter.dy,
        flameCenter.dx,
        h * 0.1,
      )
      ..close();
    canvas.drawPath(flame, flamePaint);
  }

  @override
  bool shouldRepaint(covariant _BviOilLampPainter oldDelegate) {
    return color != oldDelegate.color ||
        glowColor != oldDelegate.glowColor ||
        glowOpacity != oldDelegate.glowOpacity;
  }
}

/// Eleven small, low-opacity dots evenly spaced in a ring - a faint
/// identity/Easter-egg detail referencing Saint Ursula's eleven companions,
/// not a loud UI element. Intended to sit behind/around a single circular
/// emblem (the theme-picker preview circle, or very faintly around the
/// home-screen hero button) - never scattered through the app.
class BviElevenLampRing extends StatelessWidget {
  const BviElevenLampRing({
    super.key,
    required this.diameter,
    required this.lampColor,
    this.opacity = 0.35,
    this.dotRadius = 1.5,
  });

  final double diameter;
  final Color lampColor;
  final double opacity;
  final double dotRadius;

  static const int _lampCount = 11;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: CustomPaint(
          painter: _BviElevenLampRingPainter(
            color: lampColor.withValues(alpha: opacity),
            dotRadius: dotRadius,
          ),
        ),
      ),
    );
  }
}

class _BviElevenLampRingPainter extends CustomPainter {
  _BviElevenLampRingPainter({required this.color, required this.dotRadius});

  final Color color;
  final double dotRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (var i = 0; i < BviElevenLampRing._lampCount; i++) {
      final angle = (2 * math.pi / BviElevenLampRing._lampCount) * i - math.pi / 2;
      final dot = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawCircle(dot, dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BviElevenLampRingPainter oldDelegate) {
    return color != oldDelegate.color || dotRadius != oldDelegate.dotRadius;
  }
}

/// A handful of very thin, very low-opacity diagonal hairlines, inspired by
/// the Union Jack's intersecting geometry but fully abstracted - no
/// recognizable flag silhouette, just restrained background texture.
/// Intended as a Positioned.fill layer behind existing content.
class BviFlagGeometryOverlay extends StatelessWidget {
  const BviFlagGeometryOverlay({
    super.key,
    this.opacity = 0.06,
    required this.blueLine,
    required this.redLine,
    required this.whiteLine,
  });

  final double opacity;
  final Color blueLine;
  final Color redLine;
  final Color whiteLine;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _BviFlagGeometryPainter(
          blueLine: blueLine.withValues(alpha: opacity),
          redLine: redLine.withValues(alpha: opacity),
          whiteLine: whiteLine.withValues(alpha: opacity * 0.8),
        ),
      ),
    );
  }
}

class _BviFlagGeometryPainter extends CustomPainter {
  _BviFlagGeometryPainter({
    required this.blueLine,
    required this.redLine,
    required this.whiteLine,
  });

  final Color blueLine;
  final Color redLine;
  final Color whiteLine;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void diagonal(Color color, double strokeWidth, double offsetFraction) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = color;
      final dx = w * offsetFraction;
      canvas.drawLine(Offset(dx, 0), Offset(0, h * offsetFraction + h * 0.4), paint);
      canvas.drawLine(Offset(w - dx, h), Offset(w, h - h * offsetFraction - h * 0.4), paint);
    }

    diagonal(blueLine, 1.0, 0.1);
    diagonal(redLine, 0.75, 0.22);
    diagonal(whiteLine, 0.75, 0.34);
  }

  @override
  bool shouldRepaint(covariant _BviFlagGeometryPainter oldDelegate) {
    return blueLine != oldDelegate.blueLine ||
        redLine != oldDelegate.redLine ||
        whiteLine != oldDelegate.whiteLine;
  }
}
