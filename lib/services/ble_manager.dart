import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../models/band_state.dart';
import '../models/sensor_data.dart';
import 'sensor_parser.dart';

// BLE GATT identifiers — must match firmware/config.h byte for byte.
const String _kServiceUuid = '19b10000-e8f2-537e-4f6c-d104768a1214';
const String _kSensorUuid = '19b10001-e8f2-537e-4f6c-d104768a1214';
const String _kBatteryUuid = '19b10002-e8f2-537e-4f6c-d104768a1214';
// Config characteristic — kept here for future sample-rate writes (golf 200 Hz).
// ignore: unused_element
const String _kConfigUuid = '19b10003-e8f2-537e-4f6c-d104768a1214';

/// SportBand-XXXX advertising prefix. The firmware appends 4 hex chars
/// derived from the nRF52840 factory DEVICEID, so each physical band has a
/// stable name across resets and OS-level MAC rotation.
const String _kAdvNamePrefix = 'SportBand-';

/// App-side identifiers — the firmware does not know its own side.
const String kLeftAnkle = 'LEFT_ANKLE';
const String kRightAnkle = 'RIGHT_ANKLE';

/// Aggregate state surfaced by `bleManagerProvider`. Per-side `BandState`
/// objects are derived in `band_providers.dart`.
class BleManagerState {
  const BleManagerState({
    required this.left,
    required this.right,
    required this.scanning,
    this.error,
  });

  final BandState left;
  final BandState right;
  final bool scanning;

  /// Last unrecoverable scan/connect error message — surfaced verbatim in
  /// the scan screen footer in Phase 4 (Sprint 2 just logs).
  final String? error;

  static const BleManagerState initial = BleManagerState(
    left: BandState(
      nodeId: kLeftAnkle,
      name: 'SportBand-…',
      status: BandStatus.searching,
    ),
    right: BandState(
      nodeId: kRightAnkle,
      name: 'SportBand-…',
      status: BandStatus.searching,
    ),
    scanning: false,
  );

