// from: design/design_handoff_arc_app/design/screens/atoms.jsx (ARCTopBar)

import 'package:flutter/widgets.dart';

import '../theme/app_spacing.dart';

/// 44 px-tall in-app top bar with three flex slots (left / center / right).
/// Right slot is right-aligned, left slot is left-aligned. Center is a
/// fixed-width row in between.
class ARCTopBar extends StatelessWidget {
  const ARCTopBar({
    super.key,
    this.left,
    this.center,
    this.right,
  });

  final Widget? left;
  final Widget? center;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.fromLTRB(S.s5, S.s2, S.s5, S.s3),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[if (left != null) left!],
            ),
          ),
          if (center != null) center!,
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[if (right != null) right!],
            ),
          ),
        ],
      ),
    );
  }
}
