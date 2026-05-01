/// Snapshot of the values the Home screen renders.
///
/// User-facing copy that mutates between sessions (greeting, recommendation,
/// user name) lives in its own provider — this model only holds the numeric
/// aggregates that come from the session DB.
class HomeStats {
  const HomeStats({
    required this.greetingDate,
    required this.totalSessions,
    required this.totalKm,
    required this.streakDays,
    required this.score,
    required this.scoreTrendThisWeek,
    required this.scoreSpark,
    required this.cadenceSpm,
    required this.symmetryLeftPct,
    required this.symmetryRightPct,
    required this.gctMs,
    required this.technicalScore,
  });

  final String greetingDate;

  // Lifetime totals (stats line).
  final int totalSessions;
  final double totalKm;
  final int streakDays;

  // Hero score + sparkline (also reused inside Promedios card).
  final int score;
  final int scoreTrendThisWeek;
  final List<int> scoreSpark;

  // "Promedios — últimas 10" card metrics.
  final int cadenceSpm;
  final int symmetryLeftPct;
  final int symmetryRightPct;
  final int gctMs;
  final int technicalScore;
}
