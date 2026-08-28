import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The shipped logo assets are solid white with transparency, which vanishes
/// against a light background. Tinting them with the brand color keeps one
/// asset legible in both themes instead of shipping a second copy.
class BrandLogo extends StatelessWidget {
  const BrandLogo.mark({super.key, this.size = 72})
    : _asset = 'assets/logo-small.png',
      _height = null;

  const BrandLogo.wordmark({super.key, double height = 26})
    : _asset = 'assets/logo-full.png',
      _height = height,
      size = null;

  final String _asset;
  final double? _height;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Image.asset(
      _asset,
      width: size,
      height: _height ?? size,
      filterQuality: FilterQuality.medium,
      color: c.brand,
      // The assets are single-color silhouettes, so srcIn recolors them
      // wholesale while preserving the alpha edges.
      colorBlendMode: BlendMode.srcIn,
      excludeFromSemantics: true,
    );
  }
}
