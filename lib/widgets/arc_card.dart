// from: design/design_handoff_arc_app/design/screens/atoms.jsx (ARCCard)

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// Standard surface card — `surface` background, 1 px border, radius 14.
///
///  - `accent: true` paints a 3 px cyan stripe on the left edge (the JSX
///    `borderLeft: 3px accent`). Implemented as a left-side overlay clipped to
///    the card's rounded corners — Flutter does not allow per-side border
///    colours combined with `borderRadius`.
///  - `borderColor` overrides the default `border` token (use `accent` for the
///    Home A "RECOMENDACIÓN · HISTÓRICO" full-cyan-border variant).
///  - `ringShadow: true` projects an outer 3 px solid `accentDim` ring around
///    the card (the JSX `boxShadow: 0 0 0 3px accentDim`). The ring lives on a
///    wrapper outside the `ClipRRect` so it isn't clipped away.
class ARCCard extends StatelessWidget {
  const ARCCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(S.s4),
    this.accent = false,
    this.borderColor,
    this.ringShadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool accent;
  final Color? borderColor;
  final bool ringShadow;

  static const double _accentStripWidth = 3;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(R.lg);
    final Widget body = ClipRRect(
      borderRadius: radius,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: borderColor ?? AppColors.border),
          borderRadius: radius,
        ),
        child: Stack(
          children: <Widget>[
            Padding(
              padding: padding.add(
                accent
                    ? const EdgeInsets.only(left: _accentStripWidth)
                    : EdgeInsets.zero,
              ),
              child: child,
            ),
            if (accent)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _accentStripWidth,
                child: Container(color: AppColors.accent),
              ),
          ],
        ),
      ),
    );

    if (!ringShadow) return body;
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.accentDim,
            blurRadius: 0,
            spreadRadius: 3,
          ),
        ],
      ),
      child: body,
    );
  }
}
