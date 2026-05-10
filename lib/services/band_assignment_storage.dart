import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-side identifiers — match `ble_manager.dart`. The firmware does not
/// know its own side; the app is the source of truth.
const String kLeftAnkle = 'LEFT_ANKLE';
const String kRightAnkle = 'RIGHT_ANKLE';

/// Persists the `chipId → side` map produced by the shake-to-identify
/// flow on the Permisos onboarding. Once a band has been assigned, the
/// next launch reconnects it to the same ankle silently.
///
/// Storage layout:
///   key   = `band_assignments_v1`
///   value = JSON object `{"ABCD": "LEFT_ANKLE", "EF12": "RIGHT_ANKLE"}`
///
/// Versioned by suffix so we can change the shape post-MVP without
/// stomping on existing installs (e.g., adding battery-low timestamps,
/// adding sport-specific overrides).
class BandAssignmentStorage {
  BandAssignmentStorage();

  static const String _kAssignmentsKey = 'band_assignments_v1';
  static const String _kOnboardingKey = 'onboarding_completed_v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<Map<String, String>> load() async {
    final SharedPreferences prefs = await _getPrefs();
    final String? raw = prefs.getString(_kAssignmentsKey);
    if (raw == null || raw.isEmpty) return <String, String>{};
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, String>{};
      final Map<String, String> result = <String, String>{
        for (final MapEntry<dynamic, dynamic> e in decoded.entries)
          if (e.key is String && e.value is String)
            e.key as String: e.value as String,
      };
      debugPrint('[storage] loaded $result');
      return result;
    } on Object catch (e) {
      debugPrint('[storage] load error: $e — returning empty map');
      return <String, String>{};
    }
  }

  /// Replace the whole map. Use when persisting a fresh pairing result.
  Future<void> save(Map<String, String> assignments) async {
    final SharedPreferences prefs = await _getPrefs();
    await prefs.setString(_kAssignmentsKey, jsonEncode(assignments));
    debugPrint('[storage] saved $assignments');
  }

  /// Add or update a single chipId → side mapping while preserving the rest.
  /// If `side` is the same as another chipId already in the map, that other
  /// chipId is *flipped* to the opposite side automatically — the only
  /// valid post-shake state is "exactly one band per side".
  Future<void> assign(String chipId, String side) async {
    assert(side == kLeftAnkle || side == kRightAnkle,
        'side must be LEFT_ANKLE or RIGHT_ANKLE, got "$side"');
    final Map<String, String> current = await load();
    final String otherSide = side == kLeftAnkle ? kRightAnkle : kLeftAnkle;
    final Map<String, String> next = <String, String>{
      for (final MapEntry<String, String> e in current.entries)
        if (e.key != chipId) e.key: e.value == side ? otherSide : e.value,
      chipId: side,
    };
    await save(next);
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await _getPrefs();
    await prefs.remove(_kAssignmentsKey);
    await prefs.remove(_kOnboardingKey);
    debugPrint('[storage] cleared');
  }

  /// Set/read a flag indicating the user has completed the first-time
  /// pairing onboarding (HowToWear + Scan + Identify + PairedSuccess).
  /// On subsequent launches this lets us skip HowToWear when going back
  /// through Permisos after a permission revoke.
  Future<bool> isOnboardingCompleted() async {
    final SharedPreferences prefs = await _getPrefs();
    return prefs.getBool(_kOnboardingKey) ?? false;
  }

  Future<void> markOnboardingCompleted() async {
    final SharedPreferences prefs = await _getPrefs();
    await prefs.setBool(_kOnboardingKey, true);
  }
}

/// Singleton — one storage instance per app, shared between BleManager
/// and any screen that needs to consult/mutate the assignment map.
final Provider<BandAssignmentStorage> bandAssignmentStorageProvider =
    Provider<BandAssignmentStorage>((Ref ref) => BandAssignmentStorage());
