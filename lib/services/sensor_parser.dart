import 'dart:typed_data';

import '../models/sensor_data.dart';

/// Decodes the BLE notify payload emitted by the SportBand firmware.
///
/// The firmware always emits **v3** (22 bytes). The parser also degrades to
/// the legacy formats so a mixed-version setup never throws on an unexpected
/// length:
///
/// ```
/// v1 = 14 B  ts + quat + accel_x + accel_y                       (no accel_z, no gyro)
/// v2 = 16 B  ts + quat + accel_x + accel_y + accel_z             (no gyro)
/// v3 = 22 B  ts + quat + accel + gyro_x + gyro_y + gyro_z        (current)
/// ```
///
/// Layout (little-endian, all int16 except byte 0..1 which is uint16):
///   [0..1]   timestamp_ms (uint16, relative to session start)
///   [2..3]   qw * 10000   (int16)
///   [4..5]   qx * 10000
///   [6..7]   qy * 10000
///   [8..9]   qz * 10000
///   [10..11] accel_x in milli-g
///   [12..13] accel_y in milli-g
///   [14..15] accel_z in milli-g                       (v2+)
///   [16..17] gyro_x  * GYRO_SCALE (default 100 → °/s) (v3 only)
///   [18..19] gyro_y  * GYRO_SCALE
///   [20..21] gyro_z  * GYRO_SCALE
class SensorParser {
  static const double _quatScale = 1.0 / 10000.0;
  // milli-g → m/s². Firmware uses g = 9.80665.
  static const double _accelScale = 9.80665 / 1000.0;
  // int16 → °/s. GYRO_SCALE in firmware/config.h defaults to 100 (running/gym).
  // Drop to 10 for golf (wrist peaks ~2000 °/s); keep firmware and parser in sync.
  static const double _defaultGyroScale = 1.0 / 100.0;

  /// Returns null when the payload is too short to even contain a v1 packet.
  /// Otherwise returns a fully populated `SensorData` (gyro fields are NaN
  /// for v1/v2 packets).
  ///
  /// `chipId` is the stable 4-hex factory identifier (lower 16 bits of the
  /// nRF52840 DEVICEID, encoded by the firmware in the BLE local name
  /// `SportBand-XXXX`). `nodeId` is the side label (`LEFT_ANKLE` /
  /// `RIGHT_ANKLE`) — empty string when the band is connected but not yet
  /// assigned a side via the pairing flow.
  static SensorData? parse(
    List<int> bytes,
    String chipId,
    String nodeId, {
    double gyroScale = _defaultGyroScale,
  }) {
    if (bytes.length < 14) return null;

    final ByteData buf = ByteData.sublistView(Uint8List.fromList(bytes));

    final int ts = buf.getUint16(0, Endian.little);
    final double qw = buf.getInt16(2, Endian.little) * _quatScale;
    final double qx = buf.getInt16(4, Endian.little) * _quatScale;
    final double qy = buf.getInt16(6, Endian.little) * _quatScale;
    final double qz = buf.getInt16(8, Endian.little) * _quatScale;
    final double ax = buf.getInt16(10, Endian.little) * _accelScale;
    final double ay = buf.getInt16(12, Endian.little) * _accelScale;
    final double az = bytes.length >= 16
        ? buf.getInt16(14, Endian.little) * _accelScale
        : 0.0;
    final double gx = bytes.length >= 22
        ? buf.getInt16(16, Endian.little) * gyroScale
        : double.nan;
    final double gy = bytes.length >= 22
        ? buf.getInt16(18, Endian.little) * gyroScale
        : double.nan;
    final double gz = bytes.length >= 22
        ? buf.getInt16(20, Endian.little) * gyroScale
        : double.nan;

    return SensorData.fromQuaternion(
      chipId: chipId,
      nodeId: nodeId,
      timestampMs: ts,
      qw: qw,
      qx: qx,
      qy: qy,
      qz: qz,
      accelX: ax,
      accelY: ay,
      accelZ: az,
      gyroX: gx,
      gyroY: gy,
      gyroZ: gz,
    );
  }
}
