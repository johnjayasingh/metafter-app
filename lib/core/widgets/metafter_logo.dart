import 'package:flutter/material.dart';

/// The available color variants of the MetAfter brand artwork.
enum MetafterLogoVariant {
  /// Red glyph / text — for white / light backgrounds.
  red,

  /// White glyph / text — for red / dark backgrounds.
  white,

  /// Black glyph / text — for monochrome / neutral backgrounds.
  black,
}

/// The available forms of the MetAfter brand artwork.
enum MetafterLogoForm {
  /// The dolphin glyph with its ripple rings (used on the splash screen).
  icon,

  /// The "MetAfter" wordmark, trimmed to its text bounds.
  wordmark,
}

/// MetAfter brand artwork.
///
/// Renders the bundled brand assets in `assets/logos/` at the requested
/// [height] in logical pixels. Choose the [form] (dolphin [icon] or text
/// [wordmark]) and the [variant] that contrasts with the surface it sits on:
///
/// * [MetafterLogoVariant.red] — for white / light backgrounds (default).
/// * [MetafterLogoVariant.white] — for the splash & onboarding gradients.
/// * [MetafterLogoVariant.black] — for neutral / monochrome surfaces.
class MetafterLogo extends StatelessWidget {
  const MetafterLogo({
    super.key,
    this.form = MetafterLogoForm.icon,
    this.variant = MetafterLogoVariant.red,
    this.height = 28,
  });

  final MetafterLogoForm form;
  final MetafterLogoVariant variant;
  final double height;

  String get _assetPath {
    switch (form) {
      case MetafterLogoForm.icon:
        switch (variant) {
          case MetafterLogoVariant.red:
            return 'assets/logos/R 2.png';
          case MetafterLogoVariant.white:
            return 'assets/logos/W02 1.png';
          case MetafterLogoVariant.black:
            return 'assets/logos/B 2.png';
        }
      case MetafterLogoForm.wordmark:
        switch (variant) {
          case MetafterLogoVariant.red:
            return 'assets/logos/wordmark_red.png';
          case MetafterLogoVariant.white:
            return 'assets/logos/wordmark_white.png';
          case MetafterLogoVariant.black:
            return 'assets/logos/wordmark_black.png';
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
