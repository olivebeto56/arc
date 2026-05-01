import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

/// Custom dark theme for ARC.
///
/// Material 3 is OFF — every visual decision flows through the handoff tokens
/// (`AppColors`, `AppText`, `S`, `R`). Material widgets are not used directly:
/// only `MaterialApp` + `Scaffold(backgroundColor: AppColors.bg)` as roots.
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    canvasColor: AppColors.bg,
    fontFamily: AppText.sans,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      onSurface: AppColors.text,
      primary: AppColors.accent,
      onPrimary: AppColors.bg,
      secondary: AppColors.accent,
      onSecondary: AppColors.bg,
      error: AppColors.crit,
      onError: AppColors.text,
    ),
    textTheme: const TextTheme(
      displayLarge: AppText.display,
      displayMedium: AppText.display2,
      displaySmall: AppText.display3,
      headlineLarge: AppText.headline,
      headlineMedium: AppText.title,
      headlineSmall: AppText.title2,
      titleLarge: AppText.title2,
      titleMedium: AppText.metric,
      titleSmall: AppText.metricSm,
      bodyLarge: AppText.bodyLg,
      bodyMedium: AppText.body,
      bodySmall: AppText.bodySm,
      labelLarge: AppText.cta,
      labelMedium: AppText.caption,
      labelSmall: AppText.captionXs,
    ),
  );
}
