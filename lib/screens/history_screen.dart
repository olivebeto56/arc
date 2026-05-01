// from: design/design_handoff_arc_app/design/screens/screens-post.jsx
//        (ScreenHistory)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/history_period.dart';
import '../models/session_summary.dart';
import '../providers/history_provider.dart';
import '../providers/session_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../widgets/arc_icons.dart';
import '../widgets/arc_top_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/segmented.dart';
import 'history/widgets/aggregate_stats_strip.dart';
import 'history/widgets/session_row.dart';
import 'summary_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  /// Opens [SummaryScreen] in read-only "historical" mode, with the global
  /// `sessionSummaryProvider` overridden so the screen renders the tapped
  /// entry instead of the live post-session mock.
  void _openSummary(BuildContext context, SessionSummaryData entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProviderScope(
          overrides: <Override>[
            sessionSummaryProvider.overrideWith(
              (Ref ref) => entry,
            ),
          ],
          child: const SummaryScreen(isHistorical: true),
        ),
      ),
    );
  }

  // JSX literal — between-scale.
  static const double _statusBarReserve = 56;
  static const double _topPadV = S.s2;
  static const double _topPadH = S.s5;
  static const double _topPadBottom = S.s4;
  static const double _afterSegmented = S.s4;
  static const double _listPadH = S.s5;
  static const double _listPadBottom = S.s5;
  static const double _rowGap = S.s2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HistoryPeriod period = ref.watch(selectedPeriodProvider);
    final List<SessionSummaryData> entries = ref.watch(filteredHistoryProvider);

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
                'Historial',
                style: AppText.body.copyWith(fontWeight: FontWeight.w500),
              ),
              right: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // TODO(arc): wire to a search field when the dataset grows.
                onTap: () {},
                child: ArcIcons.search(size: 20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _topPadH,
                _topPadV,
                _topPadH,
                _topPadBottom,
              ),
              child: Column(
                children: <Widget>[
                  Segmented<HistoryPeriod>(
                    value: period,
                    options: const <SegmentedOption<HistoryPeriod>>[
                      SegmentedOption<HistoryPeriod>(
                        value: HistoryPeriod.week,
                        label: 'Semana',
                      ),
                      SegmentedOption<HistoryPeriod>(
                        value: HistoryPeriod.month,
                        label: 'Mes',
                      ),
                      SegmentedOption<HistoryPeriod>(
                        value: HistoryPeriod.all,
                        label: 'Todo',
                      ),
                    ],
                    onChanged: (HistoryPeriod v) =>
                        ref.read(selectedPeriodProvider.notifier).state = v,
                  ),
                  const SizedBox(height: _afterSegmented),
                  const AggregateStatsStrip(),
                ],
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? const _Empty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        _listPadH,
                        0,
                        _listPadH,
                        _listPadBottom,
                      ),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: _rowGap),
                      itemBuilder: (BuildContext context, int i) {
                        final SessionSummaryData entry = entries[i];
                        return SessionRow(
                          summary: entry,
                          onTap: () => _openSummary(context, entry),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(S.s6),
      child: EmptyState(
        caption: 'Sin sesiones aún',
        body: 'Cuando termines tu primera sesión aparecerá aquí. '
            'Cambia el filtro para ver entradas de otros periodos.',
      ),
    );
  }
}
