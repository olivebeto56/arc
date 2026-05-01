/// User-facing settings persisted across the app session.
///
/// Phase 4 will hydrate this from `shared_preferences`; for now everything
/// is in-memory and the navigate-row sub-screens that would mutate the
/// per-field values are still TODO.
class SettingsState {
  const SettingsState({
    required this.demoMode,
    required this.heightCm,
    required this.weightKg,
    required this.strideLengthM,
    required this.impactThreshold,
    required this.takeoffThreshold,
    required this.minStepDurationMs,
    required this.unitSystemLabel,
    required this.languageLabel,
  });

  /// True when the "Saltar (modo demo)" path was taken at Scan. Lets
  /// downstream providers short-circuit BLE / GPS calls and return mocks.
  final bool demoMode;

  // ─── Personal — values shown in the navigate rows ─────────────
  final int heightCm;
  final int weightKg;
  final double strideLengthM;

  // ─── Calibración ──────────────────────────────────────────────
  final double impactThreshold; // m/s²
  final double takeoffThreshold; // m/s²
  final int minStepDurationMs; // ms

  // ─── Units ────────────────────────────────────────────────────
  final String unitSystemLabel; // 'Métrico' / 'Imperial'
  final String languageLabel; // 'Español' / 'English'

  /// Mock defaults used by the JSX literal. The notifier returns these as
  /// the initial state.
  static const SettingsState defaults = SettingsState(
    demoMode: false,
    heightCm: 176,
    weightKg: 72,
    strideLengthM: 1.18,
    impactThreshold: 12,
    takeoffThreshold: 3,
    minStepDurationMs: 180,
    unitSystemLabel: 'Métrico',
    languageLabel: 'Español',
  );

  SettingsState copyWith({
    bool? demoMode,
    int? heightCm,
    int? weightKg,
    double? strideLengthM,
    double? impactThreshold,
    double? takeoffThreshold,
    int? minStepDurationMs,
    String? unitSystemLabel,
    String? languageLabel,
  }) {
    return SettingsState(
      demoMode: demoMode ?? this.demoMode,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      strideLengthM: strideLengthM ?? this.strideLengthM,
      impactThreshold: impactThreshold ?? this.impactThreshold,
      takeoffThreshold: takeoffThreshold ?? this.takeoffThreshold,
      minStepDurationMs: minStepDurationMs ?? this.minStepDurationMs,
      unitSystemLabel: unitSystemLabel ?? this.unitSystemLabel,
      languageLabel: languageLabel ?? this.languageLabel,
    );
  }
}
