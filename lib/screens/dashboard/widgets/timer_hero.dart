// from: design/design_handoff_arc_app/design/screens/screens-live.jsx
//        (ScreenDashboardB big timer block + sub-stats)

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/session_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/caption.dart';
import '../../../widgets/session_timer.dart';

class TimerHero extends ConsumerWidget {
  const TimerHero({super.key});

  // JSX literal — between-scale.
  static const double _topPadding = S.s3;
  static const double _bottomPadding = S.s5;
  static const double _hPadding = S.s5;
  static const double _subStatsTopMargin = S.s3;
  static const double _subStatsGap = S.s7;
  static const double _separatorWidth = 1;
  static const double _separatorHeight = 38;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double km = ref.watch(distanceProvider);
    final String pace = ref.watch(paceProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        _hPadding,
        _topPadding,
        _hPadding,
        _bottomPadding,
      ),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -1.4),
          radius: 0.9,
          colors: <Color>[
            AppColors.accentDim,
            AppColors.accentDim.withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.6],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SessionTimer(),
          const SizedBox(height: _subStatsTopMargin),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _SubStat(
                value: km.toStringAsFixed(1),
                label: 'km',
              ),
              const SizedBox(width: _subStatsGap),
              Container(
                width: _separatorWidth,
                height: _separatorHeight,
                color: AppColors.border,
              ),
              const SizedBox(width: _subStatsGap),
              _SubStat(
                value: pace,
                label: 'min/km',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubStat extends StatelessWidget {
  const _SubStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(value, style: AppText.metric.copyWith(color: AppColors.accent)),
        const SizedBox(height: 2),
        Caption(label),
      ],
    );
  }
}
