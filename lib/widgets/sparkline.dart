// from: design/design_handoff_arc_app/design/screens/atoms.jsx (Sparkline)

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';

/// Compact line chart — normalises [values] to fit the box and draws a
/// single 1.5 px polyline with a small dot at the last point.
///
/// Static (no animation) per the JSX. CustomPainter so it works without
/// pulling in `fl_chart` for a one-line preview.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.width = 60,
    this.height = 18,
    this.color = AppColors.accent,
    this.dot = true,
  });

  final List<double> values;
  final double width;
  final double height;
  final Color color;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(values: values, color: color, dot: dot),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.color,
    required this.dot,
  });

  final List<double> values;
  final Color color;
  final bool dot;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    double min = values.first;
    double max = values.first;
    for (final double v in values) {
      if (v < min) min = v;
      if (v > max) max = v;
    }
    final double range = (max - min) == 0 ? 1 : (max - min);

    final Path path = Path();
    final List<Offset> points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final double x = (i / (values.length - 1)) * size.width;
      final double y = size.height - ((values[i] - min) / range) * size.height;
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke);

    if (dot) {
      canvas.drawCircle(
        points.last,
        2,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.color != color || old.dot != dot;
}
