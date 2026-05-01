/// Lifecycle of a SportBand from BLE scan to streaming.
enum BandStatus {
  /// Scanning, no advertising packet seen yet.
  searching,

  /// Found an advertiser matching the expected name suffix; not yet connected.
  found,

  /// GATT connection established; ready to subscribe to sensor data.
  connected,

  /// Connection lost or scan failed (UI ready, mock does not trigger this yet).
  error,
}

/// Snapshot of one band. Driven by `BandNotifier` in mock; in Phase 4 the
/// `flutter_blue_plus` adapter populates the same shape from real scan results.
class BandState {
  const BandState({
    required this.nodeId,
    required this.name,
    required this.status,
    this.mac,
    this.rssi,
    this.battery,
  });

  /// Internal node id — `'LEFT_ANKLE'` or `'RIGHT_ANKLE'` (CLAUDE.md convention).
  final String nodeId;

  /// BLE device name — `'SportBand-L'` or `'SportBand-R'`.
  final String name;

  /// MAC address as `aa:bb:cc:dd:ee:ff` (or partial mock).
  final String? mac;

  final BandStatus status;

  /// Last advertised RSSI in dBm (negative — closer to 0 is stronger).
  final int? rssi;

  /// Battery percentage 0-100, available only after `connected`.
  final int? battery;

  BandState copyWith({
    BandStatus? status,
    int? rssi,
    int? battery,
    bool clearBattery = false,
  }) {
    return BandState(
      nodeId: nodeId,
      name: name,
      mac: mac,
      status: status ?? this.status,
      rssi: rssi ?? this.rssi,
      battery: clearBattery ? null : (battery ?? this.battery),
    );
  }
}
