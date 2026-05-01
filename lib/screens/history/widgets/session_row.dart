// from: design/design_handoff_arc_app/design/screens/screens-post.jsx
//        (Session row inside ScreenHistory)

import 'package:flutter/widgets.dart';

import '../../../models/session_summary.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/route_map_placeholder.dart';
import '../../../widgets/sparkline.dart';

class SessionRow extends StatelessWidget {
  const SessionRow({
    super.key,
    required this.summary,
    this.onTap,
  });

  final SessionSummaryData summary;
  final VoidCallback? onTap;

  // JSX literal — between-scale.
  static const double _padV = 14;
  static const double _padH = 12;
  static const double _gap = 12;
  static const double _miniMapSize = 48;
  static const double _sparklineWidth = 80;
  static const double _sparklineHeight = 14;

  String _formatDuration(Duration d) {
    final int totalSeconds = d.inSeconds;
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds ~/ 60) % 60;
    final int seconds = totalSeconds % 60;
    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');
    if (hours == 0) return '$mm:$ss';
    return '$hours:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _padH,
        vertical: _padV,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(R.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const RouteMapPlaceholder(
            width: _miniMapSize,
            height: _miniMapSize,
            radius: R.sm,
            label: null,
          ),
          const SizedBox(width: _gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        summary.dateLabel,
                        style: AppText.bodySm.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      summary.sessionType,
                      style: AppText.bodyXs.copyWith(
                        fontSize: 10,
                        color: AppColors.text3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _formatDuration(summary.totalDuration),
                      style: AppText.monoReadout.copyWith(
                        color: AppColors.text2,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '·',
                        style: AppText.monoReadout.copyWith(
                          color: AppColors.border,
                        ),
                      ),
                    ),
                    Text(
                      '${summary.distanceKm.toStringAsFixed(2)} km',
                      style: AppText.monoReadout.copyWith(
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Sparkline(
                  values: summary.cadenceTimeSeries,
                  width: _sparklineWidth,
                  height: _sparklineHeight,
                  dot: false,
                ),
              ],
            ),
          ),
          const SizedBox(width: _gap),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${summary.score}',
                style: AppText.metric.copyWith(
                  color: AppColors.accent,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'SCORE',
                style: AppText.captionXs.copyWith(fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}
