// from: design/design_handoff_arc_app/design/screens/screens-post.jsx
//        (ARCMap inside ScreenSummary) — placeholder until Phase 4
//        flutter_map / Mapbox integration.

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import 'caption.dart';

/// Stand-in for the route map. Renders a `surfaceMap`-tinted card with a
/// soft caption overlay so the layout space is reserved while the real
/// map integration is pending.
///
/// Pass `label: null` (or empty) to render a label-less mini variant
/// — used by `SessionRow` in History for the 48×48 route preview.
class RouteMapPlaceholder extends StatelessWidget {
  const RouteMapPlaceholder({
    super.key,
    this.height = 180,
    this.width,
    this.radius = R.lg,
    this.label = 'MAPA · TODO FASE 4',
  });

  final double height;

  /// `null` → fills available width.
  final double? width;
  final double radius;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceMap,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: (label == null || label!.isEmpty) ? null : Caption(label!),
    );
  }
}
