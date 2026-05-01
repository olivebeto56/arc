// from: design/design_handoff_arc_app/design/screens/atoms.jsx (Icon)

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// Inline SVG icons reproduced literally from atoms.jsx.
///
/// `uses-material-design: false` is on, and the handoff bans Material widgets,
/// so we re-render the SVG paths from the JSX with `SvgPicture.string` and
/// recolour them via `BlendMode.srcIn`. New icons go here as static methods.
class ArcIcons {
  ArcIcons._();

  static Widget _build(
    String svg, {
    required double size,
    required Color color,
  }) {
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Bluetooth glyph (24×24, stroke 1.5).
  static Widget bluetooth({
    double size = 24,
    Color color = AppColors.text2,
  }) {
    return _build(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" '
      'stroke-linejoin="round">'
      '<path d="m7 7 10 10-5 5V2l5 5-10 10"/>'
      '</svg>',
      size: size,
      color: color,
    );
  }

  /// Location glyph (24×24, stroke 1.5).
  static Widget location({
    double size = 24,
    Color color = AppColors.text2,
  }) {
    return _build(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" '
      'stroke-linejoin="round">'
      '<path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/>'
      '<circle cx="12" cy="10" r="3"/>'
      '</svg>',
      size: size,
      color: color,
    );
  }

  /// Right chevron (24×24, stroke 1.5).
  static Widget chevR({
    double size = 24,
    Color color = AppColors.text3,
  }) {
    return _build(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" '
      'stroke-linejoin="round">'
      '<polyline points="9 18 15 12 9 6"/>'
      '</svg>',
      size: size,
      color: color,
    );
  }

  /// Left chevron (24×24, stroke 1.5).
  static Widget chevL({
    double size = 22,
    Color color = AppColors.text2,
  }) {
    return _build(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" '
      'stroke-linejoin="round">'
      '<polyline points="15 18 9 12 15 6"/>'
      '</svg>',
      size: size,
      color: color,
    );
  }

  /// Share / upload glyph (24×24, stroke 1.5). Used in the Summary CTAs.
  static Widget share({
    double size = 20,
    Color color = AppColors.text2,
  }) {
    return _build(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" '
      'stroke-linejoin="round">'
      '<path d="M12 16V4m0 0L8 8m4-4 4 4M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-7"/>'
      '</svg>',
      size: size,
      color: color,
    );
  }

  /// Search / magnifier glyph (24×24, stroke 1.5). Used in the History TopBar.
  static Widget search({
    double size = 20,
    Color color = AppColors.text2,
  }) {
    return _build(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" '
      'stroke-linejoin="round">'
      '<circle cx="11" cy="11" r="7"/>'
      '<line x1="21" y1="21" x2="16.65" y2="16.65"/>'
      '</svg>',
      size: size,
      color: color,
    );
  }

  /// Settings gear (24×24, stroke 1.5).
  static Widget settings({
    double size = 22,
    Color color = AppColors.text2,
  }) {
    return _build(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" '
      'stroke-linejoin="round">'
      '<circle cx="12" cy="12" r="3"/>'
      '<path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83'
      'l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0'
      'v-.09a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83'
      'l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4'
      'h.09a1.65 1.65 0 0 0 1.51-1 1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83'
      'l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0'
      'v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83'
      'l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4'
      'h-.09a1.65 1.65 0 0 0-1.51 1z"/>'
      '</svg>',
      size: size,
      color: color,
    );
  }

  /// Trend up glyph (24×24, stroke 1.5) — used next to "+4 esta semana".
  static Widget trend({
    double size = 12,
    Color color = AppColors.ok,
  }) {
    return _build(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" '
      'stroke-linejoin="round">'
      '<polyline points="3 17 9 11 13 15 21 7"/>'
      '<polyline points="14 7 21 7 21 14"/>'
      '</svg>',
      size: size,
      color: color,
    );
  }

  /// Pause glyph (24×24, solid). Used in the Dashboard PAUSA CTA.
  static Widget pause({
    double size = 18,
    Color color = AppColors.text2,
  }) {
    return _build(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#FFFFFF">'
      '<rect x="6" y="5" width="4" height="14" rx="1"/>'
      '<rect x="14" y="5" width="4" height="14" rx="1"/>'
      '</svg>',
      size: size,
      color: color,
    );
  }

  /// Stop glyph (24×24, solid). Used in the Dashboard TERMINAR CTA.
  static Widget stop({
    double size = 16,
    Color color = AppColors.crit,
  }) {
    return _build(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#FFFFFF">'
      '<rect x="6" y="6" width="12" height="12" rx="2"/>'
      '</svg>',
      size: size,
      color: color,
    );
  }

  /// Play triangle (24×24, solid). Used in the Pause modal REANUDAR CTA.
  static Widget play({
    double size = 18,
    Color color = AppColors.bg,
  }) {
    return _build(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#FFFFFF">'
      '<path d="M8 5v14l11-7z"/>'
      '</svg>',
      size: size,
      color: color,
    );
  }

  /// Battery glyph with a percentage-driven inner fill (viewBox 28×12).
  ///
  /// JSX literal — three rects with different opacities means we cannot use
  /// `BlendMode.srcIn`; instead we interpolate the colour hex into the SVG
  /// string and let `flutter_svg` honour the per-rect `*-opacity` attributes.
  static Widget battery({
    double width = 22,
    double height = 10,
    required int pct,
    required Color color,
  }) {
    final double innerWidth = (19 * pct.clamp(0, 100) / 100).clamp(0, 19).toDouble();
    final String hex = _toHex(color);
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 28 12" fill="none">'
      '<rect x="0.5" y="0.5" width="23" height="11" rx="2" '
      'stroke="$hex" stroke-opacity="0.5" fill="none"/>'
      '<rect x="2.5" y="2.5" width="${innerWidth.toStringAsFixed(2)}" '
      'height="7" rx="1" fill="$hex"/>'
      '<rect x="24.5" y="3" width="2" height="6" rx="0.5" '
      'fill="$hex" fill-opacity="0.5"/>'
      '</svg>',
      width: width,
      height: height,
    );
  }

  static String _toHex(Color c) {
    int b(double v) => (v * 255).round().clamp(0, 255);
    final String r = b(c.r).toRadixString(16).padLeft(2, '0');
    final String g = b(c.g).toRadixString(16).padLeft(2, '0');
    final String bl = b(c.b).toRadixString(16).padLeft(2, '0');
    return '#$r$g$bl';
  }
}
