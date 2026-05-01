// from: design/design_handoff_arc_app/design/screens/atoms.jsx (Segmented)

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// One option of a [Segmented] control.
class SegmentedOption<T> {
  const SegmentedOption({required this.value, required this.label});
  final T value;
  final String label;
}

/// 3-position segmented pill control. Active option sits on `bg` colour,
/// inactive on transparent — both inside an outer `surfaceHi` wrapper.
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.options,
    required this.value,
    this.onChanged,
  });

  final List<SegmentedOption<T>> options;
  final T value;
  final ValueChanged<T>? onChanged;

  // JSX literal — between-scale.
  static const double _outerRadius = 10;
  static const double _innerRadius = 8;
  static const double _outerPadding = 3;
  static const double _itemGap = 2;
  static const double _itemPaddingH = 12;
  static const double _itemPaddingV = 8;

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
        children: <Widget>[
          for (int i = 0; i < options.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: _itemGap),
            Expanded(child: _buildItem(options[i])),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(SegmentedOption<T> opt) {
    final bool active = opt.value == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null ? null : () => onChanged!(opt.value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: _itemPaddingH,
          vertical: _itemPaddingV,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.bg : null,
          borderRadius: BorderRadius.circular(_innerRadius),
        ),
        child: Text(
          opt.label,
          style: AppText.bodyXs.copyWith(
            fontWeight: FontWeight.w500,
            color: active ? AppColors.text : AppColors.text2,
          ),
        ),
      ),
    );
  }
}
