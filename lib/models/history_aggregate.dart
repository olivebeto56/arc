/// Roll-up shown above the session list on the History screen.
///
/// Phase 4 derives this from the filtered list; the mock returns the
/// JSX-literal values regardless of the active period filter.
class HistoryAggregate {
  const HistoryAggregate({
    required this.sessionsCount,
    required this.totalKm,
    required this.totalHoursLabel,
    required this.avgScore,
  });

  final int sessionsCount;
  final double totalKm;

  /// Pre-formatted hours label, e.g. `'7:42'`.
  final String totalHoursLabel;

  final int avgScore;
}
