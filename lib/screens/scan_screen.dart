import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/band_state.dart';
import '../providers/settings_provider.dart';
import '../services/ble_manager.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../widgets/arc_button.dart';
import '../widgets/arc_icons.dart';
import '../widgets/battery_reading.dart';
import '../widgets/caption.dart';
import 'home_screen.dart';
import 'pairing/identify_screen.dart';

/// Scan + manual-connect screen. The user picks two bands to connect
/// and then continues to the side-assignment step.
///
/// Flow:
///   1. Empty state → centered "Buscando…" hero with pulse spinner.
///   2. As `SportBand-XXXX` advertisers arrive, they appear as tappable
///      rows in a "Disponibles" section. RSSI keeps refreshing live.
///   3. Tap a row → calls `BleManager.connectBand(chipId)`. The row
///      shows a connecting spinner and then jumps to the "Conectadas"
///      section once the GATT subscription is up.
///   4. Tap a connected row to undo (rare; still useful while testing).
///   5. CONTINUAR enables when 2 bands are connected → `IdentifyScreen`
///      (where the user picks which side each band belongs to —
///      currently still the shake flow; tap-to-assign lands later).
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  static const double _statusBarReserve = 56;

  void _restart() {
    // REESCANEAR keeps connected bands and persisted assignments —
    // we just refresh the discoverable list. Use the manager's
    // `restartScan` (full teardown) only from a dedicated "Olvidar
    // bandas" path in Settings (not yet wired up).
    // ignore: unawaited_futures
    ref.read(bleManagerProvider.notifier).rescan();
  }

  void _connectBand(String chipId) {
    // ignore: unawaited_futures
    ref.read(bleManagerProvider.notifier).connectBand(chipId);
  }

  Future<void> _confirmDisconnect(BandState band) async {
    final bool? confirmed = await Navigator.of(context).push<bool>(
      _ConfirmDisconnectRoute(bandName: band.name),
    );
    if (!mounted) return;
    if (confirmed == true) {
      // ignore: unawaited_futures
      ref.read(bleManagerProvider.notifier).disconnectBand(band.chipId);
    }
  }

  void _goNext() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const IdentifyScreen()),
    );
  }

  void _skipToDemo() {
    ref.read(settingsProvider.notifier).setDemoMode(true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BleManagerState manager = ref.watch(bleManagerProvider);

    final List<BandState> connected = manager.bands.values
        .where((BandState b) => b.status == BandStatus.connected)
        .toList();
    // Discovered list = anything not actively connected. Sort by RSSI
    // (closest first) so the most useful options surface at the top.
    final List<BandState> discovered = manager.bands.values
        .where((BandState b) => b.status != BandStatus.connected)
        .toList()
      ..sort((BandState a, BandState b) =>
          (b.rssi ?? -200).compareTo(a.rssi ?? -200));

    final bool empty = manager.bands.isEmpty;
    // TODO(arc): revert to `>= 2` once both physical bands are wired.
    // Single-band mode lets us iterate the rest of the flow with one
    // working sensor.
    final bool canContinue = connected.isNotEmpty;

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
                  const Text('Conecta tus bandas', style: AppText.title2),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(
                      'Toca la SportBand que quieras conectar primero. '
                      'Cuando tengas dos conectadas presiona Continuar.',
                      style: AppText.body.copyWith(color: AppColors.text2),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (empty)
                    const Center(child: _SearchingHero())
                  else ...<Widget>[
                    if (connected.isNotEmpty) ...<Widget>[
                      const Caption('Conectadas'),
                      const SizedBox(height: S.s3),
                      for (final BandState b in connected) ...<Widget>[
                        _ConnectedRow(
                          state: b,
                          onTap: () => _confirmDisconnect(b),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: S.s5),
                    ],
                    if (discovered.isNotEmpty) ...<Widget>[
                      Caption(
                        connected.isEmpty
                            ? 'Disponibles'
                            : 'Disponibles · toca para conectar',
                      ),
                      const SizedBox(height: S.s3),
                      for (final BandState b in discovered) ...<Widget>[
                        _DiscoveredRow(
                          state: b,
                          onTap: () => _connectBand(b.chipId),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ],
                  const SizedBox(height: S.s5),
                  // Persistent "Buscando…" footer while the radio is
                  // still actively scanning — stays visible after the
                  // first band is discovered so the user knows the app
                  // is still looking for the second one.
                  if (manager.scanning && !empty)
                    const _SearchingFooter(),
                  const SizedBox(height: S.s4),
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
                  onTap: _restart,
                ),
                const SizedBox(height: 10),
                ARCButton(
                  label: 'CONTINUAR',
                  full: true,
                  onTap: canContinue ? _goNext : null,
                ),
                const SizedBox(height: S.s4),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _skipToDemo,
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

// ─── Empty / searching state ─────────────────────────────────────

/// Centered hero shown while the scan hasn't returned any
/// `SportBand-XXXX` advertisers yet. Pulse animation + "Buscando…" copy.
class _SearchingHero extends StatelessWidget {
  const _SearchingHero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: S.s8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const _PulseSpinner(),
          const SizedBox(height: S.s5),
          Text(
            'Buscando…',
            style: AppText.body.copyWith(color: AppColors.text2),
          ),
          const SizedBox(height: S.s2),
          Text(
            'Asegúrate de que tus SportBand estén encendidas y cerca.',
            textAlign: TextAlign.center,
            style: AppText.bodyXs.copyWith(color: AppColors.text3),
          ),
        ],
      ),
    );
  }
}

/// Compact "still scanning" indicator anchored under the lists. Renders
/// the same arc spinner as a connecting row plus a one-liner caption,
/// so the user can tell the radio is still hunting for the second
/// band even after the first one shows up.
class _SearchingFooter extends StatelessWidget {
  const _SearchingFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: S.s3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const _SmallSpinner(),
          const SizedBox(width: S.s3),
          Text(
            'Buscando otras SportBand…',
            style: AppText.bodyXs.copyWith(color: AppColors.text3),
          ),
        ],
      ),
    );
  }
}

