// from: design/design_handoff_arc_app/design/screens/atoms.jsx (Dot)

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';

/// Status dot with optional outer glow. Used for connected / waiting / error
/// indicators on band cards, recommendation cards, top-bar status chips.
///
/// JSX literal: `boxShadow: 0 0 ${size*2}px ${color}` when [glow] is true →
/// in Flutter that maps to `BoxShadow(color: color, blurRadius: size*2)`.
class Dot extends StatelessWidget {
  const Dot({
    super.key,
    this.color = AppColors.ok,
    this.size = 6,
    this.glow = false,
  });

  final Color color;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: glow
            ? <BoxShadow>[
                BoxShadow(color: color, blurRadius: size * 2),
              ]
            : null,
      ),
    );
  }
}
