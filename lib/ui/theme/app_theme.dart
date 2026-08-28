import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'motion.dart';

/// Builds the light/dark [ThemeData]. Widgets read tokens via
/// `AppColors.of(context)` and `Theme.of(context).textTheme` — never by
/// branching on an `isDarkMode` boolean, which is how v1 did it.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, AppColors.light);
  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final scheme = ColorScheme.fromSeed(
      seedColor: BrandColors.seed,
      brightness: brightness,
    ).copyWith(
      primary: c.brand,
      onPrimary: c.textOnBrand,
      surface: c.surface,
      onSurface: c.textPrimary,
      error: c.danger,
    );

    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: c.surface,
      extensions: [c],
      textTheme: _textTheme(base.textTheme, c),
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: c.surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: c.border),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceSunken,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: c.brand, width: 1.5),
        ),
        hintStyle: TextStyle(color: c.textSecondary),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.brand,
          foregroundColor: c.textOnBrand,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          textStyle: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.brand,
        foregroundColor: c.textOnBrand,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),

      dividerTheme: DividerThemeData(color: c.border, space: 1, thickness: 1),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.surfaceRaised,
        contentTextStyle: TextStyle(color: c.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),

      // FadeForwards is the Material 3 shared-axis push: content slides a
      // short distance and cross-fades, which reads faster than Zoom's scale.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, AppColors c) {
    // Montserrat for headings/labels, Inter for body — Inter is designed for
    // small UI text and has proper tabular figures, which matters for the
    // entropy readouts and TOTP countdowns.
    final display = GoogleFonts.montserratTextTheme(base);
    final body = GoogleFonts.interTextTheme(base);

    return base
        .copyWith(
          displayLarge: display.displayLarge,
          displayMedium: display.displayMedium,
          displaySmall: display.displaySmall,
          headlineLarge: display.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: display.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: display.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          titleMedium: display.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          titleSmall: display.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          bodyLarge: body.bodyLarge,
          bodyMedium: body.bodyMedium,
          bodySmall: body.bodySmall,
          labelLarge: display.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          labelMedium: display.labelMedium,
          labelSmall: display.labelSmall,
        )
        .apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);
  }
}
