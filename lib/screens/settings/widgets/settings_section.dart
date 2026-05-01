// from: design/design_handoff_arc_app/design/screens/screens-post.jsx
//        (Section component inside ScreenSettings)

import 'package:flutter/widgets.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../widgets/caption.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  // JSX literal — between-scale.
  static const double _bottomMargin = 18;
  static const double _captionLeftPadding = 4;
  static const double _captionToCard = 10;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _bottomMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: _captionLeftPadding),
            child: Caption(title, color: AppColors.text2),
          ),
          const SizedBox(height: _captionToCard),
          ClipRRect(
            borderRadius: BorderRadius.circular(R.md),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(R.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
