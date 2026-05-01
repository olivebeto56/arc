import 'package:flutter/painting.dart';

/// ARC color tokens.
///
/// Source of truth: `design/design_handoff_arc_app/README.md` (Design Tokens →
/// Colors) and `design/design_handoff_arc_app/design/screens/tokens.js`.
/// Do not invent colors — derive with `withOpacity` from a token if needed.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color bg = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF13131F);
  static const Color surfaceHi = Color(0xFF0F0F1A);
  static const Color surfaceMap = Color(0xFF0F1A1F);

  // Borders
  static const Color border = Color(0xFF2B2D3F);
  static const Color borderHi = Color(0xFF3A3D52);

  // Text
  static const Color text = Color(0xFFFFFFFF);
  static const Color text2 = Color(0xFF9AA0AB);
  static const Color text3 = Color(0xFF7A7E88);
  static const Color text4 = Color(0xFF52555E);

  // Accent — cyan, the signature color
  static const Color accent = Color(0xFF00E5FF);
  static const Color accentDim = Color(0x2600E5FF); // 15%
  static const Color accentDim2 = Color(0x5400E5FF); // 33%
  static const Color accentGlow = Color(0x8000E5FF); // 50%

  // Semantic status
  static const Color ok = Color(0xFF3DDC84);
  static const Color okDim = Color(0x2E3DDC84);
  static const Color warn = Color(0xFFFFB020);
  static const Color warnDim = Color(0x2EFFB020);
  static const Color crit = Color(0xFFFF4D4F);
  static const Color critDim = Color(0x26FF4D4F);

  // Brand alt accent
  static const Color lime = Color(0xFFD6FF00);
}
