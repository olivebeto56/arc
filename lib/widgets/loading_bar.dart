// from: design/design_handoff_arc_app/design/screens/screens-onboarding.jsx
//        (loading bar inside ScreenSplash)

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';

/// Thin horizontal loading bar with a cyan segment travelling left → right.
///
/// JSX keyframes (1.4 s, ease-in-out, infinite, no reverse):
///   0%   → segment.left = -segmentWidth   (off-screen left)
///   50%  → segment.left = trackWidth / 2
///   100% → segment.left = trackWidth      (off-screen right)
///
/// We approximate with a single Curves.easeInOut tween from -segmentWidth to
/// trackWidth — visually indistinguishable from the per-segment ease.
class LoadingBar extends StatefulWidget {
  const LoadingBar({
    super.key,
    this.trackWidth = 32,
    this.segmentWidth = 12,
    this.height = 1,
  });

  final double trackWidth;
  final double segmentWidth;
  final double height;

  @override
  State<LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<LoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double startLeft = -widget.segmentWidth;
    final double endLeft = widget.trackWidth;

    return SizedBox(
      width: widget.trackWidth,
      height: widget.height,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            Container(color: AppColors.border),
            AnimatedBuilder(
              animation: _animation,
              builder: (BuildContext context, Widget? _) {
                final double left = startLeft +
                    (endLeft - startLeft) * _animation.value;
                return Positioned(
                  left: left,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: widget.segmentWidth,
                    color: AppColors.accent,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