  BleManagerState copyWith({
    BandState? left,
    BandState? right,
    bool? scanning,
    String? error,
    bool clearError = false,
  }) {
    return BleManagerState(
      left: left ?? this.left,
      right: right ?? this.right,
      scanning: scanning ?? this.scanning,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Drives the BLE lifecycle for both ankle bands.
///
/// Lifecycle:
/// 1. On first read of `bleManagerProvider`, the constructor kicks off
///    `_init` which requests permissions, waits for the adapter, and starts
///    a service-UUID-filtered scan.
/// 2. As `SportBand-XXXX` advertisers arrive, the strongest two not yet
///    paired are assigned to the LEFT and RIGHT slots respectively. This is
///    a v1 heuristic — proper "shake the left band" pairing with `chip_id →
///    side` persistence lands later. (See CLAUDE.md §5.)
/// 3. Both bands are connected in parallel (`_connect` is fire-and-forget,
///    not sequential), services discovered, and notifications subscribed on
///    the sensor + battery characteristics.
/// 4. On disconnect, status flips to `error`/`searching` and a 2 s backoff
///    reconnect is scheduled. Sensor data is funnelled to a broadcast
///    `Stream<SensorData>` for downstream metrics consumers.
class BleManager extends StateNotifier<BleManagerState> {
  BleManager() : super(BleManagerState.initial) {
    _init();
  }

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  StreamSubscription<bool>? _isScanningSub;

  /// One `_BandConnection` per assigned side, holding device + subscriptions.
  final Map<String, _BandConnection> _conns = <String, _BandConnection>{};

  /// Track BLE remoteIds we've already assigned to avoid double-pairing the
  /// same physical band into both slots when a duplicate scan result fires.
  final Map<String, String> _assigned = <String, String>{};

  bool _disposed = false;

  /// Broadcast stream of decoded sensor packets — both bands feed it.
  /// Subscribers (metrics engine, recording layer) attach via
  /// `bleManager.sensorDataStream`.
  final StreamController<SensorData> _sensorCtrl =
      StreamController<SensorData>.broadcast();

  Stream<SensorData> get sensorDataStream => _sensorCtrl.stream;

  Future<void> _init() async {
    _adapterSub = FlutterBluePlus.adapterState.listen((BluetoothAdapterState s) {
      if (_disposed) return;
      if (s == BluetoothAdapterState.on) {
        // Auto-resume scanning when the user toggles BT back on.
        if (!state.scanning && _conns.length < 2) {
          restartScan();
        }
      } else {
        _markBothError('Bluetooth apagado');
      }
    });

    _isScanningSub = FlutterBluePlus.isScanning.listen((bool isScanning) {
      if (_disposed) return;
      if (state.scanning != isScanning) {
        state = state.copyWith(scanning: isScanning);
      }
    });

    await restartScan();
  }

  Future<bool> _ensurePermissions() async {
    if (Platform.isAndroid) {
      final Map<ph.Permission, ph.PermissionStatus> res = await <ph.Permission>[
        ph.Permission.bluetoothScan,
        ph.Permission.bluetoothConnect,
        // locationWhenInUse is only required on Android < 12, but requesting
        // it on 12+ is a no-op and keeps the call site simple.
        ph.Permission.locationWhenInUse,
      ].request();
      // bluetoothScan + bluetoothConnect must be granted; location is needed
      // only on legacy Android — accept any non-permanent state for it.
      final bool scanOk = res[ph.Permission.bluetoothScan]?.isGranted ?? false;
      final bool connOk = res[ph.Permission.bluetoothConnect]?.isGranted ?? false;
      return scanOk && connOk;
    }
    if (Platform.isIOS) {
      final ph.PermissionStatus s = await ph.Permission.bluetooth.request();
      // iOS: `bluetooth` resolves to "granted" after the first system
      // prompt; fall back to allowing if `permanentlyDenied` is not set, as
      // some iOS versions report `denied` even when usable.
      return !s.isPermanentlyDenied;
    }
    return true;
  }

  /// Restart the scan, dropping any existing connections. Wired to the
  /// "REESCANEAR" button in `scan_screen.dart`.
  Future<void> restartScan() async {
    if (_disposed) return;

    await _stopScanInternal();

    // Tear down any previous connections so we re-pair fresh.
    final List<Future<void>> teardown = <Future<void>>[
      for (final _BandConnection c in _conns.values) c.disconnect(),
    ];
    await Future.wait<void>(teardown);
    _conns.clear();
    _assigned.clear();

    state = state.copyWith(
      left: state.left.copyWith(
        status: BandStatus.searching,
        clearBattery: true,
      ),
      right: state.right.copyWith(
        status: BandStatus.searching,
        clearBattery: true,
      ),
      clearError: true,
    );

    if (!await _ensurePermissions()) {
      _markBothError('Permisos BLE denegados');
      return;
    }

    // Adapter must be ON before calling startScan — otherwise it throws.
    final BluetoothAdapterState adapter =
        await FlutterBluePlus.adapterState.first;
    if (adapter != BluetoothAdapterState.on) {
      _markBothError('Bluetooth apagado');
      return;
    }

    _scanSub = FlutterBluePlus.scanResults.listen(
      _onScanResults,
      onError: (Object e) {
        state = state.copyWith(error: 'Error de escaneo: $e');
      },
    );

    try {
      await FlutterBluePlus.startScan(
        withServices: <Guid>[Guid(_kServiceUuid)],
        timeout: const Duration(seconds: 30),
        // Re-emit the same device with refreshed RSSI on every advertisement
        // — needed so the UI can show a live signal indicator while pairing.
        continuousUpdates: true,
      );
    } on Exception catch (e) {
      state = state.copyWith(error: 'No pude iniciar el scan: $e');
    }
  }

  Future<void> _stopScanInternal() async {
    await _scanSub?.cancel();
    _scanSub = null;
    if (await FlutterBluePlus.isScanning.first) {
      try {
        await FlutterBluePlus.stopScan();
      } on Exception catch (_) {
        // ignore — not fatal.
      }
    }
  }

  void _onScanResults(List<ScanResult> results) {
    if (_disposed) return;

    // Sort by RSSI desc so the closest band claims the first free slot.
    final List<ScanResult> sportBands = results
        .where(
          (ScanResult r) => r.device.advName.startsWith(_kAdvNamePrefix),
        )
        .toList()
      ..sort((ScanResult a, ScanResult b) => b.rssi.compareTo(a.rssi));

    for (final ScanResult r in sportBands) {
      final String remoteId = r.device.remoteId.str;

      // Already paired to a slot — just refresh RSSI.
      final String? assigned = _assigned[remoteId];
      if (assigned != null) {
        _setBand(assigned, rssi: r.rssi);
        continue;
      }

      // Pick the next free slot.
      final String? slot = !_assigned.values.contains(kLeftAnkle)
          ? kLeftAnkle
          : !_assigned.values.contains(kRightAnkle)
              ? kRightAnkle
              : null;
      if (slot == null) continue;

      _assigned[remoteId] = slot;
      _setBand(
        slot,
        status: BandStatus.found,
        name: r.device.advName,
        mac: remoteId,
        rssi: r.rssi,
      );
      // Fire-and-forget — connecting in parallel is the whole point.
      // ignore: unawaited_futures
      _connect(r.device, slot);
    }

    if (_assigned.values.toSet().length >= 2) {
      // Both slots claimed; no need to keep scanning.
      // ignore: unawaited_futures
      _stopScanInternal();
    }
  }

  Future<void> _connect(BluetoothDevice device, String nodeId) async {
    final _BandConnection conn = _BandConnection(
      device: device,
      nodeId: nodeId,
      manager: this,
    );
    _conns[nodeId] = conn;
    try {
      await conn.connectAndSubscribe();
    } on Exception {
      _setBand(nodeId, status: BandStatus.error);
    }
  }

  void _markBothError(String msg) {
    state = state.copyWith(
      error: msg,
      left: state.left.copyWith(status: BandStatus.error),
      right: state.right.copyWith(status: BandStatus.error),
    );
  }

  /// Mutate one band's slice of state. Fields default to "keep current".
  void _setBand(
    String nodeId, {
    BandStatus? status,
    String? name,
    String? mac,
    int? rssi,
    int? battery,
    bool clearBattery = false,
  }) {
    if (_disposed) return;
    if (nodeId == kLeftAnkle) {
      final BandState l = state.left;
      state = state.copyWith(
        left: BandState(
          nodeId: kLeftAnkle,
          name: name ?? l.name,
          mac: mac ?? l.mac,
          status: status ?? l.status,
          rssi: rssi ?? l.rssi,
          battery: clearBattery ? null : (battery ?? l.battery),
        ),
      );
    } else if (nodeId == kRightAnkle) {
      final BandState r = state.right;
      state = state.copyWith(
        right: BandState(
          nodeId: kRightAnkle,
          name: name ?? r.name,
          mac: mac ?? r.mac,
          status: status ?? r.status,
          rssi: rssi ?? r.rssi,
          battery: clearBattery ? null : (battery ?? r.battery),
        ),
      );
    }
  }

  void _emit(SensorData data) {
    if (_disposed || _sensorCtrl.isClosed) return;
    _sensorCtrl.add(data);
  }

  /// Async teardown — call from `ref.onDispose` so we can await disconnects.
  Future<void> disposeAsync() async {
    _disposed = true;
    await _stopScanInternal();
    await _adapterSub?.cancel();
    await _isScanningSub?.cancel();
    final List<Future<void>> teardown = <Future<void>>[
      for (final _BandConnection c in _conns.values) c.disconnect(),
    ];
    await Future.wait<void>(teardown);
    _conns.clear();
    _assigned.clear();
    await _sensorCtrl.close();
  }

  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      // Best-effort sync teardown — ignore any awaits we cannot run here.
      _scanSub?.cancel();
      _adapterSub?.cancel();
      _isScanningSub?.cancel();
      for (final _BandConnection c in _conns.values) {
        // ignore: unawaited_futures
        c.disconnect();
      }
      _sensorCtrl.close();
    }
    super.dispose();
  }
}

/// Per-band connection holder. Keeps the device, the connectionState
/// subscription, and the per-characteristic notification subscriptions.
class _BandConnection {
  _BandConnection({
    required this.device,
    required this.nodeId,
    required this.manager,
  });

