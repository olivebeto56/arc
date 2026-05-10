import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../models/band_state.dart';
import '../models/sensor_data.dart';
import 'band_assignment_storage.dart';
import 'sensor_parser.dart';

// BLE GATT identifiers — must match firmware/config.h byte for byte.
const String _kServiceUuid = '19b10000-e8f2-537e-4f6c-d104768a1214';
const String _kSensorUuid = '19b10001-e8f2-537e-4f6c-d104768a1214';
const String _kBatteryUuid = '19b10002-e8f2-537e-4f6c-d104768a1214';
// Config characteristic — kept here for future sample-rate writes (golf 200 Hz).
// ignore: unused_element
const String _kConfigUuid = '19b10003-e8f2-537e-4f6c-d104768a1214';

/// SportBand-XXXX advertising prefix. The firmware appends 4 hex chars
/// derived from the nRF52840 factory DEVICEID, so each physical band has
/// a stable name across resets and OS-level MAC rotation.
const String _kAdvNamePrefix = 'SportBand-';

/// State surfaced by `bleManagerProvider`. Bands are keyed by `chipId`
/// (the 4-hex identity) so the manager can hold connections without
/// requiring a side assignment yet — the shake-to-identify flow runs
/// AFTER both bands are connected, and persists the resolved
/// `chipId → side` map in `BandAssignmentStorage`.
class BleManagerState {
  const BleManagerState({
    required this.bands,
    required this.assignments,
    required this.scanning,
    this.error,
  });

  /// Every SportBand-XXXX seen during this session, keyed by chipId.
  final Map<String, BandState> bands;

  /// Persisted side assignments. Null when storage hasn't been loaded yet.
  /// Empty map = first-time pairing (none assigned yet).
  final Map<String, String> assignments;

  final bool scanning;
  final String? error;

  static const BleManagerState initial = BleManagerState(
    bands: <String, BandState>{},
    assignments: <String, String>{},
    scanning: false,
  );

  /// Find the BandState assigned to a specific side, or null when no
  /// band is yet bound to that ankle. Used by `leftBandProvider` /
  /// `rightBandProvider` to derive their per-side BandState.
  BandState? bandForSide(String side) {
    for (final MapEntry<String, String> e in assignments.entries) {
      if (e.value == side) return bands[e.key];
    }
    return null;
  }

  /// chipIds connected but without a side assignment yet — these are the
  /// targets of the shake-to-identify flow. Empty when nothing's pending.
  List<String> get pendingChipIds {
    return bands.entries
        .where((MapEntry<String, BandState> e) =>
            e.value.status == BandStatus.connected &&
            !assignments.containsKey(e.key))
        .map((MapEntry<String, BandState> e) => e.key)
        .toList();
  }

  /// True when both ankles have a band actively connected.
  bool get bothSidesConnected {
    final BandState? l = bandForSide(kLeftAnkle);
    final BandState? r = bandForSide(kRightAnkle);
    return l?.status == BandStatus.connected &&
        r?.status == BandStatus.connected;
  }

