import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/settings_state.dart';

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState.defaults);

  void setDemoMode(bool value) {
    state = state.copyWith(demoMode: value);
  }

  void resetCalibrationDefaults() {
    state = state.copyWith(
      impactThreshold: SettingsState.defaults.impactThreshold,
      takeoffThreshold: SettingsState.defaults.takeoffThreshold,
      minStepDurationMs: SettingsState.defaults.minStepDurationMs,
    );
  }

  // TODO(arc): expose setters for impactThreshold / takeoffThreshold /
  // minStepDurationMs / heightCm / etc. once the sub-screens land that
  // mutate them. For now the values stay at JSX-literal defaults.
}

final StateNotifierProvider<SettingsNotifier, SettingsState> settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (Ref ref) => SettingsNotifier(),
);
