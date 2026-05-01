// from: design/design_handoff_arc_app/design/screens/screens-post.jsx
//        (ScreenSettings)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/band_state.dart';
import '../models/settings_state.dart';
import '../providers/band_providers.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../widgets/arc_button.dart';
import '../widgets/arc_icons.dart';
import '../widgets/arc_slider.dart';
import '../widgets/arc_top_bar.dart';
import '../widgets/battery_reading.dart';
import 'settings/widgets/settings_row.dart';
import 'settings/widgets/settings_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // JSX literal — between-scale.
  static const double _statusBarReserve = 56;
  static const double _bodyHPadding = S.s5;
  static const double _bodyTopPadding = S.s2;
  static const double _bodyBottomPadding = S.s5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsState settings = ref.watch(settingsProvider);
    final BandState left = ref.watch(leftBandProvider);
    final BandState right = ref.watch(rightBandProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: <Widget>[
            const SizedBox(height: _statusBarReserve),
            ARCTopBar(
              left: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: ArcIcons.chevL(size: 22),
              ),
              center: Text(
                'Ajustes',
                style: AppText.body.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  _bodyHPadding,
                  _bodyTopPadding,
                  _bodyHPadding,
                  _bodyBottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SettingsSection(
                      title: 'Bandas',
                      children: <Widget>[
                        _BandRow(side: 'L', state: left),
                        _BandRow(side: 'R', state: right, divider: false),
                      ],
                    ),
                    SettingsSection(
                      title: 'Calibración de detección',
                      children: <Widget>[
                        ARCSlider(
                          label: 'Impact threshold',
                          value: settings.impactThreshold,
                          min: 8,
                          max: 18,
                          unit: 'm/s²',
                        ),
                        const _Divider(),
                        ARCSlider(
                          label: 'Takeoff threshold',
                          value: settings.takeoffThreshold,
                          min: 1,
                          max: 5,
                          unit: 'm/s²',
                        ),
                        const _Divider(),
                        ARCSlider(
                          label: 'Min step duration',
                          value: settings.minStepDurationMs.toDouble(),
                          min: 100,
                          max: 300,
                          unit: 'ms',
                        ),
                        const _Divider(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ARCButton(
                              label: 'Restaurar defaults',
                              kind: ARCButtonKind.secondary,
                              size: ARCButtonSize.sm,
                              onTap: () => ref
                                  .read(settingsProvider.notifier)
                                  .resetCalibrationDefaults(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SettingsSection(
                      title: 'Personal',
                      children: <Widget>[
                        SettingsRow(
                          left: _label('Altura'),
                          right: _valueWithChev('${settings.heightCm} cm'),
                          // TODO(arc): open height picker.
                          onTap: () {},
                        ),
                        SettingsRow(
                          left: _label('Peso'),
                          right: _valueWithChev('${settings.weightKg} kg'),
                          // TODO(arc): open weight picker.
                          onTap: () {},
                        ),
                        SettingsRow(
                          left: _label('Longitud zancada'),
                          right: _valueWithChev(
                            '${settings.strideLengthM.toStringAsFixed(2)} m',
                          ),
                          divider: false,
                          // TODO(arc): open stride picker.
                          onTap: () {},
                        ),
                      ],
                    ),
                    SettingsSection(
                      title: 'Unidades',
                      children: <Widget>[
                        SettingsRow(
                          left: _label('Sistema'),
                          right: _valueWithChev(settings.unitSystemLabel),
                          // TODO(arc): toggle metric/imperial via picker.
                          onTap: () {},
                        ),
                        SettingsRow(
                          left: _label('Idioma'),
                          right: _valueWithChev(settings.languageLabel),
                          divider: false,
                          // TODO(arc): open language picker.
                          onTap: () {},
                        ),
                      ],
                    ),
                    SettingsSection(
                      title: 'Datos',
                      children: <Widget>[
                        SettingsRow(
                          left: _label('Exportar CSV'),
                          right: ArcIcons.chevR(size: 14),
                          // TODO(arc): trigger CSV export in Phase 4.
                          onTap: () {},
                        ),
                        SettingsRow(
                          left: Text(
                            'Borrar historial',
                            style: AppText.bodyXs.copyWith(
                              color: AppColors.crit,
                            ),
                          ),
                          divider: false,
                          // TODO(arc): show confirmation modal then call
                          // sessionHistoryProvider.notifier.clear().
                          onTap: () {},
                        ),
                      ],
                    ),
                    SettingsSection(
                      title: 'Acerca de',
                      children: <Widget>[
                        SettingsRow(
                          left: _label('Versión'),
                          right: Text(
                            '1.0.0 · 247',
                            style: AppText.monoTiny.copyWith(
                              color: AppColors.text2,
                            ),
                          ),
                        ),
                        SettingsRow(
                          left: _label('Política de privacidad'),
                          right: ArcIcons.chevR(size: 14),
                          divider: false,
                          // TODO(arc): open privacy policy URL.
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _label(String text) {
    return Text(
      text,
      style: AppText.bodySm.copyWith(color: AppColors.text),
    );
  }

  static Widget _valueWithChev(String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          value,
          style: AppText.bodyXs.copyWith(color: AppColors.text2),
        ),
        const SizedBox(width: 6),
        ArcIcons.chevR(size: 14),
      ],
    );
  }
}

class _BandRow extends StatelessWidget {
  const _BandRow({
    required this.side,
    required this.state,
    this.divider = true,
  });

  final String side;
  final BandState state;
  final bool divider;

  static const double _circleSize = 22;

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      divider: divider,
      // TODO(arc): open band detail / forget action.
      onTap: () {},
      left: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: _circleSize,
            height: _circleSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceHi,
              border: Border.all(color: AppColors.border),
              shape: BoxShape.circle,
            ),
            child: Text(
              side,
              style: AppText.bodyXs.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            state.name,
            style: AppText.bodySm.copyWith(color: AppColors.text),
          ),
        ],
      ),
      right: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (state.battery != null)
            BatteryReading(pct: state.battery!)
          else
            Text(
              '—',
              style: AppText.bodyXs.copyWith(color: AppColors.text3),
            ),
          const SizedBox(width: 6),
          ArcIcons.chevR(size: 14),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.border,
    );
  }
}
