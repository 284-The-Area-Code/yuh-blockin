import 'package:flutter/material.dart';

import '../theme/premium_theme.dart';

/// Shape of the spotlight cutout around a coach mark's target.
enum CoachMarkShape { circle, roundedRect }

/// One step in a [CoachMarkTour]: a real on-screen widget (via [key]) plus
/// the copy to show next to it. The target must already be laid out (have a
/// valid [RenderBox]) by the time the tour reaches this step.
class CoachMarkStep {
  const CoachMarkStep({
    required this.key,
    required this.title,
    required this.description,
    this.shape = CoachMarkShape.roundedRect,
    this.padding = 10.0,
  });

  final GlobalKey key;
  final String title;
  final String description;
  final CoachMarkShape shape;
  final double padding;
}

/// Shows an animated, interactive spotlight tour over real app UI.
///
/// Each step dims the screen except for a cutout around the target widget's
/// actual on-screen position (measured live via [RenderBox], not hardcoded
/// coordinates), with a coach-mark tooltip anchored next to it. Tapping the
/// spotlight, or the tooltip's Next button, advances to the next step with
/// an animated transition between target rects.
class CoachMarkTour {
  CoachMarkTour._();

  static OverlayEntry? _entry;

  static bool get isShowing => _entry != null;

  static void show(
    BuildContext context, {
    required List<CoachMarkStep> steps,
    VoidCallback? onComplete,
  }) {
    if (steps.isEmpty) return;
    dismiss();

    final overlayState = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CoachMarkOverlay(
        steps: steps,
        onFinished: () {
          entry.remove();
          if (identical(_entry, entry)) {
            _entry = null;
          }
          onComplete?.call();
        },
      ),
    );
    _entry = entry;
    overlayState.insert(entry);
  }

  /// Removes the tour overlay immediately, without calling onComplete. Safe
  /// to call even when no tour is showing.
  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _CoachMarkOverlay extends StatefulWidget {
  const _CoachMarkOverlay({required this.steps, required this.onFinished});

  final List<CoachMarkStep> steps;
  final VoidCallback onFinished;

  @override
  State<_CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<_CoachMarkOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;

  int _index = 0;
  Rect? _previousRect;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToStep(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Rect? _measure(int index) {
    final renderObject = widget.steps[index].key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return null;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return (topLeft & renderObject.size).inflate(widget.steps[index].padding);
  }

  void _goToStep(int index) {
    final rect = _measure(index);
    if (rect == null) {
      // Target isn't on screen right now (e.g. vehicle card absent before
      // setup) — skip it rather than spotlighting an empty area.
      _advance(fromIndex: index);
      return;
    }
    setState(() {
      _previousRect = _targetRect ?? rect;
      _targetRect = rect;
      _index = index;
    });
    _controller.forward(from: 0);
  }

  void _advance({int? fromIndex}) {
    final current = fromIndex ?? _index;
    final next = current + 1;
    if (next >= widget.steps.length) {
      widget.onFinished();
    } else {
      _goToStep(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_targetRect == null) {
      // Nothing measured yet (first frame still pending) — render nothing
      // rather than a full-screen black flash.
      return const SizedBox.shrink();
    }

    final step = widget.steps[_index];
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, _) {
        final rect = Rect.lerp(_previousRect, _targetRect, _curve.value)!;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _advance,
                child: CustomPaint(
                  painter: _SpotlightPainter(rect: rect, shape: step.shape),
                ),
              ),
            ),
            _CoachMarkTooltip(
              rect: rect,
              title: step.title,
              description: step.description,
              stepIndex: _index,
              stepCount: widget.steps.length,
              onNext: _advance,
              onSkip: widget.onFinished,
            ),
          ],
        );
      },
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.rect, required this.shape});

  final Rect rect;
  final CoachMarkShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final scrimPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = shape == CoachMarkShape.circle
        ? (Path()..addOval(rect))
        : (Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(18))));

    final scrim = Path.combine(PathOperation.difference, scrimPath, holePath);
    canvas.drawPath(scrim, Paint()..color = Colors.black.withValues(alpha: 0.78));

    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    if (shape == CoachMarkShape.circle) {
      canvas.drawOval(rect, ringPaint);
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(18)), ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.rect != rect || oldDelegate.shape != shape;
}

class _CoachMarkTooltip extends StatelessWidget {
  const _CoachMarkTooltip({
    required this.rect,
    required this.title,
    required this.description,
    required this.stepIndex,
    required this.stepCount,
    required this.onNext,
    required this.onSkip,
  });

  final Rect rect;
  final String title;
  final String description;
  final int stepIndex;
  final int stepCount;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeTop = MediaQuery.of(context).padding.top + 16;
    final safeBottom = MediaQuery.of(context).padding.bottom + 16;

    final spaceBelow = screenSize.height - rect.bottom;
    final spaceAbove = rect.top;
    final showBelow = spaceBelow >= 190 || spaceBelow >= spaceAbove;

    final isLast = stepIndex + 1 == stepCount;

    return Positioned(
      left: 24,
      right: 24,
      top: showBelow ? rect.bottom + 16 : null,
      bottom: showBelow ? null : (screenSize.height - rect.top) + 16,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenSize.height - safeTop - safeBottom,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            decoration: BoxDecoration(
              color: PremiumTheme.surfaceColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${stepIndex + 1} of $stepCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: PremiumTheme.accentColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: PremiumTheme.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: PremiumTheme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: onSkip,
                      child: Text(
                        'Skip',
                        style: TextStyle(color: PremiumTheme.tertiaryTextColor),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PremiumTheme.accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(isLast ? 'Done' : 'Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
