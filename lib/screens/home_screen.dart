// from: design/design_handoff_arc_app/design/screens/screens-onboarding.jsx
//        (ScreenHomeA — Home variant A "atlético / energético")

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/home_stats.dart';
import '../providers/home_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../widgets/arc_button.dart';
import '../widgets/arc_icons.dart';
import '../widgets/arc_logo.dart';
import '../widgets/arc_top_bar.dart';
import '../widgets/caption.dart';
import '../widgets/segmented.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'home/widgets/averages_card.dart';
import 'home/widgets/bands_card.dart';
import 'home/widgets/recommendation_card.dart';
import 'home/widgets/stats_strip.dart';
import 'settings_screen.dart';

enum _SessionType { libre, tiempo, distancia }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // JSX literal — between-scale.
  static const double _statusBarReserve = 56;
  static const double _bodyHPadding = S.s5;
  static const double _bodyTop = S.s2;
  static const double _bodyBottom = S.s5;
  static const double _greetingMarginBottom = 22;
  static const double _statsMarginBottom = 18;
  static const double _afterAverages = 12;
  static const double _afterRecommendation = 12;
  static const double _afterBands = 14;
  static const double _greetingDateToTitle = 6;
  static const double _footerTop = S.s3;
  static const double _footerBottom = 38;
  static const double _footerHGap = 10;

  // Local state — purely visual; no downstream consumer yet.
  // TODO(arc): wire to a session goal modal once DashboardScreen exists.
  _SessionType _sessionType = _SessionType.libre;

  void _goSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  void _goHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
    );
  }

  void _startSession() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final HomeStats stats = ref.watch(homeStatsProvider);
    final String userName = ref.watch(userNameProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: <Widget>[
            const SizedBox(height: _statusBarReserve),
            ARCTopBar(
              left: const ARCLogo(height: 18),
              right: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _goSettings,
                child: ArcIcons.settings(size: 22),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  _bodyHPadding,
                  _bodyTop,
                  _bodyHPadding,
                  _bodyBottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _Greeting(
                      date: stats.greetingDate,
                      userName: userName,
                    ),
                    const SizedBox(height: _greetingMarginBottom),
                    const StatsStrip(),
                    const SizedBox(height: _statsMarginBottom),
                    const AveragesCard(),
                    const SizedBox(height: _afterAverages),
                    const RecommendationCard(),
                    const SizedBox(height: _afterRecommendation),
                    const BandsCard(),
                    const SizedBox(height: _afterBands),
                    Segmented<_SessionType>(
                      value: _sessionType,
                      options: const <SegmentedOption<_SessionType>>[
                        SegmentedOption<_SessionType>(
                          value: _SessionType.libre,
                          label: 'Libre',
                        ),
                        SegmentedOption<_SessionType>(
                          value: _SessionType.tiempo,
                          label: 'Tiempo',
                        ),
                        SegmentedOption<_SessionType>(
                          value: _SessionType.distancia,
                          label: 'Distancia',
                        ),
                      ],
                      onChanged: (_SessionType v) =>
                          setState(() => _sessionType = v),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _bodyHPadding,
                _footerTop,
                _bodyHPadding,
                _footerBottom,
              ),
              child: Row(
                children: <Widget>[
                  // JSX forces width 100 on HISTORIAL but the lg button can't
                  // fit the label in 52 px of inner width — letting it size
                  // to content keeps the visual hierarchy without overflow.
                  ARCButton(
                    label: 'HISTORIAL',
                    kind: ARCButtonKind.secondary,
                    onTap: _goHistory,
                  ),
                  const SizedBox(width: _footerHGap),
                  Expanded(
                    child: ARCButton(
                      label: 'INICIAR SESIÓN',
                      glow: true,
                      full: true,
                      onTap: _startSession,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.date, required this.userName});

  final String date;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Caption(date),
        const SizedBox(height: _HomeScreenState._greetingDateToTitle),
        Text(
          'Hola, $userName',
          style: AppText.title.copyWith(height: 1.1),
        ),
      ],
    );
  }
}
