// from: design/design_handoff_arc_app/design/screens/screens-onboarding.jsx
//        (ScreenHomeA "Promedios — últimas 10" card)

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/home_stats.dart';
import '../../../providers/home_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/arc_card.dart';
import '../../../widgets/caption.dart';
import '../../../widgets/sparkline.dart';

class AveragesCard extends ConsumerWidget {
  const AveragesCard({super.key});

  // JSX literal — between-scale.
  static const double _topRowMargin = 14;
  static const double _gridGap = 14;
  static const double _valueUnitGap = 4;
  static const double _sparklineWidth = 50;
  static const double _sparklineHeight = 16;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomeStats s = ref.watch(homeStatsProvider);
    final List<double> spark =
        s.scoreSpark.map((int v) => v.toDouble()).toList(growable: false);

    final List<_Metric> metrics = <_Metric>[
      _Metric(value: '${s.cadenceSpm}', unit: 'spm', label: 'Cadencia'),
      _Metric(
        value: '${s.symmetryLeftPct} / ${s.symmetryRightPct}',
        unit: '%',
        label: 'Simetría L / R',
      ),
      _Metric(value: '${s.gctMs}', unit: 'ms', label: 'GCT'),
      _Metric(value: '${s.technicalScore}', unit: '/100', label: 'Score técnico'),
    ];

    return ARCCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Caption('Promedios — últimas 10'),
              Sparkline(
                values: spark,
                width: _sparklineWidth,
                height: _sparklineHeight,
              ),
            ],
          ),
          const SizedBox(height: _topRowMargin),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _MetricTile(m: metrics[0])),
              const SizedBox(width: _gridGap),
              Expanded(child: _MetricTile(m: metrics[1])),
            ],
          ),
          const SizedBox(height: _gridGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _MetricTile(m: metrics[2])),
              const SizedBox(width: _gridGap),
              Expanded(child: _MetricTile(m: metrics[3])),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric {
  const _Metric({required this.value, required this.unit, required this.label});
  final String value;
  final String unit;
  final String label;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.m});

  final _Metric m;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(m.value, style: AppText.metric),
            const SizedBox(width: AveragesCard._valueUnitGap),
            Text(
              m.unit,
              style: AppText.bodyXs.copyWith(color: AppColors.text3),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Caption(m.label),
      ],
    );
  }
}
