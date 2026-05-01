// from: design/design_handoff_arc_app/design/screens/screens-post.jsx
//        (Row component inside ScreenSettings)

import 'package:flutter/widgets.dart';

import '../../../theme/app_colors.dart';

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.left,
    this.right,
    this.onTap,
    this.divider = true,
  });

  /// Left-side widget — typically a `Text` for the row label, but can be
  /// any composition (e.g. icon + text for the band rows).
  final Widget left;

  /// Right-side widget — value text + chevron, version readout, or `null`
  /// for action rows like "Borrar historial".
  final Widget? right;

  final VoidCallback? onTap;
  final bool divider;

  // JSX literal — between-scale.
  static const double _padV = 12;
  static const double _padH = 14;
  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _padH,
        vertical: _padV,
      ),
      decoration: BoxDecoration(
        border: divider
            ? const Border(
                bottom: BorderSide(color: AppColors.border),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(child: left),
          if (right != null) ...<Widget>[
            const SizedBox(width: _gap),
            DefaultTextStyle.merge(
              style: const TextStyle(),
              child: right!,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}
