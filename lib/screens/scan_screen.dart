// from: design/design_handoff_arc_app/design/screens/screens-onboarding.jsx
//        (ScreenScan)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/band_providers.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../widgets/arc_button.dart';
import '../widgets/arc_icons.dart';
import '../widgets/caption.dart';
import 'home_screen.dart';
import 'scan/widgets/band_card.dart';

/// Step 2 of onboarding — scan for and pair both ankle bands.
///
/// Mock-only: providers auto-progress searching → found → connected on a
/// timer. REESCANEAR resets both bands; "Saltar (modo demo)" flips
/// `settingsProvider.demoMode` so downstream screens render canned data.
class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  static const double _statusBarReserve = 56;

  // JSX literal — between-scale.
  static const double _titleToBody = 10;
  static const double _bodyToList = 28;
  static const double _cardListGap = 10;
  static const double _listToDiscarded = 0; // discarded sits below the list
  static const double _footerGap = 10;

  void _restart(WidgetRef ref) {
    ref.read(leftBandProvider.notifier).start();
    ref.read(rightBandProvider.notifier).start();
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  void _skipToDemo(BuildContext context, WidgetRef ref) {
    ref.read(settingsProvider.notifier).setDemoMode(true);
    _goHome(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final left = ref.watch(leftBandProvider);
    final right = ref.watch(rightBandProvider);
    final bool canContinue = ref.watch(bothBandsConnectedProvider);
    final int connectedCount = ref.watch(connectedBandsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: <Widget>[
          const SizedBox(height: _statusBarReserve),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(S.s6, S.s7, S.s6, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Caption('Paso 2 de 2'),
                  const SizedBox(height: S.s2),
                  const Text(
                    'Conecta tus bandas',
                    style: AppText.title2,
                  ),
                  const SizedBox(height: _titleToBody),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(
                      'Coloca SportBand-L en tu tobillo izquierdo y '
                      'SportBand-R en el derecho. Mantén el celular cerca '
                      'durante el escaneo.',
                      style: AppText.body.copyWith(color: AppColors.text2),
                    ),
                  ),
                  const SizedBox(height: _bodyToList),
                  BandCard(state: left, sideLabel: 'L'),
                  const SizedBox(height: _cardListGap),
                  BandCard(state: right, sideLabel: 'R'),
                  const SizedBox(height: S.s5),
                  Caption('$connectedCount de 2 conectadas'),
                  const SizedBox(height: S.s3),
                  const _DiscardedListCard(),
                  const SizedBox(height: _listToDiscarded),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(S.s6, S.s5, S.s6, S.s8),
            child: Column(
              children: <Widget>[
                ARCButton(
                  label: 'REESCANEAR',
                  kind: ARCButtonKind.secondary,
                  full: true,
                  onTap: () => _restart(ref),
                ),
                const SizedBox(height: _footerGap),
                ARCButton(
                  label: 'CONTINUAR',
                  full: true,
                  onTap: canContinue ? () => _goHome(context) : null,
                ),
                const SizedBox(height: S.s4),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _skipToDemo(context, ref),
                  child: Text(
                    'Saltar (modo demo)',
                    style: AppText.bodySm.copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.border,
                      decorationThickness: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscardedListCard extends StatelessWidget {
  const _DiscardedListCard();

  // JSX literal — between-scale.
  static const double _radius = 10;
  static const double _padH = 14;
  static const double _padV = S.s3;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _padH,
        vertical: _padV,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceHi,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          // TODO(arc): wire to actual scan results in Phase 4.
          const Text('3 dispositivos descartados', style: AppText.bodyXs),
          ArcIcons.chevR(size: 14, color: AppColors.text3),
        ],
      ),
    );
  }
}

