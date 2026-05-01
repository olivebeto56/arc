// from: design/design_handoff_arc_app/design/screens/screens-onboarding.jsx
//        (NodeCard inside ScreenScan)

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../models/band_state.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/battery_reading.dart';
import '../../../widgets/dot.dart';

/// Single band row card. Shows the band name, MAC, signal strength and the
/// progression status (searching / found / connected / error).
///
/// All sizing literals come from the JSX `NodeCard` component:
///  - card padding 16 (`S.s4`), radius 14 (`R.lg`)
///  - top row marginBottom 14 (between-scale)
///  - side circle 36×36, fully circular
///  - status indicator 14×14 (spinner) or 8 (dot)
class BandCard extends StatelessWidget {
  const BandCard({
    super.key,
    required this.state,
    required this.sideLabel,
  });

  final BandState state;
  final String sideLabel;

  // JSX literal — between-scale.
  static const double _topRowGap = 14;
  static const double _sideToNameGap = 10;
  static const double _sideCircleSize = 36;

  Color get _borderColor =>
      state.status == BandStatus.connected ? AppColors.accent : AppColors.border;

  List<BoxShadow>? get _connectedRing => state.status == BandStatus.connected
      ? const <BoxShadow>[
          BoxShadow(
            color: AppColors.accentDim,
            blurRadius: 0,
            spreadRadius: 3,
          ),
        ]
      : null;

  Color get _statusColor {
    switch (state.status) {
      case BandStatus.connected:
        return AppColors.ok;
      case BandStatus.searching:
      case BandStatus.found:
        return AppColors.accent;
      case BandStatus.error:
        return AppColors.crit;
    }
  }

  String get _statusLabel {
    switch (state.status) {
      case BandStatus.searching:
        return 'Buscando…';
      case BandStatus.found:
        return 'Detectada';
      case BandStatus.connected:
        return 'Conectado';
      case BandStatus.error:
        return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(S.s4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(R.lg),
        boxShadow: _connectedRing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _SideCircle(label: sideLabel),
              const SizedBox(width: _sideToNameGap),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      state.name,
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (state.mac != null)
                      Text(
                        state.mac!,
                        style: AppText.monoReadout.copyWith(
                          color: AppColors.text3,
                        ),
                      ),
                  ],
                ),
              ),
              _StatusIndicator(status: state.status),
            ],
          ),
          const SizedBox(height: _topRowGap),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                state.rssi != null ? 'RSSI ${state.rssi} dBm' : 'RSSI —',
                style: AppText.bodyXs,
              ),
              if (state.battery != null)
                BatteryReading(pct: state.battery!)
              else
                Text('—', style: AppText.bodyXs.copyWith(color: AppColors.text3)),
              Text(
                _statusLabel,
                style: AppText.bodyXs.copyWith(
                  fontWeight: FontWeight.w500,
                  color: _statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SideCircle extends StatelessWidget {
  const _SideCircle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: BandCard._sideCircleSize,
      height: BandCard._sideCircleSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceHi,
        border: Border.all(color: AppColors.border),
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: AppText.bodySm.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.status});

  final BandStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case BandStatus.searching:
        return const _ScanSpinner();
      case BandStatus.found:
        return const Dot(color: AppColors.accent, size: 8, glow: true);
      case BandStatus.connected:
        return const Dot(color: AppColors.ok, size: 8, glow: true);
      case BandStatus.error:
        return const Dot(color: AppColors.crit, size: 8);
    }
  }
}

/// 14×14 spinner — a stroked circle in `border` colour with a 90° accent arc
/// at the top, rotating linearly every 800 ms (JSX literal `arc-spin`).
class _ScanSpinner extends StatefulWidget {
  const _ScanSpinner();

  @override
  State<_ScanSpinner> createState() => _ScanSpinnerState();
}

class _ScanSpinnerState extends State<_ScanSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: const SizedBox(
        width: 14,
        height: 14,
        child: RepaintBoundary(
          child: CustomPaint(painter: _SpinnerPainter()),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter();

  static const double _strokeWidth = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.width - _strokeWidth) / 2;
    final Paint base = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    canvas.drawCircle(center, radius, base);
    final Paint highlight = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    // 90° arc centred on the top of the circle.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 3 / 4,
      math.pi / 2,
      false,
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter oldDelegate) => false;
}
