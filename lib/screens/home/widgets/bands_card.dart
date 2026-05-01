// from: design/design_handoff_arc_app/design/screens/screens-onboarding.jsx
//        (ScreenHomeA Bandas card — wrapper + 2 mini band cards)

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/band_state.dart';
import '../../../providers/band_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/arc_card.dart';
import '../../../widgets/battery_reading.dart';
import '../../../widgets/caption.dart';
import '../../../widgets/dot.dart';

class BandsCard extends ConsumerWidget {
  const BandsCard({super.key});

  // JSX literal — between-scale.
  static const double _wrapperPadding = 14;
  static const double _topRowMargin = 12;
  static const double _miniGap = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BandState left = ref.watch(leftBandProvider);
    final BandState right = ref.watch(rightBandProvider);

    return ARCCard(
      padding: const EdgeInsets.all(_wrapperPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Caption('Bandas conectadas'),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Dot(color: AppColors.ok, size: 6, glow: true),
                  const SizedBox(width: 5),
                  Text(
                    'Listo para correr',
                    style: AppText.bodyXs.copyWith(color: AppColors.ok),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: _topRowMargin),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(child: _MiniBand(side: 'L', state: left)),
              const SizedBox(width: _miniGap),
              Expanded(child: _MiniBand(side: 'R', state: right)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBand extends StatelessWidget {
  const _MiniBand({required this.side, required this.state});

  final String side;
  final BandState state;

  // JSX literal — between-scale.
  static const double _padding = 10;
  static const double _radius = 10;
  static const double _innerGap = 10;
  static const double _circleSize = 30;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: AppColors.surfaceHi,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: _circleSize,
            height: _circleSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.border),
              shape: BoxShape.circle,
            ),
            child: Text(
              side,
              style: AppText.bodySm.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: _innerGap),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  state.name,
                  style: AppText.bodyXs.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                if (state.battery != null)
                  BatteryReading(pct: state.battery!)
                else
                  Text(
                    '—',
                    style: AppText.bodyXs.copyWith(color: AppColors.text3),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
