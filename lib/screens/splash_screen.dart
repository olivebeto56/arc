// from: design/design_handoff_arc_app/design/screens/screens-onboarding.jsx
//        (ScreenSplash)

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../widgets/arc_logo.dart';
import '../widgets/loading_bar.dart';
import 'permisos_screen.dart';

/// Splash screen shown for ~1500 ms while BLE / GPS subsystems initialize.
///
/// Layout per JSX:
///  - Centered cluster: ARCLogo(height: 56) + tagline (caption style), gap 32
///  - Absolute bottom 100 px: LoadingBar (32 x 1, cyan dot moving L→R)
///  - Absolute bottom 50 px:  mono version readout
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const PermisosScreen(),
      ),
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

