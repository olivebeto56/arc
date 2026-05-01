// from: design/design_handoff_arc_app/design/screens/screens-post.jsx
//        (Symmetry L/R bar card inside ScreenSummary)

import 'package:flutter/widgets.dart';

import '../../../models/live_metrics.dart';
import '../../../models/session_summary.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/caption.dart';

class SymmetryBar extends StatelessWidget {
  const SymmetryBar({super.key, required this.summary});

  final SessionSummaryData summary;

  // JSX literal — between-scale.
  static const double _barHeight = 36;
  static const double _barRadius = 8;

  Color _statusColor(MetricStatus s) {
    switch (s) {
      case MetricStatus.ok:
        return AppColors.ok;
      case MetricStatus.warn:
        return AppColors.warn;
      case MetricStatus.crit:
        return AppColors.crit;
    }
  }

  String _statusLabel(MetricStatus s) {
    switch (s) {
      case MetricStatus.ok:
        return '● En rango';
      case MetricStatus.warn:
        return '● Fuera de rango';
      case MetricStatus.crit:
        return '● Crítico';
    }
  }

  @override
  Widget build(BuildContext context) {
    final int leftFlex = summary.symmetryLeftPct.round();
    final int rightFlex = summary.symmetryRightPct.round();
    final Color statusColor = _statusColor(summary.symmetryStatus);

    return Container(
      padding: const EdgeInsets.all(S.s4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(R.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Caption('Simetría L / R'),
              Text(
                _statusLabel(summary.symmetryStatus),
                style: AppText.bodyXs.copyWith(color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: S.s3),
          ClipRRect(
            borderRadius: BorderRadius.circular(_barRadius),
            child: Container(
              height: _barHeight,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(_barRadius),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: leftFlex,
                    child: Container(
                      color: AppColors.accent,
                      alignment: Alignment.center,
                      child: Text(
                        '$leftFlex%',
                        style: AppText.bodySm.copyWith(
                          color: AppColors.bg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: rightFlex,
                    child: Container(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      alignment: Alignment.center,
                      child: Text(
                        '$rightFlex%',
                        style: AppText.bodySm.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          DefaultTextStyle.merge(
            style: AppText.captionXs.copyWith(
              color: AppColors.text3,
              letterSpacing: 10 * 0.08,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('IZQUIERDA'),
                Text('DERECHA'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
