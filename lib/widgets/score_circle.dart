// from: design/design_handoff_arc_app/README.md (Summary Score circle)
//        design/design_handoff_arc_app/design/screens/screens-post.jsx
//        (ScoreCircle inside ScreenSummary)

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Where the small `/100` (or `/ 100`) suffix lives relative to the score
/// number inside the circle.
enum ScoreCircleSuffixPlacement { beside, below }

/// Circular score gauge — full ring in `border` colour, accent arc whose
/// sweep is proportional to [score] / 100. The arc is rendered twice: a
/// blurred wider pass underneath (cyan glow) and a solid arc on top.
///
/// On first build the arc fills from 0 to its target with an 800 ms
/// `easeOutCubic` tween. Setting [animateOnFirstBuild] to false skips that
/// (used by the History screen's tiny ring where the entrance would be
/// distracting).
class ScoreCircle extends StatelessWidget {
  const ScoreCircle({
    super.key,
    required this.score,
    this.diameter = 160,
    this.strokeWidth = 8,
    this.numberStyle = AppText.display2,
    this.suffix = '/100',
    this.suffixPlacement = ScoreCircleSuffixPlacement.beside,
    this.suffixStyle,
    this.animateOnFirstBuild = true,
  });

  final int score;
  final double diameter;
  final double strokeWidth;
  final TextStyle numberStyle;
  final String suffix;
  final ScoreCircleSuffixPlacement suffixPlacement;
  final TextStyle? suffixStyle;
  final bool animateOnFirstBuild;

  @override
  Widget build(BuildContext context) {
    final TextStyle resolvedSuffix = suffixStyle ??
        (suffixPlacement == ScoreCircleSuffixPlacement.beside
            ? AppText.bodyLg.copyWith(color: AppColors.text3)
            : AppText.captionXs.copyWith(
                color: AppColors.text3,
                letterSpacing: 0,
              ));

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          RepaintBoundary(
            child: TweenAnimationBuilder<double>(
              duration: animateOnFirstBuild
                  ? const Duration(milliseconds: 800)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: 1),
              builder: (BuildContext _, double progress, Widget? __) {
                return CustomPaint(
                  size: Size.square(diameter),
                  painter: _ScoreRingPainter(
                    score: score,
                    strokeWidth: strokeWidth,
                    progress: progress,
                  ),
                );
              },
            ),
          ),
          _InnerLabel(
            score: score,
            suffix: suffix,
            placement: suffixPlacement,
            numberStyle: numberStyle,
            suffixStyle: resolvedSuffix,
          ),
        ],
      ),
    );
  }
}

class _InnerLabel extends StatelessWidget {
  const _InnerLabel({
    required this.score,
    required this.suffix,
    required this.placement,
    required this.numberStyle,
    required this.suffixStyle,
  });

  final int score;
  final String suffix;
  final ScoreCircleSuffixPlacement placement;
  final TextStyle numberStyle;
  final TextStyle suffixStyle;

  @override
  Widget build(BuildContext context) {
    final Text number = Text(
      '$score',
      style: numberStyle.copyWith(color: AppColors.accent),
    );
    final Text suffixText = Text(suffix, style: suffixStyle);

    switch (placement) {
      case ScoreCircleSuffixPlacement.beside:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[number, suffixText],
        );
      case ScoreCircleSuffixPlacement.below:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            number,
            const SizedBox(height: 2),
            suffixText,
          ],
        );
    }
  }
}

class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter({
    required this.score,
    required this.strokeWidth,
    required this.progress,
  });

  final int score;
  final double strokeWidth;

  /// 0..1 — multiplied with the target sweep so the arc fills in.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.width - strokeWidth) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint base = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, base);

    final double targetSweep = 2 * math.pi * (score.clamp(0, 100) / 100);
    final double sweep = targetSweep * progress.clamp(0.0, 1.0);
    if (sweep <= 0) return;

    // Glow under the arc (drawn first, blurred).
    final Paint glow = Paint()
      ..color = AppColors.accentGlow
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, glow);

    // Solid accent arc on top.
    final Paint arc = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter old) =>
      old.score != score ||
      old.strokeWidth != strokeWidth ||
      old.progress != progress;
}
