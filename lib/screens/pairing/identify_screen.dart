import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/band_assignment_storage.dart';
import '../../services/ble_manager.dart';
import '../../services/shake_detector.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text.dart';
import 'paired_success_screen.dart';

/// Step 3 of the pairing flow. Both bands are connected; we ask the
/// user to shake the LEFT one for 2 seconds. The `ShakeDetector` listens
/// to `bleManager.sensorDataStream` and reports which `chipId` had the
/// highest peak. We persist the resulting `chipId → side` mapping via
/// `bleManager.assignSide()`, then advance to `PairedSuccessScreen`.
class IdentifyScreen extends ConsumerStatefulWidget {
  const IdentifyScreen({super.key});

  @override
  ConsumerState<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends ConsumerState<IdentifyScreen> {
  static const double _statusBarReserve = 56;
  static const double _titleToBody = 10;

  /// One of:
  ///  - `idle`     : waiting for user to shake.
  ///  - `running`  : detector active, listening for movement.
  ///  - `success`  : winning chipId resolved (transitioning out).
  ///  - `ambiguous`: detector returned null — user shook both / nothing
  ///                 above threshold. Shows retry CTA.
  _Phase _phase = _Phase.idle;

  String? _lastError;

  @override
  void initState() {
    super.initState();
    // Auto-arm the detector as soon as the screen mounts. The user has
    // already read the instructions on Scan and on this screen, so we
    // don't want them to tap a button before being able to shake.
    WidgetsBinding.instance.addPostFrameCallback((_) => _runDetector());
  }

  Future<void> _runDetector() async {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.running;
      _lastError = null;
    });

    final ShakeDetector detector = ShakeDetector(
      sensorStream: ref.read(sensorDataStreamProvider),
    );
    final ShakeResult result = await detector.detect();
    if (!mounted) return;

    if (result.isAmbiguous) {
      setState(() {
        _phase = _Phase.ambiguous;
        _lastError = 'No pude distinguir cuál banda agitaste. Intenta otra vez.';
      });
      return;
    }

    final String winner = result.winnerChipId!;
    debugPrint('[identify] winner=$winner peaks=${result.peaks}');

    // Persist & propagate.
    await ref
        .read(bleManagerProvider.notifier)
        .assignSide(chipId: winner, side: kLeftAnkle);
    // The other connected band — if any — automatically becomes RIGHT
    // via the storage's "flip the other side" rule.
    final List<String> connected = ref
        .read(bleManagerProvider)
        .bands
        .keys
        .where((String id) => id != winner)
        .toList();
    if (connected.isNotEmpty) {
      await ref
          .read(bleManagerProvider.notifier)
          .assignSide(chipId: connected.first, side: kRightAnkle);
    }

    if (!mounted) return;
    setState(() => _phase = _Phase.success);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const PairedSuccessScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: <Widget>[
          const SizedBox(height: _statusBarReserve),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(S.s6, S.s7, S.s6, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Identifica tu banda izquierda',
                    style: AppText.title2,
                  ),
                  const SizedBox(height: _titleToBody),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(
                      'Agita la banda de tu tobillo IZQUIERDO durante 2 '
                      'segundos. Sólo esa.',
                      style: AppText.body.copyWith(color: AppColors.text2),
                    ),
                  ),
                  const SizedBox(height: S.s8),
                  const Center(child: _PulseAnimation()),
                  const SizedBox(height: S.s5),
                  Center(child: _StatusLine(phase: _phase, error: _lastError)),
                ],
              ),
            ),
          ),
          if (_phase == _Phase.ambiguous)
            Padding(
              padding: const EdgeInsets.fromLTRB(S.s6, S.s5, S.s6, S.s8),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _runDetector,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(R.lg),
                  ),
                  child: Text(
                    'INTENTAR DE NUEVO',
                    style: AppText.caption.copyWith(color: AppColors.accent),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _Phase { idle, running, success, ambiguous }

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.phase, required this.error});

  final _Phase phase;
  final String? error;

  @override
  Widget build(BuildContext context) {
    switch (phase) {
      case _Phase.idle:
      case _Phase.running:
        return Text('Esperando…',
            style: AppText.monoReadout.copyWith(color: AppColors.text3));
      case _Phase.success:
        return Text('¡Detectada!',
            style: AppText.monoReadout.copyWith(color: AppColors.ok));
      case _Phase.ambiguous:
        return Text(error ?? 'No detectada',
            style: AppText.bodySm.copyWith(color: AppColors.crit));
    }
  }
}

/// Three concentric circles expanding outward in a staggered loop —
/// signals "active listening" without any text-equivalent UX cost.
class _PulseAnimation extends StatefulWidget {
  const _PulseAnimation();

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) =>
            CustomPaint(painter: _PulsePainter(progress: _controller.value)),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  const _PulsePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    const double maxRadius = 90;
    const double minRadius = 28;

    // Three rings, evenly spaced in phase.
    for (int i = 0; i < 3; i++) {
      final double t = (progress + i / 3.0) % 1.0;
      final double radius = minRadius + (maxRadius - minRadius) * t;
      final double alpha = (1.0 - t).clamp(0.0, 1.0);
      final Paint ring = Paint()
        ..color = AppColors.accent.withValues(alpha: alpha * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius, ring);
    }

    // Solid core.
    canvas.drawCircle(
      center,
      minRadius,
      Paint()..color = AppColors.accent,
    );
    canvas.drawCircle(
      center,
      minRadius - 4,
      Paint()..color = AppColors.bg,
    );
    canvas.drawCircle(
      center,
      minRadius - 10,
      Paint()..color = AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
