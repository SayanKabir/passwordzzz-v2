import 'package:flutter/animation.dart';

/// Shared motion vocabulary. One place to tune the app's feel.
///
/// v1 used ad-hoc values (a 100ms slide, a 300ms scale dialog) with no
/// relationship to each other, which reads as inconsistent rather than fast.
abstract final class Motion {
  /// State changes the user already expects: toggles, ripples, checkmarks.
  static const instant = Duration(milliseconds: 120);

  /// The default for most transitions: sheets, fades, list reorders.
  static const quick = Duration(milliseconds: 220);

  /// Larger surfaces travelling further: page pushes, hero flights.
  static const moderate = Duration(milliseconds: 320);

  /// Deliberate, attention-carrying motion: unlock reveal, onboarding.
  static const slow = Duration(milliseconds: 480);

  /// Standard easing for elements entering the screen.
  static const enter = Curves.easeOutCubic;

  /// Elements leaving should move faster than they arrived.
  static const exit = Curves.easeInCubic;

  /// Symmetric moves that both start and end on-screen.
  static const standard = Curves.easeInOutCubic;

  /// Slight overshoot for anything that should feel physical: FAB, sheets.
  static const spring = Curves.easeOutBack;

  /// Emphasized curve for the vault unlock reveal.
  static const emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
}

/// Spacing scale (4pt grid). Prevents the drifting 5/7/13px padding in v1.
abstract final class Space {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const huge = 48.0;
}

/// Corner radii.
abstract final class Radii {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 18.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

/// Fixed row height for the vault list. Declared here because
/// `ListView.builder` uses it as `itemExtent`, which makes scroll extent O(1)
/// instead of O(n) — the single cheapest scrolling win available.
const double kVaultRowExtent = 72.0;
