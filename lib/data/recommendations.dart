import '../models/live_metrics.dart';
import '../models/recommendation_item.dart';

/// Static catalogue of contextual recommendation copies. Each entry is a
/// template — the live current value can be substituted by the caller
/// (the symmetry one is fully literal in the JSX, so we keep it static).
///
/// Phase 4 wires `recommendation_engine` outputs to richer, personalised
/// strings; this table is the deterministic mock used in demo mode.
// TODO(arc): expand with cadence, gct, strike, impact, variability copies.
class Recommendations {
  Recommendations._();

  static const RecommendationItem symmetry = RecommendationItem(
    captionLabel: 'Simetría · fuera de rango',
    body: 'Estás cargando más en la pierna izquierda. Relaja el hombro '
        'derecho y busca llegar parejo al suelo.',
    currentValue: '48/52',
    optimalValue: '50/50',
    currentStatus: MetricStatus.warn,
  );
}