  final BluetoothDevice device;
  final String nodeId;
  final BleManager manager;

  StreamSubscription<BluetoothConnectionState>? _stateSub;
  StreamSubscription<List<int>>? _sensorSub;
  StreamSubscription<List<int>>? _batterySub;

  bool _disposing = false;

  Future<void> connectAndSubscribe() async {
    _stateSub ??= device.connectionState.listen(_onConnectionState);

    await device.connect(
      timeout: const Duration(seconds: 10),
      autoConnect: false,
    );

    // Larger MTU allows the firmware to fit a 22-byte sensor packet plus
    // ATT overhead inside a single notify (no fragmentation). iOS handles
    // MTU automatically — calling there is unnecessary.
    if (Platform.isAndroid) {
      try {
        await device.requestMtu(247);
      } on Exception {
        // Some Android stacks reject — fall back to default MTU.
      }
    }

    await _discoverAndSubscribe();
    manager._setBand(nodeId, status: BandStatus.connected);
  }

  Future<void> _discoverAndSubscribe() async {
    await _sensorSub?.cancel();
    await _batterySub?.cancel();
    _sensorSub = null;
    _batterySub = null;

    final List<BluetoothService> services = await device.discoverServices();

    for (final BluetoothService svc in services) {
      if (svc.uuid != Guid(_kServiceUuid)) continue;

      for (final BluetoothCharacteristic c in svc.characteristics) {
        if (c.uuid == Guid(_kSensorUuid) && c.properties.notify) {
          await c.setNotifyValue(true);
          _sensorSub = c.lastValueStream.listen((List<int> bytes) {
            if (bytes.length < 14) return;
            final SensorData? data = SensorParser.parse(bytes, nodeId);
            if (data != null) manager._emit(data);
          });
        } else if (c.uuid == Guid(_kBatteryUuid)) {
          // Read once so the UI shows a number immediately, then subscribe
          // to notifications (the firmware emits one every 10 s).
          try {
            final List<int> v = await c.read();
            if (v.isNotEmpty) {
              manager._setBand(nodeId, battery: v[0]);
            }
          } on Exception {
            // ignore — keep going.
          }
          if (c.properties.notify) {
            await c.setNotifyValue(true);
            _batterySub = c.lastValueStream.listen((List<int> bytes) {
              if (bytes.isNotEmpty) {
                manager._setBand(nodeId, battery: bytes[0]);
              }
            });
          }
        }
      }
    }
  }

