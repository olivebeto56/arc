/// Lifecycle of a SportBand from BLE scan to streaming.
enum BandStatus {
  /// No advertising packet seen yet — placeholder/idle state.
  searching,

  /// Advertiser visible in the scan list. Waiting for the user to tap
  /// the row in `ScanScreen` to initiate the GATT connection.
  found,

  /// User has tapped — GATT connection in progress (handshake, MTU,
  /// service discovery, characteristic subscriptions).
  connecting,

  /// GATT connection established; ready to subscribe to sensor data.
  connected,

  /// Connection lost or scan failed.
  error,
}

/// Snapshot of one band. The `chipId` (4 hex chars from the BLE local
/// name `SportBand-XXXX`) is the stable factory identifier; `nodeId` is
/// the side label assigned by the user via the shake-to-identify flow,
/// or empty string for bands that are connected but not yet identified.
class BandState {
  const BandState({
    required this.chipId,
    required this.nodeId,
    required this.name,
    required this.status,
    this.mac,
    this.rssi,
    this.battery,
  });

  /// 4-hex factory id from `SportBand-XXXX`. Stable across resets and
  /// OS-level MAC rotation. Empty for placeholder/searching states.
  final String chipId;

  /// `LEFT_ANKLE` / `RIGHT_ANKLE` if assigned, empty string otherwise.
  final String nodeId;

  /// BLE device name — `SportBand-XXXX`.
  final String name;

  /// MAC address as `aa:bb:cc:dd:ee:ff` on Android, opaque UUID on iOS.
  final String? mac;

  final BandStatus status;

  /// Last advertised RSSI in dBm (negative — closer to 0 is stronger).
  final int? rssi;

  /// Battery percentage 0-100, available only after `connected`.
  final int? battery;

  /// True when this band has been identified to an ankle.
  bool get isAssigned => nodeId.isNotEmpty;

  BandState copyWith({
    String? chipId,
    String? nodeId,
    String? name,
    BandStatus? status,
    String? mac,
    int? rssi,
    int? battery,
    bool clearBattery = false,
  }) {
    return BandState(
      chipId: chipId ?? this.chipId,
      nodeId: nodeId ?? this.nodeId,
      name: name ?? this.name,
      mac: mac ?? this.mac,
      status: status ?? this.status,
      rssi: rssi ?? this.rssi,
      battery: clearBattery ? null : (battery ?? this.battery),
    );
  }

  /// Empty placeholder used by the providers when no band is yet
  /// assigned to a slot. Renders as a "searching" card in the UI.
  static const BandState empty = BandState(
    chipId: '',
    nodeId: '',
    name: 'SportBand-…',
    status: BandStatus.searching,
  );
}