// ─── Discovered row ───────────────────────────────────────────────

class _DiscoveredRow extends StatelessWidget {
  const _DiscoveredRow({required this.state, required this.onTap});

  final BandState state;
  final VoidCallback onTap;

  static const double _padH = 14;
  static const double _padV = 14;

  @override
  Widget build(BuildContext context) {
    final bool busy = state.status == BandStatus.connecting;
    final bool errored = state.status == BandStatus.error;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: _padH, vertical: _padV),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color: errored ? AppColors.crit : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(R.lg),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    state.name,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subline(state),
                    style: AppText.bodyXs.copyWith(color: AppColors.text3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: S.s3),
            _DiscoveredTrailing(status: state.status),
          ],
        ),
      ),
    );
  }

  static String _subline(BandState state) {
    switch (state.status) {
      case BandStatus.found:
        return 'RSSI ${state.rssi ?? "—"} dBm · Toca para conectar';
      case BandStatus.connecting:
        return 'Conectando…';
      case BandStatus.error:
        return 'No se pudo conectar · Toca para reintentar';
      case BandStatus.searching:
      case BandStatus.connected:
        return 'RSSI ${state.rssi ?? "—"} dBm';
    }
  }
}

class _DiscoveredTrailing extends StatelessWidget {
  const _DiscoveredTrailing({required this.status});

  final BandStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case BandStatus.connecting:
        return const _SmallSpinner();
      case BandStatus.error:
        return ArcIcons.refresh(size: 18, color: AppColors.crit);
      case BandStatus.searching:
      case BandStatus.found:
      case BandStatus.connected:
        return ArcIcons.chevR(size: 22, color: AppColors.text3);
    }
  }
}

// ─── Connected row ────────────────────────────────────────────────

class _ConnectedRow extends StatelessWidget {
  const _ConnectedRow({required this.state, required this.onTap});

  final BandState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.accent),
          borderRadius: BorderRadius.circular(R.lg),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.accentDim,
              blurRadius: 0,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: ArcIcons.check(size: 16, color: AppColors.bg),
            ),
            const SizedBox(width: S.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    state.name,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Conectada',
                    style: AppText.bodyXs.copyWith(color: AppColors.ok),
                  ),
                ],
              ),
            ),
            if (state.battery != null) BatteryReading(pct: state.battery!),
          ],
        ),
      ),
    );
  }
}

// ─── Spinners ─────────────────────────────────────────────────────

