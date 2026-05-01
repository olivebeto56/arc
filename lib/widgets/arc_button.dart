// from: design/design_handoff_arc_app/design/screens/atoms.jsx (ARCButton)

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_radii.dart';

enum ARCButtonKind { primary, secondary, ghost, destructive, danger }

enum ARCButtonSize { lg, md, sm }

/// Pressable CTA atom built from `Container + GestureDetector` (no Material
/// widgets). Five visual kinds × three sizes per atoms.jsx.
///
/// Disabled state is signalled by passing `onTap == null` — the button renders
/// at `opacity 0.4` and stops absorbing pointer events.
class ARCButton extends StatelessWidget {
  const ARCButton({
    super.key,
    required this.label,
    this.onTap,
    this.kind = ARCButtonKind.primary,
    this.size = ARCButtonSize.lg,
    this.icon,
    this.full = false,
    this.glow = false,
  });

  final String label;
  final VoidCallback? onTap;
  final ARCButtonKind kind;
  final ARCButtonSize size;
  final Widget? icon;
  final bool full;

  /// When true and the button is enabled, projects an outer cyan glow
  /// (`accentDim2 / blurRadius 32`). The handoff JSX applies this to the
  /// hero "INICIAR SESIÓN" CTA on Home A and Home B.
  final bool glow;

  bool get _enabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    final _Sizing s = _sizingFor(size);
    final _Palette p = _paletteFor(kind);

    final Widget content = Row(
      mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          icon!,
          const SizedBox(width: 8),
        ],
        Text(label, style: s.textStyle.copyWith(color: p.foreground)),
      ],
    );

    final Widget body = Container(
      padding: EdgeInsets.symmetric(
        horizontal: s.paddingH,
        vertical: s.paddingV,
      ),
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(s.radius),
        border: p.borderColor != null
            ? Border.all(color: p.borderColor!)
            : null,
        boxShadow: (glow && _enabled)
            ? const <BoxShadow>[
                BoxShadow(color: AppColors.accentDim2, blurRadius: 32),
              ]
            : null,
      ),
      child: content,
    );

    final Widget interactive = _enabled
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: body,
          )
        : Opacity(opacity: 0.4, child: body);

    return full ? SizedBox(width: double.infinity, child: interactive) : interactive;
  }

  static _Sizing _sizingFor(ARCButtonSize size) {
    switch (size) {
      case ARCButtonSize.lg:
        // JSX literal — between-scale paddings.
        return const _Sizing(
          paddingH: 24,
          paddingV: 18,
          radius: R.button,
          textStyle: AppText.ctaStrong,
        );
      case ARCButtonSize.md:
        return _Sizing(
          paddingH: 20,
          paddingV: 12,
          radius: R.md,
          textStyle: AppText.body.copyWith(fontWeight: FontWeight.w500),
        );
      case ARCButtonSize.sm:
        // JSX literal — radius 10 (between R.sm=8 and R.md=12).
        return _Sizing(
          paddingH: 14,
          paddingV: 8,
          radius: 10,
          textStyle: AppText.bodySm.copyWith(fontWeight: FontWeight.w500),
        );
    }
  }

  static _Palette _paletteFor(ARCButtonKind kind) {
    switch (kind) {
      case ARCButtonKind.primary:
        return const _Palette(
          background: AppColors.accent,
          foreground: AppColors.bg,
        );
      case ARCButtonKind.secondary:
        return const _Palette(
          background: null,
          foreground: AppColors.text,
          borderColor: AppColors.border,
        );
      case ARCButtonKind.ghost:
        return const _Palette(
          background: AppColors.surface,
          foreground: AppColors.text,
          borderColor: AppColors.border,
        );
      case ARCButtonKind.destructive:
        return _Palette(
          background: AppColors.crit.withValues(alpha: 0.10),
          foreground: AppColors.crit,
          borderColor: AppColors.crit,
        );
      case ARCButtonKind.danger:
        return const _Palette(
          background: AppColors.crit,
          foreground: AppColors.text,
        );
    }
  }
}

class _Sizing {
  const _Sizing({
    required this.paddingH,
    required this.paddingV,
    required this.radius,
    required this.textStyle,
  });

  final double paddingH;
  final double paddingV;
  final double radius;
  final TextStyle textStyle;
}

class _Palette {
  const _Palette({
    required this.background,
    required this.foreground,
    this.borderColor,
  });

  final Color? background;
  final Color foreground;
  final Color? borderColor;
}
