// from: design/design_handoff_arc_app/design/screens/screens-live.jsx
//        (ScreenDashboardB MAPA / CARDS pill — visual only in this variant)

import 'package:flutter/widgets.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';

class ViewToggle extends StatelessWidget {
  const ViewToggle({super.key});

  // JSX literal — between-scale.
  static const double _outerRadius = 8;
  static const double _innerRadius = 6;
  static const double _outerPadding = 3;
  static const double _gap = 4;
  static const double _itemPadH = 12;
  static const double _itemPadV = 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_outerPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceHi,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(_outerRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // TODO(arc): swap to ScreenDashboardA (map variant) on tap.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: const _Pill(label: 'MAPA', active: false),
          ),
          const SizedBox(width: _gap),
          const _Pill(label: 'CARDS', active: true),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ViewToggle._itemPadH,
        vertical: ViewToggle._itemPadV,
      ),
      decoration: BoxDecoration(
        color: active ? AppColors.bg : null,
        borderRadius: BorderRadius.circular(ViewToggle._innerRadius),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          color: active ? AppColors.text : AppColors.text2,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
