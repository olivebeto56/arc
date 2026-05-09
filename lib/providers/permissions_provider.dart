import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_blue_plus/flutter_blue_plus.dart'
    show BluetoothAdapterState, FlutterBluePlus;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart' as ph;

/// Tri-state model surfaced to the UI. Drives the badge label/colour in
/// `PermissionCard` and the enable state of the "CONTINUAR" CTA.
///
///  - `pending`  — never asked. Tap shows the native OS prompt.
///  - `granted`  — accepted. Tap is a no-op.
///  - `denied`   — previously rejected. Tap opens the app's Settings page.
enum PermissionStatus { granted, pending, denied }

// ─── Bluetooth ───────────────────────────────────────────────────

/// Bluetooth permission notifier.
///
///  - **iOS**: subscribes to `flutter_blue_plus.adapterState` in the
///    constructor. The subscription is what creates `CBCentralManager`
///    on iOS — and that's the only Apple-sanctioned path to read the
///    real `CBManager.authorization`. On a fresh install this triggers
///    the system permission prompt (expected when entering the Permisos
///    screen). On subsequent launches the manager comes up already
///    authorized and emits `.poweredOn` immediately, so the badge shows
///    the right value without the user having to tap.
///
///    `permission_handler.Permission.bluetooth` is intentionally avoided
///    on iOS — its 11.x implementation has a documented bug returning
///    `permanentlyDenied` even when the user accepts the prompt. See
///    https://github.com/Baseflow/flutter-permission-handler/issues/1333
///
///  - **Android 12+**: uses `permission_handler` with `BLUETOOTH_SCAN` +
///    `BLUETOOTH_CONNECT` (the canonical Google-recommended pair).
class BluetoothPermissionNotifier extends StateNotifier<PermissionStatus> {
  BluetoothPermissionNotifier() : super(PermissionStatus.pending) {
    if (Platform.isIOS) {
      // Eager subscribe — the listener IS our source of truth on iOS.
      _adapterSub = FlutterBluePlus.adapterState.listen(_onIosAdapter);
    } else {
      refresh();
    }
  }

  StreamSubscription<BluetoothAdapterState>? _adapterSub;

  /// Sticky cache of the last result from `.request()`. Used on Android
  /// to disambiguate a plain `denied` (could be "never asked" or "asked
  /// once and rejected") on subsequent refreshes.
  final Map<ph.Permission, ph.PermissionStatus> _lastKnown =
      <ph.Permission, ph.PermissionStatus>{};

  static List<ph.Permission> get _androidPermissions => <ph.Permission>[
        ph.Permission.bluetoothScan,
        ph.Permission.bluetoothConnect,
      ];

  Future<void> refresh() async {
    if (Platform.isIOS) {
      // The adapter listener keeps `state` accurate continuously — no
      // refresh work needed.
      debugPrint('[perm] BT refresh → $state (iOS, listener-driven)');
      return;
    }
    try {
      final List<ph.PermissionStatus> live = <ph.PermissionStatus>[
        for (final ph.Permission p in _androidPermissions) await p.status,
      ];
      state = await _resolveAndroid(live);
      debugPrint('[perm] BT refresh → $state');
    } on Object catch (e, st) {
      debugPrint('[perm] BT refresh error: $e\n$st');
    }
  }

  Future<void> request() async {
    debugPrint('[perm] BT request current: $state');
    try {
      switch (state) {
        case PermissionStatus.granted:
          return;
        case PermissionStatus.denied:
          await ph.openAppSettings();
          return;
        case PermissionStatus.pending:
          if (Platform.isIOS) {
            // Listener was started in the constructor. If the user tapped
            // before iOS finished initializing the manager, force a
            // snapshot read to coax the next emission.
            try {
              await FlutterBluePlus.adapterState.first
                  .timeout(const Duration(seconds: 5));
            } on TimeoutException {
              // OK — listener will emit when it can.
            } on Object catch (e) {
              debugPrint('[perm] iOS BT bootstrap: $e');
            }
            return;
          }
          // Android.
          final Map<ph.Permission, ph.PermissionStatus> res =
              await _androidPermissions.request();
          debugPrint('[perm] BT request result: $res');
          _lastKnown.addAll(res);
          state = _aggregatePostRequest(res.values.toList());
      }
    } on Object catch (e, st) {
      debugPrint('[perm] BT request error: $e\n$st');
    }
  }

