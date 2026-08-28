import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/motion.dart';

/// Glass surfaces, split into two implementations.
///
/// A real `BackdropFilter` is a full-screen GPU readback. The test device is a
/// Snapdragon 710, where stacking several is the single most likely source of
/// dropped frames — which fights the whole point of the app. So there are two
/// treatments and a rule: **at most one [BlurGlass] on screen at a time.**
/// Everything else uses [FauxGlass], which reads as glass through layered
/// translucency, a hairline top highlight, and a border gradient — at zero blur
/// cost.
///
/// [GlassScope] lets a screen switch its app bar to the cheap treatment while a
/// sheet owns the one blur budget.
class GlassScope extends InheritedWidget {
  const GlassScope({
    super.key,
    required this.blurAvailable,
    required super.child,
  });

  /// False while another surface (a sheet, a dialog) owns the blur budget.
  final bool blurAvailable;

  static bool of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<GlassScope>()
            ?.blurAvailable ??
        true;
  }

  @override
  bool updateShouldNotify(GlassScope old) =>
      old.blurAvailable != blurAvailable;
}

/// The one genuinely blurred surface. Falls back to [FauxGlass] automatically
/// when the blur budget is already spent.
class BlurGlass extends StatelessWidget {
  const BlurGlass({
    super.key,
    required this.child,
    this.sigma = 18,
    this.borderRadius,
    this.tintOpacity = 0.72,
    this.showTopHighlight = true,
  });

  final Widget child;
  final double sigma;
  final BorderRadius? borderRadius;
  final double tintOpacity;
  final bool showTopHighlight;

  @override
  Widget build(BuildContext context) {
    if (!GlassScope.of(context)) {
      return FauxGlass(
        borderRadius: borderRadius,
        tintOpacity: tintOpacity,
        showTopHighlight: showTopHighlight,
        child: child,
      );
    }

    final c = AppColors.of(context);
    final radius = borderRadius ?? BorderRadius.zero;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: tintOpacity),
            borderRadius: radius,
          ),
          child: _TopHighlight(
            enabled: showTopHighlight,
            radius: radius,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Glass without the blur. Two stacked translucent fills plus a one-pixel
/// highlight along the top edge; the highlight is what actually sells the
/// material, not the blur.
class FauxGlass extends StatelessWidget {
  const FauxGlass({
    super.key,
    required this.child,
    this.borderRadius,
    this.tintOpacity = 0.86,
    this.showTopHighlight = true,
    this.elevated = false,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final double tintOpacity;
  final bool showTopHighlight;

  /// Adds a soft ambient shadow for surfaces that float (FAB, sheets).
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final radius = borderRadius ?? BorderRadius.zero;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: c.border),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(
              Colors.white.withValues(alpha: dark ? 0.06 : 0.55),
              c.surfaceRaised.withValues(alpha: tintOpacity),
            ),
            c.surfaceRaised.withValues(alpha: tintOpacity),
          ],
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.44 : 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: _TopHighlight(
        enabled: showTopHighlight,
        radius: radius,
        child: child,
      ),
    );
  }
}

/// A one-pixel light along the top edge, fading out toward the corners. This is
/// the detail that makes a translucent panel read as a pane of glass catching a
/// light source rather than a flat scrim.
class _TopHighlight extends StatelessWidget {
  const _TopHighlight({
    required this.enabled,
    required this.radius,
    required this.child,
  });

  final bool enabled;
  final BorderRadius radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: radius.topLeft.x,
          right: radius.topRight.x,
          height: 1,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: dark ? 0.16 : 0.85),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Centered extended FAB in glass. Minimal — no glow, no elevation ring.
class GlassFab extends StatelessWidget {
  const GlassFab({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    const radius = BorderRadius.all(Radius.circular(Radii.pill));

    return FauxGlass(
      borderRadius: radius,
      elevated: true,
      tintOpacity: 0.92,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.xl,
              vertical: Space.md + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 19, color: c.brand),
                const SizedBox(width: Space.sm),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
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
