// from: design/design_handoff_arc_app/design/screens/screens-live.jsx
//        (ScreenDashboardB BigMetric)

import 'package:flutter/widgets.dart';

import '../../../models/live_metrics.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/caption.dart';

/// Single 1-of-6 cell in the Dashboard B grid. The 2 px coloured stripe on
/// the left edge animates smoothly across status changes (220 ms easeOut).
class LiveMetricCard extends StatelessWidget {
  const LiveMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.sub,
    required this.status,
  });

  final String label;
  final String value;
  final String unit;
  final String sub;
  final MetricStatus status;

  // JSX literal — between-scale.
  static const double _padding = 14;
  static const double _stripeWidth = 2;
  static const double _gap = 6;
  static const double _valueUnitGap = 4;
  static const Duration _animDuration = Duration(milliseconds: 220);

  static Color _statusColor(MetricStatus s) {
    switch (s) {
      case MetricStatus.ok:
        return AppColors.accent;
      case MetricStatus.warn:
        return AppColors.warn;
      case MetricStatus.crit:
        return AppColors.crit;
    }
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(R.md);
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: radius,
            ),
            padding: const EdgeInsets.fromLTRB(
              _padding + _stripeWidth,
              _padding,
              _padding,
              _padding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Caption(label),
                const SizedBox(height: _gap),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    Text(value, style: AppText.metricLg),
                    const SizedBox(width: _valueUnitGap),
                    Text(
                      unit,
                      style: AppText.bodyXs.copyWith(color: AppColors.text3),
                    ),
                  ],
                ),
                const SizedBox(height: _gap),
                Text(
                  sub,
                  style: AppText.caption.copyWith(
                    letterSpacing: 0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _stripeWidth,
            child: AnimatedContainer(
              duration: _animDuration,
              curve: Curves.easeOut,
              color: _statusColor(status),
            ),
          ),
        ],
      ),
    );
  }
}
