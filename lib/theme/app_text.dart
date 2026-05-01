import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// ARC typography tokens.
///
/// Source: `design/design_handoff_arc_app/README.md` → Design Tokens →
/// Typography. Always reference these — never inline `TextStyle(fontSize:…)`.
///
/// Rules:
///  - Numbers and readouts: `fontFeatures: [tabularFigures]` is on by default
///    in [base]. Mono styles also use it.
///  - Captions: ALWAYS uppercase + letter-spacing 0.14em + `text3`.
///  - Body uses `text` or `text2` depending on hierarchy.
class AppText {
  AppText._();

  static const String sans = 'Inter';
  static const String mono = 'JetBrainsMono';

  static const List<FontFeature> _baseFeatures = <FontFeature>[
    FontFeature.enable('ss01'),
    FontFeature.tabularFigures(),
  ];

  /// Base text style — every other style inherits family + features from here.
  static const TextStyle base = TextStyle(
    fontFamily: sans,
    fontFeatures: _baseFeatures,
    color: AppColors.text,
    height: 1.2,
  );

  // ─── Display ───────────────────────────────────────────────
  /// 88 / 300 / -0.04em — Hero score (Home B).
  static const TextStyle display = TextStyle(
    fontFamily: sans,
    fontFeatures: _baseFeatures,
    color: AppColors.text,
    fontSize: 88,
    fontWeight: FontWeight.w300,
    letterSpacing: -88 * 0.04,
    height: 1.0,
  );

  /// 72 / 300 / -0.05em — Timer en Dashboard B/C.
  static const TextStyle display2 = TextStyle(
    fontFamily: sans,
    fontFeatures: _baseFeatures,
    color: AppColors.text,
    fontSize: 72,
    fontWeight: FontWeight.w300,
    letterSpacing: -72 * 0.05,
    height: 1.0,
  );

  /// 64 / 300 / -0.04em — Timer en Dashboard A, Pause.
  static const TextStyle display3 = TextStyle(
    fontFamily: sans,
    fontFeatures: _baseFeatures,
    color: AppColors.text,
    fontSize: 64,
    fontWeight: FontWeight.w300,
    letterSpacing: -64 * 0.04,
    height: 1.0,
  );

  /// 56 / 200–300 / -0.04em — Editorial home, splash logo.
  static const TextStyle display4 = TextStyle(
    fontFamily: sans,
    fontFeatures: _baseFeatures,
    color: AppColors.text,
    fontSize: 56,
    fontWeight: FontWeight.w200,
    letterSpacing: -56 * 0.04,
    height: 1.0,
  );

  // ─── Headline / titles ─────────────────────────────────────
  /// 38 / 200 / -0.03em — "Hola, Alberto" en Home C.
  static const TextStyle headline = TextStyle(
    fontFamily: sans,
    fontFeatures: _baseFeatures,
    color: AppColors.text,
    fontSize: 38,
    fontWeight: FontWeight.w200,
    letterSpacing: -38 * 0.03,
    height: 1.1,
  );

  /// 28 / 500 / -0.02em — Greeting en Home A.
  static const TextStyle title = TextStyle(
    fontFamily: sans,
    fontFeatures: _baseFeatures,
    color: AppColors.text,
    fontSize: 28,
    fontWeight: FontWeight.w500,
    letterSpacing: -28 * 0.02,
    height: 1.2,
  );

  /// 26 / 500 / -0.02em — Headers de pantalla.
  static const TextStyle title2 = TextStyle(
    fontFamily: sans,
    fontFeatures: _baseFeatures,
    color: AppColors.text,
    fontSize: 26,
    fontWeight: FontWeight.w500,
    letterSpacing: -26 * 0.02,
    height: 1.2,
  );

  // ─── Metrics ───────────────────────────────────────────────
  /// 26 / 500 / -0.02em — Métricas grandes en cards.
  static const TextStyle metricLg = TextStyle(
    fontFamily: sans,
    fontFeatures: _baseFeatures,
    color: AppColors.text,
    fontSize: 26,
    fontWeight: FontWeight.w500,
    letterSpacing: -26 * 0.02,
    height: 1.1,
  );

  /// 22 / 500 / -0.01em — Stats inline.
  static const TextStyle metric = TextStyle(
    fontFamily: sans,
    fontFeatures: _baseFeatures,
    color: AppColors.text,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: -22 * 0.01,
    height: 1.1,
  );

  /// 20 / 500 / -0.01em — Métricas pequeñas.
  static const TextStyle metricSm = TextStyle(
    fontFamily: sans,
    fontFeatures: _baseFeatures,
    color: AppColors.text,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: -20 * 0.01,
    height: 1.1,
  );

  // ─── Body ──────────────────────────────────────────────────
  /// 18 / 300–400 / -0.01em — Recomendaciones editoriales.
  static const TextStyle bodyLg = TextStyle(
    fontFamily: sans,
    fontFeatures: _baseFeatures,
    color: AppColors.text,
    fontSize: 18,
    fontWeight: FontWeight.w300,
    letterSpacing: -18 * 0.01,
    height: 1.4,
  );

  /// 14.5 / 400 / normal — Body por defecto.
  static const TextStyle body = TextStyle(
    fontFamily: sans,
    fontFeatures: _baseFeatures,
    color: AppColors.text,
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  /// 13 / 400 / normal — Body secundario.
  static const TextStyle bodySm = TextStyle(
    fontFamily: sans,
    fontFeatures: _baseFeatures,
    color: AppColors.text2,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// 12 / 400 / normal — Metadata.
  static const TextStyle bodyXs = TextStyle(
    fontFamily: sans,
    fontFeatures: _baseFeatures,
    color: AppColors.text2,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // ─── Captions (UPPERCASE 0.14em, color text3) ──────────────
  /// 10 / 500 / 0.14em UPPER — Eyebrows, labels.
  static const TextStyle caption = TextStyle(
    fontFamily: sans,
    fontFeatures: _baseFeatures,
    color: AppColors.text3,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 10 * 0.14,
    height: 1.2,
  );

  /// 9 / 500 / 0.14em UPPER — Captions chicas.
  static const TextStyle captionXs = TextStyle(
    fontFamily: sans,
    fontFeatures: _baseFeatures,
    color: AppColors.text3,
    fontSize: 9,
    fontWeight: FontWeight.w500,
    letterSpacing: 9 * 0.14,
    height: 1.2,
  );

  // ─── Mono readouts (RSSI, GPS, MAC, build numbers) ─────────
  /// 11 / 500 — RSSI, GPS, MAC.
  static const TextStyle monoReadout = TextStyle(
    fontFamily: mono,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    color: AppColors.text2,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  /// 10 / 500 — Versiones, build numbers (handoff: 9–10).
  static const TextStyle monoTiny = TextStyle(
    fontFamily: mono,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    color: AppColors.text3,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  // ─── CTA ───────────────────────────────────────────────────
  /// 16 / 600 / 0.02em — Primary button text.
  static const TextStyle cta = TextStyle(
    fontFamily: sans,
    fontFeatures: _baseFeatures,
    color: AppColors.text,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 16 * 0.02,
    height: 1.2,
  );

  /// 16 / 600 / 0.06em — Hero CTAs (uppercase).
  static const TextStyle ctaStrong = TextStyle(
    fontFamily: sans,
    fontFeatures: _baseFeatures,
    color: AppColors.text,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 16 * 0.06,
    height: 1.2,
  );
}
