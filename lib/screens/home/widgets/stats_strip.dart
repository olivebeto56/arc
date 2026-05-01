// from: design/design_handoff_arc_app/design/screens/screens-onboarding.jsx
//        (ScreenHomeA stats line — sesiones / km / racha)

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/home_stats.dart';
import '../../../providers/home_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/caption.dart';

class StatsStrip extends ConsumerWidget {
  const StatsStrip({super.key});

  // JSX literal — between-scale (paddingLeft of inner cells).
  static const double _innerPadding = 14;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomeStats stats = ref.watch(homeStatsProvider);
    final List<_Stat> items = <_Stat>[
      _Stat(value: '${stats.totalSessions}', label: 'sesiones'),
      _Stat(value: stats.totalKm.toStringAsFixed(0), label: 'km totales'),
      _Stat(value: '${stats.streakDays}', label: 'racha días'),
    ];

    return Row(
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
                    style: AppText.metric.copyWith(height: 1.0),
                  ),
                  const SizedBox(height: 4),
                  Caption(items[i].label),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Stat {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;
}
