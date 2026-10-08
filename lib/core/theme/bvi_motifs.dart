import 'package:flutter/material.dart';

/// Small, reusable BVI Pride visual-identity primitives.
///
/// These are deliberately "dumb" widgets - they take explicit colors from
/// the caller rather than reading PremiumTheme internally, so they stay
/// reusable and are harmless if ever instantiated outside BVI Pride mode
/// (they just paint whatever colors they're given).
///
/// Design intent (see docs on each widget): abstract the flag rather than
/// render it literally. No invented heraldry, no scattering motifs across
/// unrelated screens.

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
