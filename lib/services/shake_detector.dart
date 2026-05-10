import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show debugPrint;

import '../models/sensor_data.dart';

/// Result of a shake-to-identify run.
class ShakeResult {
  const ShakeResult({
    required this.winnerChipId,
    required this.peaks,
  });

  /// chipId of the band the user shook, or null when:
  ///  - no band exceeded the minimum-shake threshold (timeout / nothing
  ///    happened), or
  ///  - both bands had similar peaks (ambiguous — user shook both, or
  ///    accidentally moved both).
  final String? winnerChipId;

  /// Per-chipId max accel-magnitude observed during the window. Useful
  /// for diagnostics / debug logs.
  final Map<String, double> peaks;

  bool get isAmbiguous => winnerChipId == null;
}

/// Detects which band the user is shaking by listening to the live
/// `SensorData` stream from `BleManager` for a fixed window. The winner
/// is the chipId with the highest peak magnitude — provided the peak
/// exceeds an absolute threshold AND beats the runner-up by a clear
/// margin (so a stationary spike on the other band doesn't accidentally
/// flip the assignment).
class ShakeDetector {
  ShakeDetector({
    required this.sensorStream,
    this.minPeak = _kMinPeak,
    this.minMargin = _kMinMargin,
  });

  /// Live, broadcast stream of decoded `SensorData` packets — typically
  /// `bleManager.sensorDataStream`.
  final Stream<SensorData> sensorStream;

  /// Minimum acceleration peak (m/s² above 1 g resting) for any band to
  /// be considered "shaken at all". Below this we assume the user
  /// hasn't started moving yet.
  final double minPeak;

  /// Minimum margin between the winner and the runner-up. If the gap is
  /// below this, the result is treated as ambiguous (probably both bands
  /// were moved).
  final double minMargin;

  static const double _kMinPeak = 5.0;
  static const double _kMinMargin = 3.0;

  /// Listen for `window` after this call and report the result. If no
  /// band reaches `minPeak` before `timeout`, returns an empty result
  /// (winnerChipId == null, peaks empty).
  ///
  /// Implementation notes:
  ///  - We work with `magnitude = sqrt(ax² + ay² + az²) - g`. Subtracting
  ///    g (9.80665) gives a "rest = 0" baseline that isn't affected by
  ///    orientation.
  ///  - The window is started on the first non-trivial sample so users
  ///    aren't penalised for taking a moment to start shaking.
  Future<ShakeResult> detect({
    Duration window = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final Map<String, double> peaks = <String, double>{};
    final Completer<ShakeResult> completer = Completer<ShakeResult>();
    StreamSubscription<SensorData>? sub;
    Timer? windowTimer;
    Timer? timeoutTimer;
    bool windowStarted = false;
    DateTime? windowEnd;

    void finish(ShakeResult result) {
      if (completer.isCompleted) return;
      windowTimer?.cancel();
      timeoutTimer?.cancel();
      sub?.cancel();
      completer.complete(result);
    }

    ShakeResult buildResult() {
      if (peaks.isEmpty) {
        debugPrint('[shake] no samples');
        return const ShakeResult(winnerChipId: null, peaks: <String, double>{});
      }
      final List<MapEntry<String, double>> sorted = peaks.entries.toList()
        ..sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
            b.value.compareTo(a.value));
      final MapEntry<String, double> top = sorted.first;
      final double runnerUp = sorted.length > 1 ? sorted[1].value : 0.0;
      final double margin = top.value - runnerUp;
      if (top.value < minPeak) {
        debugPrint(
            '[shake] no clear winner — top=${top.key}=${top.value.toStringAsFixed(1)} below minPeak=$minPeak');
        return ShakeResult(winnerChipId: null, peaks: peaks);
      }
      if (margin < minMargin) {
        debugPrint(
            '[shake] ambiguous — top=${top.key}=${top.value.toStringAsFixed(1)} runner=${runnerUp.toStringAsFixed(1)} margin=${margin.toStringAsFixed(1)} < minMargin=$minMargin');
        return ShakeResult(winnerChipId: null, peaks: peaks);
      }
      debugPrint(
          '[shake] winner=${top.key} peak=${top.value.toStringAsFixed(1)} margin=${margin.toStringAsFixed(1)}');
      return ShakeResult(winnerChipId: top.key, peaks: peaks);
    }

    sub = sensorStream.listen((SensorData data) {
      // Magnitude above gravity. Subtracting 9.80665 lets a stationary
      // band (which reads ~9.81 because of gravity) come out near 0.
      final double mag = math.sqrt(
            data.accelX * data.accelX +
                data.accelY * data.accelY +
                data.accelZ * data.accelZ,
          ) -
          9.80665;
      final double current = peaks[data.chipId] ?? 0.0;
      if (mag > current) {
        peaks[data.chipId] = mag;
      }

      // Start the measurement window only once *something* moves; the
      // user gets the full window length to keep shaking from there.
      if (!windowStarted && mag.abs() > 1.0) {
        windowStarted = true;
        windowEnd = DateTime.now().add(window);
        windowTimer = Timer(window, () => finish(buildResult()));
        debugPrint('[shake] window started, ends at $windowEnd');
      }
    });

    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        debugPrint('[shake] timeout reached without conclusive shake');
        finish(buildResult());
      }
    });

    return completer.future;
  }
}
