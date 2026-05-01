// from: design/design_handoff_arc_app/design/screens/atoms.jsx (BatteryReading)

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'arc_icons.dart';

/// Battery icon + percentage label — mono-readout style.
///
/// JSX literal: glyph 22×10 followed by a 5 px gap and the percentage in 11 px
/// mono with tabular figures. Default colour is `text2`; below 30 % it ramps
/// to `warn` (the JSX uses warn for both <30 and <15 — same colour twice).
class BatteryReading extends StatelessWidget {
  const BatteryReading({
    super.key,
    required this.pct,
    this.color,
  });

  final int pct;
  final Color? color;

  static const double _gap = 5;

  @override
  Widget build(BuildContext context) {
    final Color resolved = color ?? (pct < 30 ? AppColors.warn : AppColors.text2);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        ArcIcons.battery(pct: pct, color: resolved),
        const SizedBox(width: _gap),
        Text(
          '$pct%',
          style: AppText.monoReadout.copyWith(color: resolved),
        ),
      ],
    );
  }
}
