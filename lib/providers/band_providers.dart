import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/band_state.dart';

/// Mock progression curve for one band. Replaced by real BLE in Phase 4.
class BandMockProgression {
  const BandMockProgression({
    required this.startDelay,
    required this.searchRssi,
    required this.foundRssi,
    required this.connectedRssi,
    required this.battery,
  });

  final Duration startDelay;
  final int searchRssi;
  final int foundRssi;
  final int connectedRssi;
  final int battery;
}

class BandNotifier extends StateNotifier<BandState> {
  BandNotifier(super.state, this._progression);

  final BandMockProgression _progression;
  Timer? _foundTimer;
  Timer? _connectedTimer;

  /// Restart the scan-→found-→connected progression. Idempotent: cancels any
  /// pending transitions before starting again.
  // TODO(arc): replace with flutter_blue_plus scan in Phase 4.
  void start() {
    _cancelTimers();
    state = state.copyWith(
      status: BandStatus.searching,
      rssi: _progression.searchRssi,
      clearBattery: true,
    );
    _foundTimer = Timer(
      _progression.startDelay + const Duration(milliseconds: 1500),
      _onFound,
    );
  }

  void _onFound() {
    if (!mounted) return;
    state = state.copyWith(
      status: BandStatus.found,
      rssi: _progression.foundRssi,
    );
    _connectedTimer = Timer(const Duration(milliseconds: 1500), _onConnected);
  }

  void _onConnected() {
    if (!mounted) return;
    state = state.copyWith(
      status: BandStatus.connected,
      rssi: _progression.connectedRssi,
      battery: _progression.battery,
    );
  }

  void _cancelTimers() {
    _foundTimer?.cancel();
    _foundTimer = null;
    _connectedTimer?.cancel();
    _connectedTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}

const BandState _initialLeft = BandState(
  nodeId: 'LEFT_ANKLE',
  name: 'SportBand-L',
  status: BandStatus.searching,
  mac: 'A4:C1:38:7B:21',
);

const BandState _initialRight = BandState(
  nodeId: 'RIGHT_ANKLE',
  name: 'SportBand-R',
  status: BandStatus.searching,
  mac: 'A4:C1:38:7B:9F',
);

const BandMockProgression _leftProgression = BandMockProgression(
  startDelay: Duration.zero,
  searchRssi: -65,
  foundRssi: -60,
  connectedRssi: -58,
  battery: 87,
);

const BandMockProgression _rightProgression = BandMockProgression(
  startDelay: Duration(milliseconds: 300),
  searchRssi: -72,
  foundRssi: -68,
  connectedRssi: -65,
  battery: 92,
);

final AutoDisposeStateNotifierProvider<BandNotifier, BandState> leftBandProvider =
    StateNotifierProvider.autoDispose<BandNotifier, BandState>((Ref ref) {
  final BandNotifier notifier = BandNotifier(_initialLeft, _leftProgression);
  notifier.start();
  return notifier;
});

final AutoDisposeStateNotifierProvider<BandNotifier, BandState> rightBandProvider =
    StateNotifierProvider.autoDispose<BandNotifier, BandState>((Ref ref) {
  final BandNotifier notifier = BandNotifier(_initialRight, _rightProgression);
  notifier.start();
  return notifier;
});

/// True iff both bands are in `BandStatus.connected`. Drives CTA enable state.
final AutoDisposeProvider<bool> bothBandsConnectedProvider =
    Provider.autoDispose<bool>((Ref ref) {
  final BandState l = ref.watch(leftBandProvider);
  final BandState r = ref.watch(rightBandProvider);
  return l.status == BandStatus.connected && r.status == BandStatus.connected;
});

/// Count of bands currently connected (0, 1, or 2). Drives the
/// "X DE 2 CONECTADAS" caption.
final AutoDisposeProvider<int> connectedBandsCountProvider =
    Provider.autoDispose<int>((Ref ref) {
  int count = 0;
  if (ref.watch(leftBandProvider).status == BandStatus.connected) count++;
  if (ref.watch(rightBandProvider).status == BandStatus.connected) count++;
  return count;
});
