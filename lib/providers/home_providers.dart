import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/home_stats.dart';

/// User name shown in the greeting. Mutable so settings / onboarding can
/// update it; default mock value matches the JSX literal.
final StateProvider<String> userNameProvider =
    StateProvider<String>((Ref ref) => 'Alberto');

/// Contextual coaching paragraph for the day. Phase 4 will wire this to the
/// recommendation engine; for now the copy is verbatim from the JSX.
// TODO(arc): replace with recommendation_engine output in Phase 4.
final Provider<String> recommendationProvider = Provider<String>((Ref ref) {
  return 'Tu pierna izquierda carga 3% más que la derecha en las últimas '
      '6 sesiones. Hoy enfócate en mantener simetría sobre los 50/50.';
});

/// Numeric aggregates for the Home screen. Values copied verbatim from
/// `screens-onboarding.jsx` (ScreenHomeA).
// TODO(arc): replace with aggregation over the session DB in Phase 4.
final Provider<HomeStats> homeStatsProvider = Provider<HomeStats>((Ref ref) {
  return const HomeStats(
    greetingDate: 'Lunes · 16:42',
    totalSessions: 47,
    totalKm: 218,
    streakDays: 12,
    score: 78,
    scoreTrendThisWeek: 4,
    scoreSpark: <int>[68, 71, 65, 74, 78, 82],
    cadenceSpm: 178,
    symmetryLeftPct: 49,
    symmetryRightPct: 51,
    gctMs: 232,
    technicalScore: 78,
  );
});