  void _onConnectionState(BluetoothConnectionState s) {
    if (_disposing) return;
    if (s != BluetoothConnectionState.disconnected) return;

    manager._setBand(
      nodeId,
      status: BandStatus.error,
      clearBattery: true,
    );

    // Simple 2 s backoff reconnect. The connectionState listener stays
    // subscribed across reconnects, so we just call connect() again.
    Future<void>.delayed(const Duration(seconds: 2), () async {
      if (_disposing) return;
      try {
        manager._setBand(nodeId, status: BandStatus.searching);
        await device.connect(
          timeout: const Duration(seconds: 10),
          autoConnect: false,
        );
        await _discoverAndSubscribe();
        manager._setBand(nodeId, status: BandStatus.connected);
      } on Exception {
        manager._setBand(nodeId, status: BandStatus.error);
      }
    });
  }

  Future<void> disconnect() async {
    _disposing = true;
    await _sensorSub?.cancel();
    await _batterySub?.cancel();
    await _stateSub?.cancel();
    try {
      await device.disconnect();
    } on Exception {
      // Already disconnected — fine.
    }
  }
}

/// Singleton-per-app BleManager. Non-autoDispose so connections persist
/// across screen transitions (scan → home → dashboard).
final StateNotifierProvider<BleManager, BleManagerState> bleManagerProvider =
    StateNotifierProvider<BleManager, BleManagerState>((Ref ref) {
  final BleManager m = BleManager();
  ref.onDispose(() {
    // Fire-and-forget async teardown; Riverpod doesn't await onDispose.
    // ignore: unawaited_futures
    m.disposeAsync();
  });
  return m;
});

/// Decoded sensor data stream — subscribers get every parsed packet from
/// either band. Used by the metrics engine in Sprint 3.
final Provider<Stream<SensorData>> sensorDataStreamProvider =
    Provider<Stream<SensorData>>((Ref ref) {
  return ref.watch(bleManagerProvider.notifier).sensorDataStream;
});
