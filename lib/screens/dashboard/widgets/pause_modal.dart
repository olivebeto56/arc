// from: design/design_handoff_arc_app/design/screens/screens-live.jsx
//        (ScreenPause)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/live_metrics.dart';
import '../../../providers/session_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/arc_button.dart';
import '../../../widgets/arc_icons.dart';
import '../../../widgets/caption.dart';
import '../../../widgets/session_timer.dart';

/// Result returned via `Navigator.pop`.
const String pauseResultResume = 'resume';
const String pauseResultStop = 'stop';

/// Route for the Pause modal — opaque false so the dashboard renders behind,
/// barrier non-dismissible (the user must explicitly choose REANUDAR or
/// TERMINAR), 280 ms enter / 200 ms exit with a backdrop fade and a card
/// scale-up from 0.92.
class PauseModalRoute extends PageRouteBuilder<String> {
  PauseModalRoute()
      : super(
          opaque: false,
          barrierDismissible: false,
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (BuildContext context, Animation<double> anim,
              Animation<double> secondary) {
            return const PauseModalContent();
          },
          transitionsBuilder: (
            BuildContext context,
            Animation<double> anim,
            Animation<double> secondary,
            Widget child,
          ) {
            final CurvedAnimation eased = CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: eased,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1).animate(eased),
                child: child,
              ),
            );
          },
        );
}

class PauseModalContent extends ConsumerWidget {
  const PauseModalContent({super.key});

  // JSX literal — between-scale.
  static const double _backdropOpacity = 0.85;
  static const double _hPadding = S.s6;
  static const double _topPadding = 56;
  static const double _bottomPadding = S.s6;
  static const double _cardPadding = S.s6;
  static const double _captionToTimer = 14;
  static const double _timerToSubtext = S.s2;
  static const double _subtextToSnapshot = S.s6;
  static const double _snapshotPadding = 14;
  static const double _snapshotToActions = S.s5;
  static const double _actionsGap = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LiveMetrics m = ref.watch(liveMetricsProvider);
    final double km = ref.watch(distanceProvider);
    final String pace = ref.watch(paceProvider);

    // Scaffold with transparent background gives the route the implicit
    // Material ancestor that Text widgets need to render without the
    // yellow "missing Material" debug underlines.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: <Widget>[
          // Backdrop. Opaque tap absorber — we deliberately do NOT pop the
          // route on backdrop tap; the user must commit to REANUDAR or
          // TERMINAR.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Container(
                color: AppColors.bg.withValues(alpha: _backdropOpacity),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _hPadding,
              _topPadding,
              _hPadding,
              _bottomPadding,
            ),
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(_cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(R.xl),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Caption('● Sesión pausada', color: AppColors.warn),
                    const SizedBox(height: _captionToTimer),
                    const SessionTimer(style: AppText.display3),
                    const SizedBox(height: _timerToSubtext),
                    Text(
                      '${km.toStringAsFixed(1)} km · Ritmo medio $pace/km',
                      style: AppText.bodySm.copyWith(color: AppColors.text2),
                    ),
                    const SizedBox(height: _subtextToSnapshot),
                    _Snapshot(metrics: m),
                    const SizedBox(height: _snapshotToActions),
                    ARCButton(
                      label: 'REANUDAR',
                      full: true,
                      icon: ArcIcons.play(size: 18, color: AppColors.bg),
                      onTap: () =>
                          Navigator.of(context).pop(pauseResultResume),
                    ),
                    const SizedBox(height: _actionsGap),
                    ARCButton(
                      label: 'TERMINAR SESIÓN',
                      kind: ARCButtonKind.destructive,
                      full: true,
                      onTap: () =>
                          Navigator.of(context).pop(pauseResultStop),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Snapshot extends StatelessWidget {
  const _Snapshot({required this.metrics});

  final LiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final List<_SnapItem> items = <_SnapItem>[
      _SnapItem(value: '${metrics.cadenceSpm.round()}', label: 'spm'),
      _SnapItem(
        value:
            '${metrics.symmetryLeftPct.round()}/${(100 - metrics.symmetryLeftPct).round()}',
        label: 'sym',
      ),
      _SnapItem(value: '${metrics.gctMs.round()}', label: 'gct'),
    ];

    return Container(
      padding: const EdgeInsets.all(PauseModalContent._snapshotPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceHi,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(R.md),
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < items.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    items[i].value,
                    style: AppText.bodyLg.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Caption(items[i].label),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SnapItem {
  const _SnapItem({required this.value, required this.label});
  final String value;
  final String label;
}