  /// `flutter_blue_plus` adapter state → our tri-state. iOS reports the
  /// real `CBManager.authorization` via this stream:
  ///   `unauthorized` → user has denied the permission.
  ///   `on/off/turning*` → permission is granted (BT may or may not be on).
  ///   `unknown` → not determined yet — wait for the next emission.
  ///   `unavailable` → device doesn't support BLE; treat as denied.
  void _onIosAdapter(BluetoothAdapterState s) {
    debugPrint('[perm] iOS BT adapter → $s');
    PermissionStatus? newState;
    switch (s) {
      case BluetoothAdapterState.unauthorized:
        newState = PermissionStatus.denied;
      case BluetoothAdapterState.on:
      case BluetoothAdapterState.off:
      case BluetoothAdapterState.turningOn:
      case BluetoothAdapterState.turningOff:
        newState = PermissionStatus.granted;
      case BluetoothAdapterState.unknown:
        // Wait — no definitive info yet.
        break;
      case BluetoothAdapterState.unavailable:
        newState = PermissionStatus.denied;
    }
    if (newState != null && newState != state) {
      state = newState;
    }
  }

  /// Reduce the per-permission live status reads on Android to our
  /// tri-state. Uses `_lastKnown` as override and `shouldShowRationale`
  /// to disambiguate "never asked" from "asked and rejected".
  Future<PermissionStatus> _resolveAndroid(
    List<ph.PermissionStatus> live,
  ) async {
    bool allGranted = true;
    bool anyHardDenied = false;
    bool anyAmbiguous = false;
    for (int i = 0; i < live.length; i++) {
      final ph.Permission p = _androidPermissions[i];
      final ph.PermissionStatus s = _lastKnown[p] ?? live[i];
      if (s.isGranted || s.isLimited || s.isProvisional) continue;
      allGranted = false;
      if (s.isPermanentlyDenied || s.isRestricted) {
        anyHardDenied = true;
      } else if (s.isDenied) {
        anyAmbiguous = true;
      }
    }
    if (allGranted) return PermissionStatus.granted;
    if (anyHardDenied) return PermissionStatus.denied;
    if (anyAmbiguous) {
      bool everRejected = false;
      for (final ph.Permission p in _androidPermissions) {
        if (_lastKnown.containsKey(p)) {
          everRejected = true;
          break;
        }
        if (await p.shouldShowRequestRationale) {
          everRejected = true;
          break;
        }
      }
      return everRejected ? PermissionStatus.denied : PermissionStatus.pending;
    }
    return PermissionStatus.pending;
  }

  /// Reduce the result of a `.request()` call. Post-request, anything
  /// other than granted is a real user-denial — we never surface
  /// `pending` here.
  PermissionStatus _aggregatePostRequest(List<ph.PermissionStatus> statuses) {
    if (statuses.isEmpty) return PermissionStatus.granted;
    if (statuses.every(
      (ph.PermissionStatus s) =>
          s.isGranted || s.isLimited || s.isProvisional,
    )) {
      return PermissionStatus.granted;
    }
    return PermissionStatus.denied;
  }

  @override
  void dispose() {
    _adapterSub?.cancel();
    super.dispose();
  }
}

// ─── Location ────────────────────────────────────────────────────

/// Location permission notifier — uses `geolocator` (CLLocationManager /
/// FusedLocationProviderClient) instead of `permission_handler`. Even
/// Baseflow (the maintainers of both plugins) recommend `geolocator` for
/// location since the two have known divergence on iOS.
/// See https://github.com/Baseflow/flutter-permission-handler/issues/1391
class LocationPermissionNotifier extends StateNotifier<PermissionStatus> {
  LocationPermissionNotifier() : super(PermissionStatus.pending) {
    refresh();
  }

  /// True once we've called `requestPermission()` at least once in this
  /// session. Disambiguates `denied` (never asked) from `denied` (asked
  /// and rejected) on iOS, where there is no "rationale" API.
  bool _hasRequestedThisSession = false;

  Future<void> refresh() async {
    try {
      final geo.LocationPermission p = await geo.Geolocator.checkPermission();
      state = _map(p);
      debugPrint('[perm] location refresh → $p → $state');
    } on Object catch (e, st) {
      debugPrint('[perm] location refresh error: $e\n$st');
    }
  }

  Future<void> request() async {
    debugPrint('[perm] location request current: $state');
    try {
      final geo.LocationPermission current =
          await geo.Geolocator.checkPermission();

      switch (current) {
        case geo.LocationPermission.always:
        case geo.LocationPermission.whileInUse:
          state = PermissionStatus.granted;
          return;
        case geo.LocationPermission.deniedForever:
          await geo.Geolocator.openAppSettings();
          return;
        case geo.LocationPermission.denied:
        case geo.LocationPermission.unableToDetermine:
          if (_hasRequestedThisSession) {
            // We already asked once this session and the user said no —
            // the OS won't show the prompt again, so jump to Settings.
            await geo.Geolocator.openAppSettings();
            return;
          }
          _hasRequestedThisSession = true;
          final geo.LocationPermission result =
              await geo.Geolocator.requestPermission();
          debugPrint('[perm] location request result: $result');
          state = _map(result);
      }
    } on Object catch (e, st) {
      debugPrint('[perm] location request error: $e\n$st');
    }
  }

