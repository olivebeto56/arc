import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/recommendations.dart';
import '../models/live_metrics.dart';
import '../models/recommendation_item.dart';
import '../models/session_status.dart';
import '../models/session_summary.dart';

// ─── Session timer ─────────────────────────────────────────────

class SessionTimerNotifier extends StateNotifier<Duration> {
  SessionTimerNotifier() : super(Duration.zero);

  Timer? _ticker;

  void start() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      state = state + const Duration(seconds: 1);
    });
  }

  void pause() {
    _ticker?.cancel();
    _ticker = null;
  }

  void reset() {
    _ticker?.cancel();
    _ticker = null;
    state = Duration.zero;
  }

  bool get isRunning => _ticker != null;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

/// Elapsed session time. Survives widget rebuilds — NOT autoDispose.
final StateNotifierProvider<SessionTimerNotifier, Duration> sessionTimerProvider =
    StateNotifierProvider<SessionTimerNotifier, Duration>(
  (Ref ref) => SessionTimerNotifier(),
);

// ─── Session status ────────────────────────────────────────────

final StateProvider<SessionStatus> sessionStatusProvider =
    StateProvider<SessionStatus>((Ref ref) => SessionStatus.idle);

// ─── Live metrics ──────────────────────────────────────────────

class LiveMetricsNotifier extends StateNotifier<LiveMetrics> {
  LiveMetricsNotifier() : super(LiveMetrics.initial);

  Timer? _ticker;
  int _ticks = 0;
  int _cycleId = 0;
  bool _wasInWarnWindow = false;

  // 250 ms ticks × 100 = 25 s cycle. Warn window covers the first
  // 32 ticks (~8 s) of every cycle. Inside the warn window, symmetry is
  // forced to 48 % so the JSX-copy recommendation lights up.
  static const int _ticksPerCycle = 100;
  static const int _warnWindowTicks = 32;
  static const Duration _interval = Duration(milliseconds: 250);

  void start() {
    _ticker?.cancel();
    _ticks = 0;
    _wasInWarnWindow = false;
    _ticker = Timer.periodic(_interval, _onTick);
  }

  void pause() {
    _ticker?.cancel();
    _ticker = null;
  }

  void reset() {
    _ticker?.cancel();
    _ticker = null;
    _ticks = 0;
    state = LiveMetrics.initial;
  }

  void _onTick(Timer _) {
    if (!mounted) return;
    _ticks++;
    final int phase = _ticks % _ticksPerCycle;
    final bool inWarnWindow = phase < _warnWindowTicks;
    if (inWarnWindow && !_wasInWarnWindow) {
      _cycleId++;
    }
    _wasInWarnWindow = inWarnWindow;

    final double t = _ticks * _interval.inMilliseconds / 1000.0;
    state = LiveMetrics(
      cadenceSpm: 178 + 4 * math.sin(t * 0.45),
      symmetryLeftPct: inWarnWindow ? 48 : 50 + math.sin(t * 0.30),
      gctMs: 232 + 8 * math.sin(t * 0.50),
      impactLoad: 11 + 1.5 * math.sin(t * 0.55),
      strikeAngle: 5 + 1.5 * math.sin(t * 0.40),
      variability: 4 + 0.8 * math.sin(t * 0.35),
      symmetryWarning: inWarnWindow,
      warningCycleId: _cycleId,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final StateNotifierProvider<LiveMetricsNotifier, LiveMetrics>
    liveMetricsProvider = StateNotifierProvider<LiveMetricsNotifier, LiveMetrics>(
  (Ref ref) => LiveMetricsNotifier(),
);

// ─── Distance / pace ───────────────────────────────────────────

/// 3 m/s ≈ 5:33 min/km — close enough to the JSX's `5:32` and `5.2 km`
/// at the displayed `28:43` mark.
final Provider<double> distanceProvider = Provider<double>((Ref ref) {
  final Duration elapsed = ref.watch(sessionTimerProvider);
  return elapsed.inSeconds * 0.003;
});

/// Mock pace string. Phase 4 will compute this from GPS samples.
final Provider<String> paceProvider = Provider<String>((Ref ref) => '5:32');

// ─── Recommendation ────────────────────────────────────────────

/// `warningCycleId` of the recommendation the user has dismissed. Equal
/// values silence the overlay until the next cycle starts.
final StateProvider<int> dismissedRecommendationCycleProvider =
    StateProvider<int>((Ref ref) => -1);

/// Surfaces a recommendation when the symmetry pulse is in its warn window
/// and the user hasn't dismissed *this* particular pulse.
final Provider<RecommendationItem?> recommendationProvider =
    Provider<RecommendationItem?>((Ref ref) {
  final LiveMetrics m = ref.watch(liveMetricsProvider);
  final int dismissed = ref.watch(dismissedRecommendationCycleProvider);

  if (!m.symmetryWarning) return null;
  if (dismissed == m.warningCycleId) return null;
  return Recommendations.symmetry;
});

// ─── Session summary (post-session frozen report) ──────────────

/// Mock summary matching the JSX literal of `ScreenSummary`.
// TODO(arc): derive from real session data + biomechanics-analyzer in Phase 4.
final Provider<SessionSummaryData> sessionSummaryProvider =
    Provider<SessionSummaryData>((Ref ref) {
  return SessionSummaryData(
    dateLabel: 'Sábado 14 · junio · 17:34',
    sessionDate: DateTime.now(),
    sessionType: 'Libre',
    totalDuration: const Duration(minutes: 32, seconds: 18),
    distanceKm: 5.78,
    avgPaceLabel: '5:35',
    score: 82,
    scoreTrend: 4,
    scoreBlurb: 'Excelente sesión. Cadencia y GCT en óptimo.',
    cadenceTimeSeries: const <double>[
      172, 175, 178, 180, 182, 178, 176, 179, 181, 178, 175, 178,
    ],
    cadenceAvgSpm: 178,
    symmetryLeftPct: 49,
    symmetryRightPct: 51,
    symmetryStatus: MetricStatus.ok,
    gctAvgMs: 231,
    peakImpact: 13.2,
    variability: 4.8,
    recommendations: const <String>[
      'Mantén la cadencia 175-185 spm. Vas en óptimo.',
      'Trabaja simetría: 1% más en derecha cierra el gap.',
      'Tu variabilidad bajó: estás más estable.',
    ],
  );
});
