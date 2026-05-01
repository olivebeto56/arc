// from: design/design_handoff_arc_app/design/screens/atoms.jsx (ARCLogo)
//        design/components/logos.jsx                          (ArcMarkTall, ArcIntegratedArtboard)

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// Which brand asset to render.
///
///  - [wordmark] — symbol + "RC" letterforms in a single optically-aligned
///    SVG. Recolours via `BlendMode.srcIn`. Used in TopBar / Splash.
///  - [icon] — square 1:1 app-icon composition with a baked-in `bg`
///    background and white symbol. **NOT recolourable** (the [color] arg is
///    ignored). Used inside the app for previews of the OS icon.
///  - [symbolOnly] — just the arc + dot mark, no wordmark. Recolourable.
///    Useful for tight badges and small UI affordances.
enum ARCLogoVariant { wordmark, icon, symbolOnly }

class ARCLogo extends StatelessWidget {
  const ARCLogo({
    super.key,
    this.variant = ARCLogoVariant.wordmark,
    this.height = 22,
    this.color = AppColors.text,
  });

  final ARCLogoVariant variant;

  /// Height in logical pixels. Width derives from the SVG's intrinsic
  /// aspect ratio — except for [ARCLogoVariant.icon] which is forced to
  /// `height × height` (the SVG is 1:1).
  final double height;

  /// Tint applied with `BlendMode.srcIn` to monochrome variants. Ignored
  /// for [ARCLogoVariant.icon] — that SVG carries its own palette.
  final Color color;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case ARCLogoVariant.wordmark:
        return SvgPicture.asset(
          'assets/logos/arc-integrated-white.svg',
          height: height,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );
      case ARCLogoVariant.symbolOnly:
        return SvgPicture.asset(
          'assets/logos/arc-symbol-white.svg',
          height: height,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );
      case ARCLogoVariant.icon:
        return SvgPicture.asset(
          'assets/logos/arc-favicon-square.svg',
          width: height,
          height: height,
        );
    }
  }
}
