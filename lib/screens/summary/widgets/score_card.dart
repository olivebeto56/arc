// from: design/design_handoff_arc_app/design/screens/screens-post.jsx
//        (ScoreCircle card inside ScreenSummary)

import 'package:flutter/widgets.dart';

import '../../../models/session_summary.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/arc_icons.dart';
import '../../../widgets/caption.dart';
import '../../../widgets/score_circle.dart';

class ScoreCard extends StatelessWidget {
  const ScoreCard({super.key, required this.summary});

  final SessionSummaryData summary;

  // JSX literal — between-scale.
  static const double _padding = S.s6;
  static const double _gap = S.s6;
  static const double _circleDiameter = 130;
  static const double _circleStroke = 6;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.7,
          colors: <Color>[
            AppColors.accentDim,
            AppColors.accentDim.withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.65],
        ),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(R.xl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ScoreCircle(
            score: summary.score,
            diameter: _circleDiameter,
            strokeWidth: _circleStroke,
            numberStyle: AppText.display3.copyWith(
              fontSize: 44,
              letterSpacing: -44 * 0.03,
            ),
            suffix: '/ 100',
            suffixPlacement: ScoreCircleSuffixPlacement.below,
          ),
          const SizedBox(width: _gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Caption('Score técnico', color: AppColors.accent),
                const SizedBox(height: 6),
                Text(summary.scoreBlurb, style: AppText.body),
                const SizedBox(height: S.s2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ArcIcons.trend(size: 12, color: AppColors.ok),
                    const SizedBox(width: 5),
                    Text(
                      '+${summary.scoreTrend} vs media histórica',
                      style: AppText.bodyXs.copyWith(color: AppColors.ok),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
