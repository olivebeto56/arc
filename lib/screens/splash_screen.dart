// from: design/design_handoff_arc_app/design/screens/screens-onboarding.jsx
//        (ScreenSplash)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/permissions_provider.dart';
import '../services/band_assignment_storage.dart';
import '../services/ble_manager.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../widgets/arc_logo.dart';
import '../widgets/loading_bar.dart';
import 'home_screen.dart';
import 'permisos_screen.dart';
import 'scan_screen.dart';

/// Splash screen shown for ~1500 ms while BLE / GPS subsystems initialize.
///
/// Routing logic after the splash duration:
///  - Permisos missing                    → PermisosScreen
///  - Permisos OK + 2 bands persisted     → HomeScreen (BleManager
///                                           reconnects in background)
///  - Permisos OK + first-time pairing    → ScanScreen
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const Duration _splashDuration = Duration(milliseconds: 1500);

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(_splashDuration, _goNext);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  Future<void> _goNext() async {
    if (!mounted) return;
    final bool permsGranted = await arePermissionsAlreadyGranted();
    if (!mounted) return;

    if (!permsGranted) {
      _push(const PermisosScreen());
      return;
    }

    final BandAssignmentStorage storage =
        ref.read(bandAssignmentStorageProvider);
    final Map<String, String> assignments = await storage.load();
    if (!mounted) return;

    if (assignments.length >= 2) {
      // Pre-warm BleManager so it starts scanning + reconnecting before
      // the user even reaches the Home screen. The BandsCard reflects
      // the connection state in real time once the manager catches up.
      ref.read(bleManagerProvider);
      _push(const HomeScreen());
      return;
    }

    _push(const ScanScreen());
  }

  void _push(Widget destination) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: <Widget>[
          // Center logo + tagline (gap: 32 → S.s7).
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ARCLogo(height: 56),
                SizedBox(height: S.s7),
                Text(
                  'TU TÉCNICA, EN TIEMPO REAL',
                  style: AppText.caption,
                ),
              ],
            ),
          ),

          // Loading bar — bottom 100 px.
          Positioned(
            left: 0,
            right: 0,
            bottom: 100,
            child: Center(child: LoadingBar()),
          ),

          // Version readout — bottom 50 px.
          Positioned(
            left: 0,
            right: 0,
            bottom: 50,
            child: Center(
              child: Text(
                'v1.0.0 · build 247',
                style: AppText.monoTiny,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
