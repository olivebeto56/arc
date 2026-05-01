import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tri-state model for a single permission. Drives both the badge label/colour
/// in `PermissionCard` and the enable state of the "CONTINUAR" button.
enum PermissionStatus { granted, pending, denied }

/// Mock state for the Bluetooth permission. Phase 4 will replace this with a
/// `permission_handler` notifier; until then the UI rotates through the three
/// statuses on tap.
final StateProvider<PermissionStatus> bluetoothPermissionProvider =
    StateProvider<PermissionStatus>((Ref ref) => PermissionStatus.pending);

/// Mock state for the Location permission. Same lifecycle as Bluetooth.
final StateProvider<PermissionStatus> locationPermissionProvider =
    StateProvider<PermissionStatus>((Ref ref) => PermissionStatus.pending);

/// True once both permissions are `granted`. Drives the CTA enable state.
final Provider<bool> allPermissionsGrantedProvider = Provider<bool>((Ref ref) {
  return ref.watch(bluetoothPermissionProvider) == PermissionStatus.granted &&
      ref.watch(locationPermissionProvider) == PermissionStatus.granted;
});
