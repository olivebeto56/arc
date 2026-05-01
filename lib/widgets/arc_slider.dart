// from: design/design_handoff_arc_app/design/screens/screens-post.jsx
//        (Slider component inside ScreenSettings)

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Read-only slider readout — label + value/unit + filled track + thumb +
/// min/max footers. The thumb is purely visual; Phase 4 wires drag to a
/// `ValueChanged<double>` callback (currently `onChanged` is a no-op slot).
class ARCSlider extends StatelessWidget {
  const ARCSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    this.valueLabel,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;

  /// Pre-formatted display value. Defaults to `value.toStringAsFixed(0)`
  /// — pass an explicit string for fractional values (e.g. "1.18").
  final String? valueLabel;

  // JSX literal — between-scale.
  static const double _padding = 14;
  static const double _trackHeight = 4;
  static const double _trackRadius = 2;
  static const double _thumbSize = 14;
  static const double _thumbRingSpread = 4;
  static const double _labelToTrack = 8;
  static const double _trackToFooter = 5;

  @override
  Widget build(BuildContext context) {
    final double pct = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final String resolvedValue = valueLabel ?? value.toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.all(_padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(label, style: AppText.bodySm.copyWith(color: AppColors.text)),
              Text(
                '$resolvedValue $unit',
                style: AppText.monoReadout.copyWith(
                  fontSize: 12,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: _labelToTrack),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double trackWidth = constraints.maxWidth;
              final double thumbX = trackWidth * pct - _thumbSize / 2;
              return SizedBox(
                width: trackWidth,
                height: _thumbSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: <Widget>[
                    // Track base
                    Container(
                      height: _trackHeight,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHi,
                        borderRadius: BorderRadius.circular(_trackRadius),
                      ),
                    ),
                    // Filled portion
                    SizedBox(
                      width: trackWidth * pct,
                      height: _trackHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(_trackRadius),
                        ),
                      ),
                    ),
                    // Thumb
                    Positioned(
                      left: thumbX.clamp(0.0, trackWidth - _thumbSize),
                      width: _thumbSize,
                      height: _thumbSize,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.accentDim,
                              spreadRadius: _thumbRingSpread,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: _trackToFooter),
          DefaultTextStyle.merge(
            style: AppText.monoTiny.copyWith(fontSize: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(min.toStringAsFixed(0)),
                Text(max.toStringAsFixed(0)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