  PermissionStatus _map(geo.LocationPermission p) {
    switch (p) {
      case geo.LocationPermission.always:
      case geo.LocationPermission.whileInUse:
        return PermissionStatus.granted;
      case geo.LocationPermission.deniedForever:
        return PermissionStatus.denied;
      case geo.LocationPermission.denied:
      case geo.LocationPermission.unableToDetermine:
        return _hasRequestedThisSession
            ? PermissionStatus.denied
            : PermissionStatus.pending;
    }
  }
}

// ─── Splash one-shot check ──────────────────────────────────────

/// Lets the splash screen skip Permisos when the OS already remembers a
/// grant from a previous session.
///
/// On iOS we read the live adapter state via `flutter_blue_plus` rather
/// than `Permission.bluetooth.status` — the latter has documented bugs
/// returning wrong values even post-grant, which would keep routing the
/// user back to Permisos forever. `FlutterBluePlus.adapterState`
/// internally calls `CBManager.authorization` (the same Apple API) but
/// goes through Apple's own delegate path, which is the reliable one.
///
/// Trade-off: on the very first install, this read creates
/// `CBCentralManager` during splash and so iOS will show the Bluetooth
/// permission prompt then. The user transitions to the Permisos screen
/// while the prompt is on top — Permisos catches the eventual
/// authorization via its own listener, so the UX still resolves cleanly.
Future<bool> arePermissionsAlreadyGranted() async {
  // Bluetooth.
  bool btGranted = false;
  if (Platform.isIOS) {
    try {
      // CBCentralManager always emits `.unknown` first while it boots.
      // Skip past that and wait for the first definitive state (`.on`,
      // `.off`, `.unauthorized`, …). On a subsequent launch with the
      // permission already granted this resolves in ~10–100 ms; on a
      // fresh install it sits in `.unknown` until the user responds to
      // the system prompt — the timeout breaks us out and we route to
      // Permisos either way.
      final BluetoothAdapterState s = await FlutterBluePlus.adapterState
          .firstWhere(
            (BluetoothAdapterState s) => s != BluetoothAdapterState.unknown,
          )
          .timeout(const Duration(seconds: 2));
      btGranted = s == BluetoothAdapterState.on ||
          s == BluetoothAdapterState.off ||
          s == BluetoothAdapterState.turningOn ||
          s == BluetoothAdapterState.turningOff;
      debugPrint(
          '[perm] splash iOS BT adapter → $s → granted=$btGranted');
    } on Object catch (e) {
      debugPrint('[perm] splash iOS BT timeout/error: $e');
      btGranted = false;
    }
  } else {
    btGranted = true;
    for (final ph.Permission p in <ph.Permission>[
      ph.Permission.bluetoothScan,
      ph.Permission.bluetoothConnect,
    ]) {
      final ph.PermissionStatus s = await p.status;
      if (!(s.isGranted || s.isLimited || s.isProvisional)) {
        btGranted = false;
        break;
      }
    }
    debugPrint('[perm] splash Android BT → granted=$btGranted');
  }
  if (!btGranted) return false;

  // Location.
  final geo.LocationPermission lp = await geo.Geolocator.checkPermission();
  final bool locGranted = lp == geo.LocationPermission.always ||
      lp == geo.LocationPermission.whileInUse;
  debugPrint('[perm] splash location → $lp → granted=$locGranted');
  return locGranted;
}

// ─── Providers ──────────────────────────────────────────────────

final StateNotifierProvider<BluetoothPermissionNotifier, PermissionStatus>
    bluetoothPermissionProvider =
    StateNotifierProvider<BluetoothPermissionNotifier, PermissionStatus>(
  (Ref ref) => BluetoothPermissionNotifier(),
);

final StateNotifierProvider<LocationPermissionNotifier, PermissionStatus>
    locationPermissionProvider =
    StateNotifierProvider<LocationPermissionNotifier, PermissionStatus>(
  (Ref ref) => LocationPermissionNotifier(),
);

/// True once both permission families are `granted`. Drives the CTA.
final Provider<bool> allPermissionsGrantedProvider = Provider<bool>((Ref ref) {
  return ref.watch(bluetoothPermissionProvider) == PermissionStatus.granted &&
      ref.watch(locationPermissionProvider) == PermissionStatus.granted;
});
