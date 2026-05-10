// from: design/design_handoff_arc_app/design/screens/screens-onboarding.jsx
//        (ScreenPermisos)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/permissions_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../widgets/arc_button.dart';
import '../widgets/arc_icons.dart';
import '../widgets/caption.dart';
import 'permisos/widgets/permission_card.dart';
import 'scan_screen.dart';

/// Step 1 of onboarding — request Bluetooth + Location permissions.
///
/// Tapping a card escalates through the OS flow handled by
/// `_PermissionNotifier`: first tap shows the system prompt; subsequent
/// taps (after a permanent denial) jump to the app's Settings page so the
/// user can flip the toggle. We also re-check both permissions when the
/// app resumes, so coming back from Settings refreshes the badges.
class PermisosScreen extends ConsumerStatefulWidget {
  const PermisosScreen({super.key});

  @override
  ConsumerState<PermisosScreen> createState() => _PermisosScreenState();
}

class _PermisosScreenState extends ConsumerState<PermisosScreen>
    with WidgetsBindingObserver {
  // Status bar reservation per handoff (we draw our own bar — not native).
  static const double _statusBarReserve = 56;

  // JSX literal — between-scale gap between the two permission cards.
  static const double _cardListGap = 10;

  // JSX literal — H1 marginBottom 10, between S.s2 and S.s3.
  static const double _titleToBody = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Catch grants/denials the user made in Settings.
      // ignore: unawaited_futures
      ref.read(bluetoothPermissionProvider.notifier).refresh();
      // ignore: unawaited_futures
      ref.read(locationPermissionProvider.notifier).refresh();
    }
  }

  void _requestBluetooth() {
    // ignore: unawaited_futures
    ref.read(bluetoothPermissionProvider.notifier).request();
  }

  void _requestLocation() {
    // ignore: unawaited_futures
    ref.read(locationPermissionProvider.notifier).request();
  }

  @override
  Widget build(BuildContext context) {
    final PermissionStatus btStatus = ref.watch(bluetoothPermissionProvider);
    final PermissionStatus locStatus = ref.watch(locationPermissionProvider);
    final bool canContinue = ref.watch(allPermissionsGrantedProvider);

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
                  const Caption('Paso 1 de 2'),
                  const SizedBox(height: S.s2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: const Text(
                      'Necesitamos algunos permisos',
                      style: AppText.title2,
                    ),
                  ),
                  const SizedBox(height: _titleToBody),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(
                      'ARC necesita conectarse a tus bandas y conocer tu '
                      'ubicación para registrar la sesión.',
                      style: AppText.body.copyWith(color: AppColors.text2),
                    ),
                  ),
                  const SizedBox(height: S.s7),
                  PermissionCard(
                    iconBuilder: ArcIcons.bluetooth,
                    title: 'Bluetooth',
                    description:
                        'Para conectar las bandas SportBand-L y SportBand-R '
                        'en tus tobillos.',
                    status: btStatus,
                    // Always tappable — request() handles every state
                    // (granted = no-op, denied = re-prompt, permanently
                    // denied = openAppSettings).
                    onTap: _requestBluetooth,
                  ),
                  const SizedBox(height: _cardListGap),
                  PermissionCard(
                    iconBuilder: ArcIcons.location,
                    title: 'Ubicación',
                    description:
                        'Para registrar tu ruta y calcular distancia y ritmo '
                        'reales con GPS.',
                    status: locStatus,
                    onTap: _requestLocation,
                  ),
                  const SizedBox(height: S.s5),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    // TODO(arc): show a bottom sheet explaining each permission.
                    onTap: () {},
                    child: Text(
                      '¿Por qué los necesitamos?',
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(S.s6, S.s5, S.s6, S.s8),
            child: ARCButton(
              label: 'CONTINUAR',
              full: true,
              onTap: canContinue ? () => _goToScan(context) : null,
            ),
          ),
        ],
      ),
    );
  }

  void _goToScan(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ScanScreen()),
    );
  }
}
