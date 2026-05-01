// from: design/design_handoff_arc_app/design/screens/atoms.jsx (Caption)

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Eyebrow / label atom. Auto-uppercases its text and applies the caption
/// type token (10/500/0.14em). Default colour is `text3` per the handoff;
/// override via [color] for status variants (e.g. badges).
class Caption extends StatelessWidget {
  const Caption(
    this.text, {
    super.key,
    this.color = AppColors.text3,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppText.caption.copyWith(color: color),
    );
  }
}
