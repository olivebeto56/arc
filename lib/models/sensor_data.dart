import 'dart:math' as math;

/// One decoded sample from a SportBand node.
///
/// Quaternion convention: Hamilton (w, x, y, z), as emitted by the BNO085
/// `SH2_ARVR_STABILIZED_RV` report. Euler angles are derived in ZYX
/// (Tait-Bryan) order — roll about X, pitch about Y, yaw about Z — to match
/// the project convention. All angles in degrees.
///
/// Acceleration is in m/s² (already converted from milli-g by the parser),
/// and gyroscope rates in °/s. Gyro fields are NaN when the source packet is
/// shorter than v3 (legacy v1/v2 firmware).
class SensorData {
  const SensorData({
    required this.chipId,
    required this.nodeId,
    required this.timestampMs,
    required this.qw,
    required this.qx,
    required this.qy,
    required this.qz,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.roll,
    required this.pitch,
    required this.yaw,
  });

  /// 4-hex factory id from the BLE local name `SportBand-XXXX`. Stable
  /// across resets and OS-level MAC rotation, so it's the only reliable
  /// way to identify a physical band over time. Used by the shake
  /// detector and the persistent `chipId → side` storage.
  final String chipId;

  /// `LEFT_ANKLE` / `RIGHT_ANKLE` once the user has identified the band
  /// in the pairing flow. Empty string while a band is connected but not
  /// yet assigned a side.
  final String nodeId;

  /// Source timestamp from the firmware, relative to session start (uint16,
  /// wraps every ~65 s). Reorder by arrival on the app side; do not treat as
  /// monotonically increasing.
  final int timestampMs;

  final double qw;
  final double qx;
  final double qy;
  final double qz;

  /// Linear + gravitational acceleration in m/s² (sensor frame).
  final double accelX;
  final double accelY;
  final double accelZ;

  /// Calibrated angular rates in °/s (sensor frame). NaN for v1/v2 packets.
  final double gyroX;
  final double gyroY;
  final double gyroZ;

  /// Euler angles in degrees, derived from the quaternion (ZYX Tait-Bryan).
  final double roll;
  final double pitch;
  final double yaw;

  /// Build from a quaternion + IMU sample, computing Euler angles on the way.
  factory SensorData.fromQuaternion({
    required String chipId,
    required String nodeId,
    required int timestampMs,
    required double qw,
    required double qx,
    required double qy,
    required double qz,
    required double accelX,
    required double accelY,
    required double accelZ,
    required double gyroX,
    required double gyroY,
    required double gyroZ,
  }) {
    const double rad2deg = 180.0 / math.pi;
    final double roll = math.atan2(
          2 * (qw * qx + qy * qz),
          1 - 2 * (qx * qx + qy * qy),
        ) *
        rad2deg;
    final double sinp = 2 * (qw * qy - qz * qx);
    final double pitch = sinp.abs() >= 1
        ? (math.pi / 2) * sinp.sign * rad2deg
        : math.asin(sinp) * rad2deg;
    final double yaw = math.atan2(
          2 * (qw * qz + qx * qy),
          1 - 2 * (qy * qy + qz * qz),
        ) *
        rad2deg;
    return SensorData(
      chipId: chipId,
      nodeId: nodeId,
      timestampMs: timestampMs,
      qw: qw,
      qx: qx,
      qy: qy,
      qz: qz,
      accelX: accelX,
      accelY: accelY,
      accelZ: accelZ,
      gyroX: gyroX,
      gyroY: gyroY,
      gyroZ: gyroZ,
      roll: roll,
      pitch: pitch,
      yaw: yaw,
    );
  }
}
