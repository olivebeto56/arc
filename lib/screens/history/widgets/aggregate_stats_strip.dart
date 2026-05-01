// from: design/design_handoff_arc_app/design/screens/screens-post.jsx
//        (ScreenHistory aggregate stats line)

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/history_aggregate.dart';
import '../../../providers/history_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/caption.dart';

/// 4-column aggregate stats: sessions / km / hours / avg score.
///
/// Different from Home A's `StatsStrip` (3-col) — separate widget.
class AggregateStatsStrip extends ConsumerWidget {
  const AggregateStatsStrip({super.key});

  // JSX literal — between-scale.
  static const double _vertPadding = 14;
  static const double _innerPadding = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HistoryAggregate agg = ref.watch(aggregateStatsProvider);
    final List<_Stat> items = <_Stat>[
      _Stat(value: '${agg.sessionsCount}', label: 'sesiones'),
      _Stat(value: agg.totalKm.toStringAsFixed(1), label: 'km'),
      _Stat(value: agg.totalHoursLabel, label: 'h totales'),
      _Stat(value: '${agg.avgScore}', label: 'score avg'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: _vertPadding),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: Container(
                padding: EdgeInsets.only(left: i == 0 ? 0 : _innerPadding),
                decoration: BoxDecoration(
                  border: i > 0
                      ? const Border(
                          left: BorderSide(color: AppColors.border),
                        )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      items[i].value,
                      style: AppText.bodyLg.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Caption(items[i].label),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;
}
