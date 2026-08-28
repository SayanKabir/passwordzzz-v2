import 'package:flutter/material.dart';

/// Brand + semantic color tokens.
///
/// v1 hardcoded `0xff0ba99b` and `0xffddfffa` at ~40 call sites and branched on
/// `isDarkMode` inline. Everything here is resolved through [AppColors.of] so a
/// widget never needs to know which theme is active.
abstract final class BrandColors {
  static const seed = Color(0xFF0BA99B);

  static const teal900 = Color(0xFF04322E);
  static const teal700 = Color(0xFF067068);
  static const teal500 = Color(0xFF0BA99B);
  static const teal300 = Color(0xFF5FD3C8);
  static const teal100 = Color(0xFFDDFFFA);
}

/// Semantic tokens, resolved per brightness.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brand,
    required this.brandMuted,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textOnBrand,
    required this.scrim,
    required this.strengthWeak,
    required this.strengthFair,
    required this.strengthGood,
    required this.strengthStrong,
    required this.danger,
  });

  final Color brand;
  final Color brandMuted;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textOnBrand;

  /// Tinted overlay used instead of a second [BackdropFilter]. v1 stacked four
  /// simultaneous blurs; each one is a full-screen GPU readback.
  final Color scrim;

  final Color strengthWeak;
  final Color strengthFair;
  final Color strengthGood;
  final Color strengthStrong;
  final Color danger;

  static const light = AppColors(
    brand: BrandColors.teal500,
    brandMuted: BrandColors.teal100,
    surface: Color(0xFFF7FAFA),
    surfaceRaised: Colors.white,
    surfaceSunken: Color(0xFFEDF3F3),
    border: Color(0x14000000),
    textPrimary: Color(0xFF0B1A19),
    textSecondary: Color(0xFF5A6B6A),
    textOnBrand: Colors.white,
    scrim: Color(0x99F7FAFA),
    strengthWeak: Color(0xFFE5484D),
    strengthFair: Color(0xFFF5A524),
    strengthGood: Color(0xFF30A46C),
    strengthStrong: BrandColors.teal500,
    danger: Color(0xFFE5484D),
  );

  static const dark = AppColors(
    brand: BrandColors.teal300,
    brandMuted: Color(0xFF0A2E2B),
    surface: Color(0xFF0B1110),
    surfaceRaised: Color(0xFF141C1B),
    surfaceSunken: Color(0xFF070C0B),
    border: Color(0x1FFFFFFF),
    textPrimary: Color(0xFFE8F1F0),
    textSecondary: Color(0xFF8FA5A3),
    textOnBrand: Color(0xFF04322E),
    scrim: Color(0xB30B1110),
    strengthWeak: Color(0xFFFF6369),
    strengthFair: Color(0xFFFFB224),
    strengthGood: Color(0xFF4CC38A),
    strengthStrong: BrandColors.teal300,
    danger: Color(0xFFFF6369),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? brand,
    Color? brandMuted,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textOnBrand,
    Color? scrim,
    Color? strengthWeak,
    Color? strengthFair,
    Color? strengthGood,
    Color? strengthStrong,
    Color? danger,
  }) {
    return AppColors(
      brand: brand ?? this.brand,
      brandMuted: brandMuted ?? this.brandMuted,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textOnBrand: textOnBrand ?? this.textOnBrand,
      scrim: scrim ?? this.scrim,
      strengthWeak: strengthWeak ?? this.strengthWeak,
      strengthFair: strengthFair ?? this.strengthFair,
      strengthGood: strengthGood ?? this.strengthGood,
      strengthStrong: strengthStrong ?? this.strengthStrong,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      brand: Color.lerp(brand, other.brand, t)!,
      brandMuted: Color.lerp(brandMuted, other.brandMuted, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textOnBrand: Color.lerp(textOnBrand, other.textOnBrand, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      strengthWeak: Color.lerp(strengthWeak, other.strengthWeak, t)!,
      strengthFair: Color.lerp(strengthFair, other.strengthFair, t)!,
      strengthGood: Color.lerp(strengthGood, other.strengthGood, t)!,
      strengthStrong: Color.lerp(strengthStrong, other.strengthStrong, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}
