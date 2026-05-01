// from: design/design_handoff_arc_app/design/screens/screens-live.jsx
//        (ScreenDashboardB cards grid 2×3)

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/live_metrics.dart';
import '../../../providers/session_providers.dart';
import '../../../theme/app_spacing.dart';
import 'live_metric_card.dart';

class MetricsGrid extends ConsumerWidget {
  const MetricsGrid({super.key});

  // JSX literal: gap 8 (S.s2). 2 columns × 3 rows.
  static const double _gap = S.s2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LiveMetrics m = ref.watch(liveMetricsProvider);

    final List<_CardData> cards = <_CardData>[
      _CardData(
        label: 'Cadencia',
        value: m.cadenceSpm.round().toString(),
        unit: 'spm',
        sub: _cadenceSub(MetricThresholds.cadence(m.cadenceSpm)),
        status: MetricThresholds.cadence(m.cadenceSpm),
      ),
      _CardData(
        label: 'Simetría',
        value: '${m.symmetryLeftPct.round()}/${(100 - m.symmetryLeftPct).round()}',
        unit: '%',
        sub: _symmetrySub(MetricThresholds.symmetryLeft(m.symmetryLeftPct)),
        status: MetricThresholds.symmetryLeft(m.symmetryLeftPct),
      ),
      _CardData(
        label: 'GCT',
        value: m.gctMs.round().toString(),
        unit: 'ms',
        sub: _gctSub(MetricThresholds.gct(m.gctMs)),
        status: MetricThresholds.gct(m.gctMs),
      ),
      _CardData(
        label: 'Impacto',
        value: m.impactLoad.toStringAsFixed(1),
        unit: 'm/s²',
        sub: _impactSub(MetricThresholds.impact(m.impactLoad)),
        status: MetricThresholds.impact(m.impactLoad),
      ),
      _CardData(
        label: 'Strike angle',
        value: m.strikeAngle.toStringAsFixed(1),
        unit: '°',
        sub: 'Mid-foot',
        status: MetricThresholds.strike(m.strikeAngle),
      ),
      _CardData(
        label: 'Variabilidad',
        value: m.variability.toStringAsFixed(1),
        unit: '%',
        sub: _variabilitySub(MetricThresholds.variability(m.variability)),
        status: MetricThresholds.variability(m.variability),
      ),
    ];

    return Column(
      children: <Widget>[
        for (int i = 0; i < cards.length; i += 2) ...<Widget>[
          if (i > 0) const SizedBox(height: _gap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _build(cards[i])),
              const SizedBox(width: _gap),
              Expanded(child: _build(cards[i + 1])),
            ],
          ),
        ],
      ],
    );
  }

  Widget _build(_CardData c) => LiveMetricCard(
        label: c.label,
        value: c.value,
        unit: c.unit,
        sub: c.sub,
        status: c.status,
      );

  static String _cadenceSub(MetricStatus s) =>
      s == MetricStatus.ok ? 'Óptima 175-185' : 'Fuera de rango';
  static String _symmetrySub(MetricStatus s) =>
      s == MetricStatus.ok ? 'En rango' : 'Fuera de rango';
  static String _gctSub(MetricStatus s) =>
      s == MetricStatus.ok ? 'Óptimo' : 'Fuera de rango';
  static String _impactSub(MetricStatus s) =>
      s == MetricStatus.ok ? 'En rango' : 'Fuera de rango';
  static String _variabilitySub(MetricStatus s) =>
      s == MetricStatus.ok ? 'Estable' : 'Fuera de rango';
}

class _CardData {
  const _CardData({
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
}