  BleManagerState copyWith({
    Map<String, BandState>? bands,
    Map<String, String>? assignments,
    bool? scanning,
    String? error,
    bool clearError = false,
  }) {
    return BleManagerState(
      bands: bands ?? this.bands,
      assignments: assignments ?? this.assignments,
      scanning: scanning ?? this.scanning,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Drives the BLE lifecycle for both ankle bands.
///
/// Lifecycle:
/// 1. On first read of `bleManagerProvider`, `_init` loads any persisted
///    `chipId → side` assignments, requests permissions, waits for the
///    BLE adapter, and starts a service-UUID-filtered scan.
/// 2. Every advertising `SportBand-XXXX` is connected immediately. The
///    side assignment is resolved from the storage map (if known) or
///    left blank (pending identification).
/// 3. When 2 bands are connected without sides, the UI navigates to
///    `IdentifyScreen` which calls `assignSide()` after the user shakes
///    the left band — that persists the chip→side mapping for future
///    sessions.
/// 4. Reconnect on disconnect with 2 s back-off; re-discovers services
///    and re-subscribes to sensor + battery notifications.
class BleManager extends StateNotifier<BleManagerState> {
  BleManager(this._storage) : super(BleManagerState.initial) {
    _init();
  }

  final BandAssignmentStorage _storage;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  StreamSubscription<bool>? _isScanningSub;

  /// One `_BandConnection` per band the user has tapped, keyed by chipId.
  final Map<String, _BandConnection> _conns = <String, _BandConnection>{};

  /// Every `BluetoothDevice` seen during the current scan, keyed by
  /// chipId. Populated as scan results arrive — we don't connect until
  /// the user taps a row in `ScanScreen` and `connectBand` is called.
  final Map<String, BluetoothDevice> _devices =
      <String, BluetoothDevice>{};

  /// Guard against the double-restart that fires when both the
  /// adapter listener and `_init` call `restartScan` on boot.
  bool _restartInProgress = false;

  bool _disposed = false;

  /// Broadcast stream of decoded sensor packets — both bands feed it.
  /// Subscribers (shake detector during pairing, metrics engine in
  /// Sprint 3) attach via `bleManager.sensorDataStream`.
  final StreamController<SensorData> _sensorCtrl =
      StreamController<SensorData>.broadcast();

  Stream<SensorData> get sensorDataStream => _sensorCtrl.stream;

  /// Public accessor used by `_BandConnection` to look up the side label
  /// when parsing incoming sensor packets — `state.assignments` itself is
  /// `@protected` (intended for internal `state =` mutations only).
  Map<String, String> get assignments => state.assignments;

  Future<void> _init() async {
    // Pull persisted side assignments first so scan results immediately
    // resolve to the right side when the user reopens the app.
    final Map<String, String> saved = await _storage.load();
    if (_disposed) return;
    state = state.copyWith(assignments: saved);

    _adapterSub = FlutterBluePlus.adapterState.listen((BluetoothAdapterState s) {
      if (_disposed) return;
      if (s == BluetoothAdapterState.on) {
        if (!state.scanning && _conns.length < 2) {
          restartScan();
        }
      } else {
        state = state.copyWith(error: 'Bluetooth apagado');
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
      ].request();
      final bool scanOk = res[ph.Permission.bluetoothScan]?.isGranted ?? false;
      final bool connOk = res[ph.Permission.bluetoothConnect]?.isGranted ?? false;
      return scanOk && connOk;
    }
    // iOS: do not call `permission_handler.Permission.bluetooth.request()`
    // here — its iOS implementation is unreliable (returns
    // permanentlyDenied even when the user accepts the prompt). We rely
    // on `FlutterBluePlus.adapterState` instead, which `restartScan`
    // checks immediately after this. If iOS hasn't granted bluetooth,
    // the adapter will be `unauthorized`, not `on`, and we'll surface a
    // friendly error there.
    return true;
  }

  /// Full teardown + re-scan: drops every connection, clears the
  /// discovered list and starts a brand-new scan. Used internally by
  /// `_init` and the adapter on-events; **not** wired to REESCANEAR
  /// (that calls `rescan` so connected bands survive).
  ///
  /// Idempotent: callers like `_init` and the adapter listener may both
  /// fire on boot, so we no-op if a scan setup is already running.
  Future<void> restartScan() async {
    if (_disposed) return;
    if (_restartInProgress) {
      debugPrint('[ble] restartScan ignored — already in progress');
      return;
    }
    _restartInProgress = true;
    try {
      debugPrint('[ble] restartScan');

      await _stopScanInternal();

      final List<Future<void>> teardown = <Future<void>>[
        for (final _BandConnection c in _conns.values) c.disconnect(),
      ];
      await Future.wait<void>(teardown);
      _conns.clear();
      _devices.clear();

      state = state.copyWith(
        bands: <String, BandState>{},
        clearError: true,
      );

      await _startScanStream();
    } finally {
      _restartInProgress = false;
    }
  }

  /// Re-run discovery WITHOUT disturbing active connections. Wired to
  /// the "REESCANEAR" button in `scan_screen.dart` — the user wants to
  /// hunt for more bands while keeping whatever they've already
  /// connected (and the persisted side assignments).
  Future<void> rescan() async {
    if (_disposed) return;
    if (_restartInProgress) {
      debugPrint('[ble] rescan ignored — already in progress');
      return;
    }
    _restartInProgress = true;
    try {
      debugPrint('[ble] rescan (keep connections)');

      await _stopScanInternal();

      // Drop discovered-but-not-connected entries so the list refreshes
      // cleanly. Keep connected bands and their cached device handles.
      final Map<String, BandState> nextBands = <String, BandState>{
        for (final MapEntry<String, BandState> e in state.bands.entries)
          if (e.value.status == BandStatus.connected) e.key: e.value,
      };
      _devices.removeWhere(
        (String chipId, BluetoothDevice _) => !nextBands.containsKey(chipId),
      );
      state = state.copyWith(bands: nextBands, clearError: true);

      await _startScanStream();
    } finally {
      _restartInProgress = false;
    }
  }

  /// Shared scan-startup path: permissions, adapter check, subscribe,
  /// and `startScan`. Caller is responsible for any state cleanup
  /// before invocation.
  Future<void> _startScanStream() async {
    if (!await _ensurePermissions()) {
      debugPrint('[ble] permissions denied → aborting scan');
      _setError('Permisos BLE denegados');
      return;
    }

    final BluetoothAdapterState adapter =
        await FlutterBluePlus.adapterState.first;
    debugPrint('[ble] adapter state: $adapter');
    if (adapter != BluetoothAdapterState.on) {
      _setError('Bluetooth apagado');
      return;
    }

    _scanSub = FlutterBluePlus.scanResults.listen(
      _onScanResults,
      onError: (Object e) {
        debugPrint('[ble] scan stream error: $e');
        state = state.copyWith(error: 'Error de escaneo: $e');
      },
    );

    try {
      debugPrint('[ble] startScan(withServices=[$_kServiceUuid])');
      await FlutterBluePlus.startScan(
        withServices: <Guid>[Guid(_kServiceUuid)],
        timeout: const Duration(seconds: 30),
        continuousUpdates: true,
      );
    } on Exception catch (e) {
      debugPrint('[ble] startScan failed: $e');
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
        // not fatal
      }
    }
  }

  void _onScanResults(List<ScanResult> results) {
    if (_disposed) return;

    // Track every SportBand advertiser we see and surface it in
    // `state.bands` with status `found`. New bands stay in `found`
    // waiting for the user to tap them in `ScanScreen` — but bands
    // we already trust (a persisted side assignment exists in
    // `state.assignments`) auto-reconnect immediately, so a returning
    // user lands on Scan / Home with their pair already linked up.
    for (final ScanResult r in results) {
      if (!r.device.advName.startsWith(_kAdvNamePrefix)) continue;
      final String chipId = _chipIdFromAdvName(r.device.advName);
      if (chipId.isEmpty) continue;

      // Cache the BluetoothDevice so `connectBand` can dial it later
      // without needing a second scan to resolve the chipId.
      _devices[chipId] = r.device;

      final BandState? existing = state.bands[chipId];
      if (existing == null) {
        final bool isKnown = state.assignments.containsKey(chipId);
        debugPrint(
            '[ble] discovered chipId=$chipId rssi=${r.rssi} ${isKnown ? "(known → auto-connect)" : ""}');
        _setBand(
          chipId,
          BandState(
            chipId: chipId,
            nodeId: state.assignments[chipId] ?? '',
            name: r.device.advName,
            status: BandStatus.found,
            mac: r.device.remoteId.str,
            rssi: r.rssi,
          ),
        );
        if (isKnown) {
          // ignore: unawaited_futures
          connectBand(chipId);
        }
      } else if (existing.status == BandStatus.found) {
        // Refresh RSSI on subsequent ad packets while the row is still
        // discoverable in the list. Once the user taps and we move to
        // `connecting`/`connected`, leave the value alone.
        _setBand(chipId, existing.copyWith(rssi: r.rssi));
      }
    }

    // Stop scanning once two bands are actually connected — keeps the
    // radio quiet during the rest of the pairing flow. Until then we
    // keep listening so the discovery list stays fresh.
    final int connectedCount = state.bands.values
        .where((BandState b) => b.status == BandStatus.connected)
        .length;
    if (connectedCount >= 2) {
      // ignore: unawaited_futures
      _stopScanInternal();
    }
  }

  static String _chipIdFromAdvName(String advName) {
    if (!advName.startsWith(_kAdvNamePrefix)) return '';
    return advName.substring(_kAdvNamePrefix.length);
  }

  /// Public: connect a band the user has tapped in the discovery list.
  /// `chipId` must be one we've seen in a recent scan result (so
  /// `_devices[chipId]` is set). Idempotent — re-tapping a band already
  /// connecting/connected is a no-op.
  Future<void> connectBand(String chipId) async {
    if (_disposed) return;
    final BluetoothDevice? device = _devices[chipId];
    if (device == null) {
      debugPrint('[ble] connectBand($chipId) ignored — unknown chipId');
      return;
    }
    if (_conns.containsKey(chipId)) {
      debugPrint('[ble] connectBand($chipId) ignored — already connecting');
      return;
    }
    debugPrint('[ble] connectBand($chipId)');
    _setBand(
      chipId,
      _maybeBandFor(chipId).copyWith(status: BandStatus.connecting),
    );
    await _connect(device, chipId);
  }

  /// Public: drop the connection for one band — used when the user
  /// taps a connected row to undo their selection. The row goes back
  /// to `found` so it re-appears in the "Disponibles" list.
  Future<void> disconnectBand(String chipId) async {
    if (_disposed) return;
    debugPrint('[ble] disconnectBand($chipId)');
    final _BandConnection? conn = _conns.remove(chipId);
    if (conn != null) {
      await conn.disconnect();
    }
    final BandState current = _maybeBandFor(chipId);
    _setBand(
      chipId,
      current.copyWith(status: BandStatus.found, clearBattery: true),
    );
  }

  Future<void> _connect(BluetoothDevice device, String chipId) async {
    final _BandConnection conn = _BandConnection(
      device: device,
      chipId: chipId,
      manager: this,
    );
    _conns[chipId] = conn;
    try {
      await conn.connectAndSubscribe();
      debugPrint('[ble] connected chipId=$chipId');
    } on Exception catch (e) {
      debugPrint('[ble] connect failed chipId=$chipId: $e');
      _setBand(chipId, _maybeBandFor(chipId).copyWith(status: BandStatus.error));
      _conns.remove(chipId);
    }
  }

  /// Public: persist the user's choice from the shake-to-identify flow.
  /// `side` must be `LEFT_ANKLE` or `RIGHT_ANKLE` (the constants
  /// re-exported from `band_assignment_storage.dart`). The other band
  /// — if connected — automatically takes the opposite side.
  Future<void> assignSide({
    required String chipId,
    required String side,
  }) async {
    assert(side == kLeftAnkle || side == kRightAnkle);
    debugPrint('[ble] assignSide chipId=$chipId side=$side');

    await _storage.assign(chipId, side);
    final Map<String, String> next = await _storage.load();

    // Apply the new mapping to in-memory band states so consumers see
    // the right `nodeId` immediately.
    final Map<String, BandState> nextBands =
        Map<String, BandState>.from(state.bands);
    for (final MapEntry<String, BandState> e in nextBands.entries.toList()) {
      nextBands[e.key] =
          e.value.copyWith(nodeId: next[e.key] ?? '');
    }

    state = state.copyWith(bands: nextBands, assignments: next);
  }

  /// Public: clear all persisted assignments (e.g. when the user taps
  /// "REESCANEAR" — they want to re-pair from scratch).
  Future<void> clearAssignments() async {
    await _storage.clear();
    final Map<String, BandState> nextBands = <String, BandState>{
      for (final MapEntry<String, BandState> e in state.bands.entries)
        e.key: e.value.copyWith(nodeId: ''),
    };
    state = state.copyWith(
      bands: nextBands,
      assignments: <String, String>{},
    );
  }

  void _setError(String msg) {
    final Map<String, BandState> errored = <String, BandState>{
      for (final MapEntry<String, BandState> e in state.bands.entries)
        e.key: e.value.copyWith(status: BandStatus.error),
    };
    state = state.copyWith(error: msg, bands: errored);
  }

  BandState _maybeBandFor(String chipId) {
    return state.bands[chipId] ??
        BandState(
          chipId: chipId,
          nodeId: state.assignments[chipId] ?? '',
          name: '$_kAdvNamePrefix$chipId',
          status: BandStatus.searching,
        );
  }

  void _setBand(String chipId, BandState next) {
    if (_disposed) return;
    final Map<String, BandState> nextBands =
        Map<String, BandState>.from(state.bands);
    nextBands[chipId] = next.copyWith(
      nodeId: state.assignments[chipId] ?? next.nodeId,
    );
    state = state.copyWith(bands: nextBands);
  }

  void _patchBand(
    String chipId, {
    BandStatus? status,
    int? rssi,
    int? battery,
    bool clearBattery = false,
  }) {
    final BandState current = _maybeBandFor(chipId);
    _setBand(
      chipId,
      current.copyWith(
        status: status,
        rssi: rssi,
        battery: battery,
        clearBattery: clearBattery,
      ),
    );
  }

  void _emit(SensorData data) {
    if (_disposed || _sensorCtrl.isClosed) return;
    _sensorCtrl.add(data);
  }

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
    await _sensorCtrl.close();
  }

  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
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

/// Per-band connection holder. Keyed by chipId now (not nodeId), so it
/// works for bands that haven't been assigned a side yet.
class _BandConnection {
  _BandConnection({
    required this.device,
    required this.chipId,
    required this.manager,
  });

  final BluetoothDevice device;
  final String chipId;
  final BleManager manager;

  StreamSubscription<BluetoothConnectionState>? _stateSub;
  StreamSubscription<List<int>>? _sensorSub;
  StreamSubscription<List<int>>? _batterySub;

  bool _disposing = false;

  /// True once `device.connect()` has succeeded at least once for this
  /// `_BandConnection`. Used to ignore the very first
  /// `BluetoothConnectionState.disconnected` emission — that one is just
  /// `connectionState.listen` reporting the *current* state right after
  /// subscribe, not a real disconnect event.
  bool _everConnected = false;

  Future<void> connectAndSubscribe() async {
    _stateSub ??= device.connectionState.listen(_onConnectionState);

    await device.connect(
      timeout: const Duration(seconds: 10),
      autoConnect: false,
    );

    if (Platform.isAndroid) {
      try {
        await device.requestMtu(247);
      } on Exception {
        // some Android stacks reject — fall back to default MTU.
      }
    }

    await _discoverAndSubscribe();
    _everConnected = true;
    manager._patchBand(chipId, status: BandStatus.connected);
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
            final String side = manager.assignments[chipId] ?? '';
            final SensorData? data =
                SensorParser.parse(bytes, chipId, side);
            if (data != null) manager._emit(data);
          });
        } else if (c.uuid == Guid(_kBatteryUuid)) {
          try {
            final List<int> v = await c.read();
            if (v.isNotEmpty) {
              manager._patchBand(chipId, battery: v[0]);
            }
          } on Exception {
            // ignore — keep going.
          }
          if (c.properties.notify) {
            await c.setNotifyValue(true);
            _batterySub = c.lastValueStream.listen((List<int> bytes) {
              if (bytes.isNotEmpty) {
                manager._patchBand(chipId, battery: bytes[0]);
              }
            });
          }
        }
      }
    }
  }

  void _onConnectionState(BluetoothConnectionState s) {
    if (_disposing) return;

    if (s == BluetoothConnectionState.connected) {
      _everConnected = true;
      return;
    }

    if (s != BluetoothConnectionState.disconnected) return;

    // Ignore the synthetic "disconnected" the stream emits on subscribe
    // — that's just the current state being replayed before our own
    // `device.connect()` has had a chance to run. Only react to real
    // drops that happen after we've been connected at least once.
    if (!_everConnected) return;

    debugPrint('[ble] disconnect detected chipId=$chipId — scheduling reconnect');
    manager._patchBand(
      chipId,
      status: BandStatus.error,
      clearBattery: true,
    );

    Future<void>.delayed(const Duration(seconds: 2), () async {
      if (_disposing) return;
      try {
        manager._patchBand(chipId, status: BandStatus.connecting);
        await device.connect(
          timeout: const Duration(seconds: 10),
          autoConnect: false,
        );
        await _discoverAndSubscribe();
        manager._patchBand(chipId, status: BandStatus.connected);
      } on Exception {
        manager._patchBand(chipId, status: BandStatus.error);
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
      // already disconnected — fine.
    }
  }
}

/// Singleton-per-app BleManager. Non-autoDispose so connections persist
/// across screen transitions (scan → identify → home → dashboard).
final StateNotifierProvider<BleManager, BleManagerState> bleManagerProvider =
    StateNotifierProvider<BleManager, BleManagerState>((Ref ref) {
  final BandAssignmentStorage storage =
      ref.watch(bandAssignmentStorageProvider);
  final BleManager m = BleManager(storage);
  ref.onDispose(() {
    // ignore: unawaited_futures
    m.disposeAsync();
  });
  return m;
});

/// Decoded sensor data stream — used by the shake detector during
/// pairing and (in Sprint 3) by the metrics engine.
final Provider<Stream<SensorData>> sensorDataStreamProvider =
    Provider<Stream<SensorData>>((Ref ref) {
  return ref.watch(bleManagerProvider.notifier).sensorDataStream;
});

/// True iff there are bands connected without a side assignment yet —
/// drives the navigation from Scan to IdentifyScreen.
final Provider<bool> needsIdentificationProvider = Provider<bool>((Ref ref) {
  return ref.watch(bleManagerProvider).pendingChipIds.isNotEmpty;
});
