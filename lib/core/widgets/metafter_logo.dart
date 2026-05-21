import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// The available variants of the MetAfter wordmark.
enum MetafterLogoVariant {
  /// Red glyph + red text — for white / light backgrounds.
  red,

  /// White glyph + white text — for red / dark backgrounds.
  white,

  /// Black glyph + black text — for monochrome / neutral backgrounds.
  black,
}

/// MetAfter wordmark.
///
/// Renders the brand artwork bundled in `assets/images/` at the requested
/// [height] in logical pixels. Pick the [variant] that contrasts with the
/// surface it sits on:
///
/// * [MetafterLogoVariant.red] — for white / light backgrounds (default).
/// * [MetafterLogoVariant.white] — for the splash & onboarding gradients.
/// * [MetafterLogoVariant.black] — for neutral / monochrome surfaces.
class MetafterLogo extends StatelessWidget {
  const MetafterLogo({
    super.key,
    this.variant = MetafterLogoVariant.red,
    this.height = 28,
  });

  final MetafterLogoVariant variant;
  final double height;

  Color get _tint {
    switch (variant) {
      case MetafterLogoVariant.red:
        return AppColors.brandRed;
      case MetafterLogoVariant.white:
        return Colors.white;
      case MetafterLogoVariant.black:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo.svg',
      height: height,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(_tint, BlendMode.srcIn),
    );
  }
}
