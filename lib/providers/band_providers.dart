import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/band_state.dart';
import '../services/ble_manager.dart';

/// Per-side `BandState` derived from the shared `bleManagerProvider`. These
/// are non-autoDispose: BLE connections must survive screen transitions
/// (scan → home → dashboard), so any consumer can keep watching them.
final Provider<BandState> leftBandProvider = Provider<BandState>(
  (Ref ref) => ref.watch(bleManagerProvider).left,
);

final Provider<BandState> rightBandProvider = Provider<BandState>(
  (Ref ref) => ref.watch(bleManagerProvider).right,
);

/// True iff both bands are in `BandStatus.connected`. Drives the scan-screen
/// "CONTINUAR" CTA enable state.
final Provider<bool> bothBandsConnectedProvider = Provider<bool>((Ref ref) {
  final BandState l = ref.watch(leftBandProvider);
  final BandState r = ref.watch(rightBandProvider);
  return l.status == BandStatus.connected && r.status == BandStatus.connected;
});

/// 0, 1, or 2 — drives the "X DE 2 CONECTADAS" caption.
final Provider<int> connectedBandsCountProvider = Provider<int>((Ref ref) {
  int count = 0;
  if (ref.watch(leftBandProvider).status == BandStatus.connected) count++;
  if (ref.watch(rightBandProvider).status == BandStatus.connected) count++;
  return count;
});
