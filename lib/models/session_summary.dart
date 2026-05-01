import 'live_metrics.dart';

/// Frozen post-session report. Phase 4 will derive this from the session DB
/// (event timestamps + raw IMU samples → analyser output). For now the
/// `sessionSummaryProvider` returns a constant matching the JSX literal of
/// `ScreenSummary`.
class SessionSummaryData {
  const SessionSummaryData({
    required this.dateLabel,
    required this.sessionDate,
    required this.sessionType,
    required this.totalDuration,
    required this.distanceKm,
    required this.avgPaceLabel,
    required this.score,
    required this.scoreTrend,
    required this.scoreBlurb,
    required this.cadenceTimeSeries,
    required this.cadenceAvgSpm,
    required this.symmetryLeftPct,
    required this.symmetryRightPct,
    required this.symmetryStatus,
    required this.gctAvgMs,
    required this.peakImpact,
    required this.variability,
    required this.recommendations,
  });

  /// Pre-formatted date string ("Sábado 14 · junio · 17:34").
  final String dateLabel;

  /// Real DateTime — used by `filteredHistoryProvider` for period filtering
  /// and sort. The `dateLabel` is the display-only formatted version.
  final DateTime sessionDate;

  /// Session goal label — `'Libre'`, `'Tiempo · 25min'`, `'Distancia · 7km'`.
  /// Phase 4 turns this into a structured `SessionGoal` enum + value.
  final String sessionType;

  final Duration totalDuration;
  final double distanceKm;

  /// Pre-formatted pace string ("5:35").
  final String avgPaceLabel;

  /// 0-100 technical score.
  final int score;

  /// Delta vs historical mean (positive = better).
  final int scoreTrend;

  /// Short blurb describing the session quality.
  final String scoreBlurb;

  final List<double> cadenceTimeSeries;
  final int cadenceAvgSpm;

  final double symmetryLeftPct;
  final double symmetryRightPct;
  final MetricStatus symmetryStatus;

  final int gctAvgMs;
  final double peakImpact;
  final double variability;

  final List<String> recommendations;
}
