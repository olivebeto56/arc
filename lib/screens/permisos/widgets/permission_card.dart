// from: design/design_handoff_arc_app/design/screens/screens-onboarding.jsx
//        (Permission inside ScreenPermisos)

import 'package:flutter/widgets.dart';

import '../../../providers/permissions_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/caption.dart';

typedef ArcIconBuilder = Widget Function({double size, Color color});

/// Single permission row card — icon, title, description, status badge.
///
/// Visual spec from the JSX `Permission` component:
///  - card padding 18, gap 14, radius 14, surface bg
///  - icon container 40×40, radius 10, surfaceHi bg, accent foreground
///  - title 15/500/text, badge = Caption with status colour
///  - description 12.5/text2 (we use AppText.bodyXs = 12/text2, +0.5 px diff)
class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    required this.iconBuilder,
    required this.title,
    required this.description,
    required this.status,
    this.onTap,
  });

  final ArcIconBuilder iconBuilder;
  final String title;
  final String description;
  final PermissionStatus status;
  final VoidCallback? onTap;

  // JSX literal — between-scale values not present in the spacing/radii tokens.
  static const double _cardPadding = 18;
  static const double _iconBoxSize = 40;
  static const double _iconBoxRadius = 10;
  static const double _innerGap = 14;
  static const double _iconSize = 20;

  static String _label(PermissionStatus s) {
    switch (s) {
      case PermissionStatus.granted:
        return 'Concedido';
      case PermissionStatus.pending:
        return 'Pendiente';
      case PermissionStatus.denied:
        return 'Denegado';
    }
  }

  static Color _statusColor(PermissionStatus s) {
    switch (s) {
      case PermissionStatus.granted:
        return AppColors.ok;
      case PermissionStatus.pending:
        return AppColors.text3;
      case PermissionStatus.denied:
        return AppColors.crit;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget card = Container(
      padding: const EdgeInsets.all(_cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(R.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: _iconBoxSize,
            height: _iconBoxSize,
            decoration: BoxDecoration(
              color: AppColors.surfaceHi,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(_iconBoxRadius),
            ),
            alignment: Alignment.center,
            child: iconBuilder(size: _iconSize, color: AppColors.accent),
          ),
          const SizedBox(width: _innerGap),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          title,
                          style: AppText.body.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Caption(_label(status), color: _statusColor(status)),
                    ],
                  ),
                  const SizedBox(height: S.s1),
                  Text(description, style: AppText.bodyXs),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}
