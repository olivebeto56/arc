import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/history_aggregate.dart';
import '../models/history_period.dart';
import '../models/live_metrics.dart';
import '../models/session_summary.dart';

// ─── Saved sessions ────────────────────────────────────────────

/// In-memory list of saved sessions, newest first. Phase 4 wires this to
/// the local DB (drift / isar). Until then, sessions live for the app run.
class SessionHistoryNotifier extends StateNotifier<List<SessionSummaryData>> {
  SessionHistoryNotifier() : super(_seed());

  /// Hardcoded seed matching the literal table from `ScreenHistory` in
  /// the JSX. The dates are computed relative to `DateTime.now()` so the
  /// "Hoy" entry stays accurate.
  static List<SessionSummaryData> _seed() {
    final DateTime now = DateTime.now();
    SessionSummaryData entry({
      required String dateLabel,
      required int daysAgo,
      required String sessionType,
      required Duration duration,
      required double distanceKm,
      required String avgPaceLabel,
      required int score,
      required List<double> cadenceSpark,
      required int cadenceAvg,
    }) {
      return SessionSummaryData(
        dateLabel: dateLabel,
        sessionDate: now.subtract(Duration(days: daysAgo)),
        sessionType: sessionType,
        totalDuration: duration,
        distanceKm: distanceKm,
        avgPaceLabel: avgPaceLabel,
        score: score,
        scoreTrend: 0,
        scoreBlurb: '',
        cadenceTimeSeries: cadenceSpark,
        cadenceAvgSpm: cadenceAvg,
        symmetryLeftPct: 50,
        symmetryRightPct: 50,
        symmetryStatus: MetricStatus.ok,
        gctAvgMs: 230,
        peakImpact: 12,
        variability: 4.5,
        recommendations: const <String>[],
      );
    }

    return <SessionSummaryData>[
      entry(
        dateLabel: 'Hoy · 17:34',
        daysAgo: 0,
        sessionType: 'Libre',
        duration: const Duration(minutes: 32, seconds: 18),
        distanceKm: 5.78,
        avgPaceLabel: '5:35',
        score: 82,
        cadenceSpark: const <double>[175, 178, 182, 178, 175, 178],
        cadenceAvg: 178,
      ),
      entry(
        dateLabel: 'Mié · 06:42',
        daysAgo: 2,
        sessionType: 'Tiempo · 25min',
        duration: const Duration(minutes: 24, seconds: 51),
        distanceKm: 4.12,
        avgPaceLabel: '6:02',
        score: 75,
        cadenceSpark: const <double>[170, 172, 168, 175, 178, 176],
        cadenceAvg: 173,
      ),
      entry(
        dateLabel: 'Lun · 18:10',
        daysAgo: 4,
        sessionType: 'Distancia · 7km',
        duration: const Duration(minutes: 38, seconds: 42),
        distanceKm: 7.20,
        avgPaceLabel: '5:23',
        score: 79,
        cadenceSpark: const <double>[172, 176, 180, 178, 176, 175],
        cadenceAvg: 176,
      ),
      entry(
        dateLabel: '8 jun · 17:00',
        daysAgo: 6,
        sessionType: 'Libre',
        duration: const Duration(minutes: 28, seconds: 30),
        distanceKm: 5.00,
        avgPaceLabel: '5:42',
        score: 71,
        cadenceSpark: const <double>[165, 170, 172, 168, 170, 172],
        cadenceAvg: 169,
      ),
      entry(
        dateLabel: '6 jun · 06:30',
        daysAgo: 8,
        sessionType: 'Libre',
        duration: const Duration(minutes: 22, seconds: 15),
        distanceKm: 3.85,
        avgPaceLabel: '5:46',
        score: 80,
        cadenceSpark: const <double>[178, 180, 182, 178, 176, 178],
        cadenceAvg: 178,
      ),
    ];
  }

  void save(SessionSummaryData summary) {
    state = <SessionSummaryData>[summary, ...state];
  }
}

final StateNotifierProvider<SessionHistoryNotifier, List<SessionSummaryData>>
    sessionHistoryProvider =
    StateNotifierProvider<SessionHistoryNotifier, List<SessionSummaryData>>(
  (Ref ref) => SessionHistoryNotifier(),
);

// ─── Period filter ─────────────────────────────────────────────

final StateProvider<HistoryPeriod> selectedPeriodProvider =
    StateProvider<HistoryPeriod>((Ref ref) => HistoryPeriod.month);

final Provider<List<SessionSummaryData>> filteredHistoryProvider =
    Provider<List<SessionSummaryData>>((Ref ref) {
  final List<SessionSummaryData> all = ref.watch(sessionHistoryProvider);
  final HistoryPeriod period = ref.watch(selectedPeriodProvider);
  final DateTime now = DateTime.now();
  final DateTime cutoff = switch (period) {
    HistoryPeriod.week => now.subtract(const Duration(days: 7)),
    HistoryPeriod.month => now.subtract(const Duration(days: 30)),
    HistoryPeriod.all => DateTime(0),
  };
  return all
      .where((SessionSummaryData s) => s.sessionDate.isAfter(cutoff))
      .toList();
});

// ─── Aggregate stats ───────────────────────────────────────────

/// Hardcoded JSX-literal aggregate. Phase 4 derives this from the
/// filtered list (sum km, count sessions, sum hours, avg score).
final Provider<HistoryAggregate> aggregateStatsProvider =
    Provider<HistoryAggregate>((Ref ref) {
  return const HistoryAggregate(
    sessionsCount: 12,
    totalKm: 52.4,
    totalHoursLabel: '7:42',
    avgScore: 78,
  );
});
