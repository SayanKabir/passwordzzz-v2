import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/motion.dart';

/// The Passwordzzz mark: a sleeping padlock whose mouth is a keyhole, with two
/// z's drifting up and to the right.
///
/// Painted rather than shipped as an asset. The v1 PNGs were solid white, so
/// they vanished on light surfaces and had to be tinted after the fact; they
/// also softened badly at app-bar size. A painter is crisp at every size, takes
/// its color from the theme, and can animate — which the drifting z's need.
///
/// Geometry is authored on a 96x96 grid and scaled to the requested size.
class PasswordzzzMark extends StatelessWidget {
  const PasswordzzzMark({
    super.key,
    this.size = 28,
    this.color,
    this.faceColor,
    this.drift = 0,
  });

  final double size;

  /// Defaults to the brand token.
  final Color? color;

  /// The knocked-out face (eyes + keyhole). Defaults to the surface behind the
  /// mark so the face reads as a cutout rather than a painted shape.
  final Color? faceColor;

  /// 0..1 breathing phase for the z's. 0 is at rest.
  final double drift;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MarkPainter(
          color: color ?? c.brand,
          faceColor: faceColor ?? c.surface,
          drift: drift,
        ),
      ),
    );
  }
}

/// [PasswordzzzMark] with the z's gently rising — used on the lock screen so
/// the vault reads as asleep rather than merely closed.
class BreathingPasswordzzzMark extends StatefulWidget {
  const BreathingPasswordzzzMark({super.key, this.size = 72, this.color});

  final double size;
  final Color? color;

  @override
  State<BreathingPasswordzzzMark> createState() =>
      _BreathingPasswordzzzMarkState();
}

class _BreathingPasswordzzzMarkState extends State<BreathingPasswordzzzMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => PasswordzzzMark(
          size: widget.size,
          color: widget.color,
          drift: _c.value,
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({
    required this.color,
    required this.faceColor,
    required this.drift,
  });

  final Color color;
  final Color faceColor;
  final double drift;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 96.0;
    canvas.save();
    canvas.scale(s);

    final body = Paint()
      ..color = color
      ..isAntiAlias = true;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final face = Paint()
      ..color = faceColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5
      ..isAntiAlias = true;

    // Shackle: two uprights joined by a semicircle centred on (44, 38).
    final shackle = Path()
      ..moveTo(29, 48)
      ..lineTo(29, 38)
      ..arcToPoint(
        const Offset(55, 38),
        radius: const Radius.circular(13),
        clockwise: true,
      )
      ..lineTo(55, 48);
    canvas.drawPath(shackle, stroke..strokeWidth = 7.5);

    // Body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(12, 48, 60, 39),
        const Radius.circular(12.5),
      ),
      body,
    );

    // Closed eyes — quadratic arcs bulging downward.
    canvas.drawPath(
      Path()
        ..moveTo(25, 63)
        ..quadraticBezierTo(31, 70, 37, 63),
      face,
    );
    canvas.drawPath(
      Path()
        ..moveTo(47, 63)
        ..quadraticBezierTo(53, 70, 59, 63),
      face,
    );

    // Keyhole mouth: bore plus a tapered stem. The stem is sub-pixel below
    // ~18px and simply disappears, leaving a round mouth — which is the
    // correct reading at that size anyway.
    canvas.drawCircle(
      const Offset(42, 74),
      3.6,
      Paint()
        ..color = faceColor
        ..isAntiAlias = true,
    );
    canvas.drawPath(
      Path()
        ..moveTo(40.4, 76.4)
        ..lineTo(39.4, 81)
        ..lineTo(44.6, 81)
        ..lineTo(43.6, 76.4)
        ..close(),
      Paint()
        ..color = faceColor
        ..isAntiAlias = true,
    );

    // Two z's, ascending. `drift` lifts and fades them on a sine so the loop
    // has no seam.
    final phase = math.sin(drift * 2 * math.pi);
    _drawZ(canvas, stroke, x: 67, y: 23 + phase * 1.6, w: 13, h: 15, sw: 5.6,
        opacity: 1.0);
    _drawZ(canvas, stroke, x: 82, y: 3 + phase * 2.6, w: 11, h: 13, sw: 4.8,
        opacity: 0.62);

    canvas.restore();
  }

  void _drawZ(
    Canvas canvas,
    Paint stroke, {
    required double x,
    required double y,
    required double w,
    required double h,
    required double sw,
    required double opacity,
  }) {
    final p = Path()
      ..moveTo(x, y)
      ..lineTo(x + w, y)
      ..lineTo(x, y + h)
      ..lineTo(x + w, y + h);
    canvas.drawPath(
      p,
      stroke
        ..strokeWidth = sw
        ..color = color.withValues(alpha: opacity),
    );
    stroke.color = color;
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.color != color || old.faceColor != faceColor || old.drift != drift;
}

/// Mark + wordmark lockup for the app bar. Tapping it opens Settings, which is
/// how every app in this family exposes settings — there is no gear icon.
class PasswordzzzWordmark extends StatelessWidget {
  const PasswordzzzWordmark({super.key, this.markSize = 26, this.onTap});

  final double markSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.sm,
          vertical: Space.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PasswordzzzMark(size: markSize),
            const SizedBox(width: Space.sm),
            Text(
              'Passwordzzz',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: markSize * 0.78,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: c.textPrimary,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
