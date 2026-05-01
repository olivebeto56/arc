// from: design/design_handoff_arc_app/design/screens/screens-live.jsx
//        (ScreenRecommendation floating card)

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/live_metrics.dart';
import '../../../models/recommendation_item.dart';
import '../../../providers/session_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/caption.dart';

/// Floating contextual card that slides up from the bottom of the dashboard
/// when a metric goes out of range. Auto-hides when the metric returns to
/// the OK band; user can dismiss the current pulse via the X button.
class RecommendationOverlay extends ConsumerWidget {
  const RecommendationOverlay({super.key});

  // JSX literal — between-scale.
  static const double _bottomOffset = 110;
  static const double _hMargin = S.s4;
  static const double _padding = S.s4;
  static const double _ringSpread = 4;
  static const Duration _enterDuration = Duration(milliseconds: 280);
  static const Duration _exitDuration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RecommendationItem? item = ref.watch(recommendationProvider);
    final int currentCycle =
        ref.watch(liveMetricsProvider).warningCycleId;

    return Positioned(
      left: _hMargin,
      right: _hMargin,
      bottom: _bottomOffset,
      child: AnimatedSwitcher(
        duration: _enterDuration,
        reverseDuration: _exitDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> anim) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              // Slide from 24 px below (matches Tu prompt's spec of "8 px"
              // visually felt too subtle once the cycle restarts; 24 px
              // is what the JSX shows).
              position: Tween<Offset>(
                begin: const Offset(0, 0.24),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          );
        },
        child: item == null
            ? const SizedBox.shrink(key: ValueKey<String>('empty'))
            : _Card(
                key: ValueKey<int>(currentCycle),
                item: item,
                onDismiss: () => ref
                    .read(dismissedRecommendationCycleProvider.notifier)
                    .state = currentCycle,
              ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    super.key,
    required this.item,
    required this.onDismiss,
  });

  final RecommendationItem item;
  final VoidCallback onDismiss;

  static Color _statusColor(MetricStatus s) {
    switch (s) {
      case MetricStatus.ok:
        return AppColors.ok;
      case MetricStatus.warn:
        return AppColors.warn;
      case MetricStatus.crit:
        return AppColors.crit;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RecommendationOverlay._padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.accent),
        borderRadius: BorderRadius.circular(R.lg),
        boxShadow: <BoxShadow>[
          BoxShadow(
            offset: const Offset(0, 12),
            blurRadius: 40,
            color: AppColors.bg.withValues(alpha: 0.6),
          ),
          const BoxShadow(
            color: AppColors.accentDim,
            spreadRadius: RecommendationOverlay._ringSpread,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Caption(item.captionLabel, color: AppColors.accent),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDismiss,
                child: Padding(
                  padding: const EdgeInsets.only(left: S.s2),
                  child: Text(
                    '×',
                    style: AppText.bodyLg.copyWith(
                      color: AppColors.text3,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: S.s2),
          Text(item.body, style: AppText.body),
          const SizedBox(height: S.s3),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'Actual ',
                style: AppText.monoReadout.copyWith(color: AppColors.text2),
              ),
              Text(
                item.currentValue,
                style: AppText.monoReadout.copyWith(
                  color: _statusColor(item.currentStatus),
                ),
              ),
              const SizedBox(width: S.s2),
              Text(
                '→',
                style: AppText.monoReadout.copyWith(color: AppColors.border),
              ),
              const SizedBox(width: S.s2),
              Text(
                'Óptimo ',
                style: AppText.monoReadout.copyWith(color: AppColors.text2),
              ),
              Text(
                item.optimalValue,
                style: AppText.monoReadout.copyWith(color: AppColors.ok),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
