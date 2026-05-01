/// Visual range bucket for a metric — drives the colour of the card border
/// and the recommendation banner.
enum MetricStatus { ok, warn, crit }

/// Snapshot of all live biomechanics metrics emitted ~4 Hz by the
/// `liveMetricsProvider` mock. Phase 4 will wire this to the
/// `biomechanics-analyzer` running on the BLE samples.
class LiveMetrics {
  const LiveMetrics({
    required this.cadenceSpm,
    required this.symmetryLeftPct,
    required this.gctMs,
    required this.impactLoad,
    required this.strikeAngle,
    required this.variability,
    required this.symmetryWarning,
    required this.warningCycleId,
  });

  final double cadenceSpm;
  final double symmetryLeftPct;
  final double gctMs;
  final double impactLoad;
  final double strikeAngle;
  final double variability;

  /// True while the symmetry pulse is forcing an out-of-range value (mock).
  /// In Phase 4 this becomes a generic per-metric warning flag.
  final bool symmetryWarning;

  /// Increments every time the symmetry warning re-triggers. Lets the
  /// recommendation overlay tell "this is a new pulse" from "still the same".
  final int warningCycleId;

  static const LiveMetrics initial = LiveMetrics(
    cadenceSpm: 178,
    symmetryLeftPct: 50,
    gctMs: 232,
    impactLoad: 11,
    strikeAngle: 5,
    variability: 4,
    symmetryWarning: false,
    warningCycleId: 0,
  );
}

/// Threshold tables — match the JSX status decisions for ScreenDashboardB.
/// Values are tighter than the CLAUDE.md raíz "biomechanics reference"
/// because the JSX uses them as the demo source of truth.
class MetricThresholds {
  MetricThresholds._();

  static MetricStatus cadence(double v) {
    if (v >= 175 && v <= 185) return MetricStatus.ok;
    if (v >= 165 && v <= 195) return MetricStatus.warn;
    return MetricStatus.crit;
  }

  static MetricStatus symmetryLeft(double v) {
    if (v >= 47 && v <= 53) return MetricStatus.ok;
    if (v >= 45 && v <= 55) return MetricStatus.warn;
    return MetricStatus.crit;
  }

  static MetricStatus gct(double v) {
    if (v >= 200 && v <= 250) return MetricStatus.ok;
    if (v >= 180 && v <= 280) return MetricStatus.warn;
    return MetricStatus.crit;
  }

  static MetricStatus impact(double v) {
    if (v >= 8 && v <= 15) return MetricStatus.ok;
    if (v >= 6 && v <= 18) return MetricStatus.warn;
    return MetricStatus.crit;
  }

  static MetricStatus strike(double v) {
    if (v >= 0 && v <= 10) return MetricStatus.ok;
    if (v >= -5 && v <= 15) return MetricStatus.warn;
    return MetricStatus.crit;
  }

  static MetricStatus variability(double v) {
    if (v >= 3 && v <= 6) return MetricStatus.ok;
    if (v >= 2 && v <= 8) return MetricStatus.warn;
    return MetricStatus.crit;
  }
}
