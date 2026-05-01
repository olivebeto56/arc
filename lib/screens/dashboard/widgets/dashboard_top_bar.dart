// from: design/design_handoff_arc_app/design/screens/screens-live.jsx
//        (ScreenDashboardB ARCTopBar — pre-arranged left/center/right)

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/band_state.dart';
import '../../../providers/band_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/arc_top_bar.dart';
import '../../../widgets/dot.dart';

class DashboardTopBar extends ConsumerWidget {
  const DashboardTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BandState left = ref.watch(leftBandProvider);
    final BandState right = ref.watch(rightBandProvider);

    return ARCTopBar(
      left: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Dot(color: AppColors.ok, size: 6, glow: true),
          const SizedBox(width: 6),
          Text(
            'Conectado',
            style: AppText.bodyXs.copyWith(color: AppColors.text2),
          ),
        ],
      ),
      center: Text(
        // TODO(arc): wire to geolocator accuracy in Phase 4.
        'GPS ±4m',
        style: AppText.monoTiny.copyWith(color: AppColors.ok),
      ),
      right: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            'L ${left.battery ?? '—'}%',
            style: AppText.monoTiny.copyWith(color: AppColors.text2),
          ),
          const SizedBox(width: 8),
          Text(
            'R ${right.battery ?? '—'}%',
            style: AppText.monoTiny.copyWith(color: AppColors.text2),
          ),
        ],
      ),
    );
  }
}