/// Small inline spinner (16×16) used for the connecting trailing slot.
class _SmallSpinner extends StatefulWidget {
  const _SmallSpinner();

  @override
  State<_SmallSpinner> createState() => _SmallSpinnerState();
}

class _SmallSpinnerState extends State<_SmallSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: const SizedBox(
        width: 16,
        height: 16,
        child: RepaintBoundary(child: CustomPaint(painter: _ArcSpinner())),
      ),
    );
  }
}

class _ArcSpinner extends CustomPainter {
  const _ArcSpinner();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.width - 2) / 2;
    final Paint base = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, base);
    final Paint hi = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 3 / 4,
      math.pi / 2,
      false,
      hi,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcSpinner oldDelegate) => false;
}

/// Hero pulse used in the empty state — three concentric expanding
/// rings + a solid core. Same visual vocabulary as the IdentifyScreen
/// pulse so the "we're listening" idiom carries through the flow.
class _PulseSpinner extends StatefulWidget {
  const _PulseSpinner();

  @override
  State<_PulseSpinner> createState() => _PulseSpinnerState();
}

class _PulseSpinnerState extends State<_PulseSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) =>
            CustomPaint(painter: _PulsePainter(progress: _controller.value)),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  const _PulsePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    const double maxRadius = 56;
    const double minRadius = 18;

    for (int i = 0; i < 3; i++) {
      final double t = (progress + i / 3.0) % 1.0;
      final double radius = minRadius + (maxRadius - minRadius) * t;
      final double alpha = (1.0 - t).clamp(0.0, 1.0);
      final Paint ring = Paint()
        ..color = AppColors.accent.withValues(alpha: alpha * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius, ring);
    }

    canvas.drawCircle(center, minRadius, Paint()..color = AppColors.accent);
    canvas.drawCircle(
        center, minRadius - 4, Paint()..color = AppColors.bg);
    canvas.drawCircle(
        center, minRadius - 9, Paint()..color = AppColors.accent);
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─── Disconnect confirmation modal ────────────────────────────────

/// Modal route shown when the user taps a connected band, asking to
/// confirm before we drop the GATT connection. Returns `true` via
/// `Navigator.pop` for "Desconectar", `false` (or `null`) otherwise.
///
/// Visual pattern mirrors `PauseModalRoute` in the dashboard: opaque
/// false so the scan screen renders behind, soft fade + scale from 0.94.
class _ConfirmDisconnectRoute extends PageRouteBuilder<bool> {
  _ConfirmDisconnectRoute({required this.bandName})
      : super(
          opaque: false,
          barrierDismissible: false,
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          pageBuilder: (BuildContext context, _, __) =>
              _ConfirmDisconnectContent(bandName: bandName),
          transitionsBuilder: (
            BuildContext context,
            Animation<double> anim,
            Animation<double> secondary,
            Widget child,
          ) {
            final CurvedAnimation eased = CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: eased,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1).animate(eased),
                child: child,
              ),
            );
          },
        );

  // ignore: unused_element
  final String bandName;
}

class _ConfirmDisconnectContent extends StatelessWidget {
  const _ConfirmDisconnectContent({required this.bandName});

  final String bandName;

  static const double _backdropOpacity = 0.85;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: <Widget>[
          // Backdrop — tap outside the card cancels.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(false),
              child: Container(
                color: AppColors.bg.withValues(alpha: _backdropOpacity),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: S.s6),
            child: Center(
              // Absorb taps on the card so they don't bubble up to the
              // backdrop and dismiss the modal.
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(S.s6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(R.xl),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Desconectar banda',
                        style: AppText.title2,
                      ),
                      const SizedBox(height: S.s3),
                      Text(
                        '¿Quieres desconectar $bandName? Podrás volver a '
                        'conectarla cuando quieras.',
                        style:
                            AppText.body.copyWith(color: AppColors.text2),
                      ),
                      const SizedBox(height: S.s7),
                      ARCButton(
                        label: 'DESCONECTAR',
                        kind: ARCButtonKind.destructive,
                        full: true,
                        onTap: () => Navigator.of(context).pop(true),
                      ),
                      const SizedBox(height: 10),
                      ARCButton(
                        label: 'CANCELAR',
                        kind: ARCButtonKind.secondary,
                        full: true,
                        onTap: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
