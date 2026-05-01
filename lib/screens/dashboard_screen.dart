// from: design/design_handoff_arc_app/design/screens/screens-live.jsx
//        (ScreenDashboardB — "Cards prominent (no map)" variant)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recommendation_item.dart';
import '../models/session_status.dart';
import '../providers/session_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/arc_button.dart';
import '../widgets/arc_icons.dart';
import 'dashboard/widgets/dashboard_top_bar.dart';
import 'dashboard/widgets/metrics_grid.dart';
import 'dashboard/widgets/pause_modal.dart';
import 'dashboard/widgets/recommendation_overlay.dart';
import 'dashboard/widgets/timer_hero.dart';
import 'dashboard/widgets/view_toggle.dart';
import 'summary_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // JSX literal — between-scale.
  static const double _statusBarReserve = 56;
  static const double _afterTimerHero = 0;
  static const double _toggleHPadding = S.s5;
  static const double _toggleBottomPadding = S.s3;
  static const double _gridHPadding = S.s4;
  static const double _footerTop = 14;
  static const double _footerHPadding = S.s4;
  static const double _footerBottomPadding = 38;
  static const double _footerGap = 10;

  static const Duration _recommendationAutoDismiss = Duration(seconds: 8);

  Timer? _autoDismissTimer;
  int _lastShownCycle = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startSession();
    });
  }

  void _startSession() {
    ref.read(sessionTimerProvider.notifier).reset();
    ref.read(sessionTimerProvider.notifier).start();
    ref.read(liveMetricsProvider.notifier).start();
    ref.read(sessionStatusProvider.notifier).state = SessionStatus.running;
    ref.read(dismissedRecommendationCycleProvider.notifier).state = -1;
  }

  /// Re-arms the auto-dismiss timer whenever a brand-new recommendation
  /// surfaces (i.e. the warning cycle id changes).
  void _onRecommendationChange(RecommendationItem? item) {
    if (item == null) {
      _autoDismissTimer?.cancel();
      _autoDismissTimer = null;
      return;
    }
    final int cycle = ref.read(liveMetricsProvider).warningCycleId;
    if (cycle == _lastShownCycle) return;
    _lastShownCycle = cycle;
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(_recommendationAutoDismiss, () {
      if (!mounted) return;
      ref.read(dismissedRecommendationCycleProvider.notifier).state = cycle;
    });
  }

  Future<void> _onPause() async {
    if (ref.read(sessionStatusProvider) != SessionStatus.running) return;
    ref.read(sessionTimerProvider.notifier).pause();
    ref.read(liveMetricsProvider.notifier).pause();
    ref.read(sessionStatusProvider.notifier).state = SessionStatus.paused;

    final NavigatorState navigator = Navigator.of(context);
    final String? result = await navigator.push(PauseModalRoute());
    if (!mounted) return;

    if (result == pauseResultStop) {
      _finishSession(navigator);
      return;
    }
    // pauseResultResume (or backdrop noop — barrier non-dismissible, so
    // we only resume on explicit pop with the "resume" result).
    ref.read(sessionTimerProvider.notifier).start();
    ref.read(liveMetricsProvider.notifier).start();
    ref.read(sessionStatusProvider.notifier).state = SessionStatus.running;
  }

  void _onStop() {
    _finishSession(Navigator.of(context));
  }

  void _finishSession(NavigatorState navigator) {
    ref.read(sessionTimerProvider.notifier).pause();
    ref.read(liveMetricsProvider.notifier).pause();
    ref.read(sessionStatusProvider.notifier).state = SessionStatus.stopped;
    navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const SummaryScreen()),
    );
  }

  Future<bool> _onWillPop() async {
    final SessionStatus status = ref.read(sessionStatusProvider);
    if (status != SessionStatus.running) return true;
    // TODO(arc): replace with a custom confirm modal.
    return true;
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    // The session providers themselves are NOT autoDispose so the timer
    // keeps running if the user navigates away briefly. If the screen is
    // gone for good (e.g. logged out), call reset() on each notifier from
    // the appropriate route guard.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RecommendationItem?>(
      recommendationProvider,
      (RecommendationItem? prev, RecommendationItem? next) =>
          _onRecommendationChange(next),
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) async {
        if (didPop) return;
        final NavigatorState navigator = Navigator.of(context);
        final bool ok = await _onWillPop();
        if (ok && mounted) navigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: <Widget>[
            SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: _statusBarReserve),
                  const DashboardTopBar(),
                  const TimerHero(),
                  const SizedBox(height: _afterTimerHero),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                      _toggleHPadding,
                      0,
                      _toggleHPadding,
                      _toggleBottomPadding,
                    ),
                    child: Center(child: ViewToggle()),
                  ),
                  const Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: _gridHPadding,
                      ),
                      child: MetricsGrid(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _footerHPadding,
                      _footerTop,
                      _footerHPadding,
                      _footerBottomPadding,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: ARCButton(
                            label: 'PAUSA',
                            kind: ARCButtonKind.ghost,
                            full: true,
                            icon: ArcIcons.pause(
                              size: 18,
                              color: AppColors.text,
                            ),
                            onTap: _onPause,
                          ),
                        ),
                        const SizedBox(width: _footerGap),
                        Expanded(
                          child: ARCButton(
                            label: 'TERMINAR',
                            kind: ARCButtonKind.destructive,
                            full: true,
                            icon: ArcIcons.stop(
                              size: 16,
                              color: AppColors.crit,
                            ),
                            onTap: _onStop,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const RecommendationOverlay(),
          ],
        ),
      ),
    );
  }
}
