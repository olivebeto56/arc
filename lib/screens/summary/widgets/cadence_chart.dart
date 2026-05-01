// from: design/design_handoff_arc_app/design/screens/screens-post.jsx
//        (Cadence chart card inside ScreenSummary)

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';

import '../../../models/session_summary.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/caption.dart';

class CadenceChart extends StatelessWidget {
  const CadenceChart({super.key, required this.summary});

  final SessionSummaryData summary;

  // JSX literal — optimal cadence band 175-185 spm.
  static const double _optimalLow = 175;
  static const double _optimalHigh = 185;
  static const double _chartHeight = 80;

  @override
  Widget build(BuildContext context) {
    final List<double> series = summary.cadenceTimeSeries;
    final double minY = series.fold<double>(
        series.first, (double a, double b) => a < b ? a : b) - 5;
    final double maxY = series.fold<double>(
        series.first, (double a, double b) => a > b ? a : b) + 5;

    final List<FlSpot> spots = <FlSpot>[
      for (int i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i]),
    ];

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
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              const Caption('Cadencia · sesión completa'),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '${summary.cadenceAvgSpm}',
                    style: AppText.monoReadout.copyWith(color: AppColors.text),
                  ),
                  Text(
                    ' spm avg',
                    style: AppText.monoReadout.copyWith(color: AppColors.text2),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: S.s3),
          SizedBox(
            height: _chartHeight,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                minX: 0,
                maxX: (series.length - 1).toDouble(),
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                rangeAnnotations: RangeAnnotations(
                  horizontalRangeAnnotations: <HorizontalRangeAnnotation>[
                    HorizontalRangeAnnotation(
                      y1: _optimalLow,
                      y2: _optimalHigh,
                      color: AppColors.okDim,
                    ),
                  ],
                ),
                lineBarsData: <LineChartBarData>[
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.2,
                    color: AppColors.accent,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    isStrokeJoinRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          DefaultTextStyle.merge(
            style: AppText.monoTiny,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('0:00'),
                Text('16:00'),
                Text('32:18'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
