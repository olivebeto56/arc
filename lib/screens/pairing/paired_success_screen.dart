import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/band_state.dart';
import '../../providers/band_providers.dart';
import '../../services/band_assignment_storage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text.dart';
import '../../widgets/battery_reading.dart';
import '../home_screen.dart';

/// Confirmation screen after the shake-to-identify flow. Shows both
/// bands with their resolved L/R labels + batteries, plays a brief
/// "tick" check animation, then auto-navigates to the Home screen
/// after 2 seconds.
///
/// Shown only after a fresh pairing — re-pair flows skip this and go
/// straight to Home (per the user's UX choice).
class PairedSuccessScreen extends ConsumerStatefulWidget {
  const PairedSuccessScreen({super.key});

  @override
  ConsumerState<PairedSuccessScreen> createState() =>
      _PairedSuccessScreenState();
}

class _PairedSuccessScreenState extends ConsumerState<PairedSuccessScreen>
    with SingleTickerProviderStateMixin {
  static const double _statusBarReserve = 56;
  static const Duration _autoNavDelay = Duration(milliseconds: 2000);

  late final AnimationController _checkController;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    // Mark onboarding as completed so subsequent launches skip
    // HowToWear when permissions are revoked + re-granted.
    final BandAssignmentStorage storage =
        ref.read(bandAssignmentStorageProvider);
    // ignore: unawaited_futures
    storage.markOnboardingCompleted();

    _navTimer = Timer(_autoNavDelay, _goHome);
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _checkController.dispose();
    super.dispose();
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BandState left = ref.watch(leftBandProvider);
    final BandState right = ref.watch(rightBandProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: <Widget>[
          const SizedBox(height: _statusBarReserve),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _CheckMark(controller: _checkController),
                const SizedBox(height: S.s7),
                const Text(
                  '¡Bandas conectadas!',
                  style: AppText.title2,
                ),
                const SizedBox(height: S.s2),
                Text(
                  'Listas para tu sesión',
                  style: AppText.body.copyWith(color: AppColors.text2),
                ),
                const SizedBox(height: S.s8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: S.s6),
                  child: Row(
                    children: <Widget>[
                      Expanded(child: _BandSummary(state: left, side: 'L')),
                      const SizedBox(width: S.s4),
                      Expanded(child: _BandSummary(state: right, side: 'R')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BandSummary extends StatelessWidget {
  const _BandSummary({required this.state, required this.side});

  final BandState state;
  final String side;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(S.s4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.accent),
        borderRadius: BorderRadius.circular(R.lg),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.accentDim,
            blurRadius: 0,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceHi,
              border: Border.all(color: AppColors.border),
              shape: BoxShape.circle,
            ),
            child: Text(
              side,
              style: AppText.bodySm.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: S.s3),
          Text(
            state.name,
            style: AppText.bodySm.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: S.s2),
          if (state.battery != null)
            BatteryReading(pct: state.battery!)
          else
            Text('—',
                style: AppText.bodyXs.copyWith(color: AppColors.text3)),
        ],
      ),
    );
  }
}

/// Check-mark drawn from scratch in CustomPaint with an animated
/// stroke — no asset dependency, plays a clean entrance.
class _CheckMark extends StatelessWidget {
  const _CheckMark({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, _) =>
            CustomPaint(painter: _CheckPainter(progress: controller.value)),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2 - 4;

    // Outer ring with a subtle accent glow.
    canvas.drawCircle(
      center,
      radius + 2,
      Paint()..color = AppColors.accentDim,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = AppColors.accent,
    );

    // Animated check stroke.
    final Path checkPath = Path()
      ..moveTo(center.dx - 18, center.dy + 2)
      ..lineTo(center.dx - 4, center.dy + 16)
      ..lineTo(center.dx + 22, center.dy - 14);

    final ui.PathMetrics metrics = checkPath.computeMetrics();
    final Path animated = Path();
    for (final ui.PathMetric pm in metrics) {
      animated.addPath(
        pm.extractPath(0, pm.length * progress),
        Offset.zero,
      );
    }

    canvas.drawPath(
      animated,
      Paint()
        ..color = AppColors.bg
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
