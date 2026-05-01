import 'live_metrics.dart';

/// One contextual coaching cue surfaced over the dashboard when a metric
/// goes out of range. Copy and "actual / optimal" pair are usually pulled
/// from `data/recommendations.dart`; the live current value plugs in last.
class RecommendationItem {
  const RecommendationItem({
    required this.captionLabel,
    required this.body,
    required this.currentValue,
    required this.optimalValue,
    required this.currentStatus,
  });

  /// Caption shown at the top of the overlay, in `accent`. Already in the
  /// final form ("Simetría · fuera de rango"); the `Caption` widget will
  /// upper-case it.
  final String captionLabel;

  final String body;

  /// Pre-formatted current metric value, e.g. "48/52".
  final String currentValue;

  /// Pre-formatted optimal value, e.g. "50/50".
  final String optimalValue;

  final MetricStatus currentStatus;
}
