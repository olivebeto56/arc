// from: design/design_handoff_arc_app/design/screens/screens-post.jsx
//        (ScreenSummary)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session_summary.dart';
import '../providers/history_provider.dart';
import '../providers/session_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../widgets/arc_button.dart';
import '../widgets/arc_icons.dart';
import '../widgets/arc_top_bar.dart';
import '../widgets/caption.dart';
import '../widgets/route_map_placeholder.dart';
import 'home_screen.dart';
import 'summary/widgets/cadence_chart.dart';
import 'summary/widgets/score_card.dart';
import 'summary/widgets/summary_header.dart';
import 'summary/widgets/symmetry_bar.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  // JSX literal — between-scale.
  static const double _statusBarReserve = 56;
  static const double _bodyHPadding = S.s5;
  static const double _bodyTopPadding = S.s2;
  static const double _bodyBottomPadding = S.s5;
  static const double _afterHeader = S.s5;
  static const double _afterCard = S.s3;
  static const double _afterTrioGrid = S.s4;
  static const double _trioGap = S.s2;
  static const double _footerHPadding = S.s5;
  static const double _footerTopPadding = S.s3;
  static const double _footerBottomPadding = 38;
  static const double _footerGap = 10;

  void _onShare() {
    // TODO(arc): wire to share_plus once a Summary share-sheet asset exists.
  }

  void _onDone(BuildContext context, WidgetRef ref) {
    final SessionSummaryData summary = ref.read(sessionSummaryProvider);
    ref.read(sessionHistoryProvider.notifier).save(summary);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SessionSummaryData summary = ref.watch(sessionSummaryProvider);

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
                // TODO(arc): replace with proper back navigation once the
                // post-session route stack supports it.
                onTap: () => _onDone(context, ref),
                child: ArcIcons.chevL(size: 22),
              ),
              right: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onShare,
                child: ArcIcons.share(size: 20),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SummaryHeader(summary: summary),
                    const SizedBox(height: _afterHeader),
                    ScoreCard(summary: summary),
                    const SizedBox(height: _afterCard),
                    const RouteMapPlaceholder(),
                    const SizedBox(height: _afterCard),
                    CadenceChart(summary: summary),
                    const SizedBox(height: _afterCard),
                    SymmetryBar(summary: summary),
                    const SizedBox(height: _afterCard),
                    _TrioGrid(summary: summary),
                    const SizedBox(height: _afterTrioGrid),
                    _NextSession(recommendations: summary.recommendations),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _footerHPadding,
                _footerTopPadding,
                _footerHPadding,
                _footerBottomPadding,
              ),
              child: Row(
                children: <Widget>[
                  // JSX forces width 110 here, but with lg padding it doesn't
                  // fit "COMPARTIR" + share icon. Letting it size to content
                  // keeps the visual hierarchy without overflow.
                  ARCButton(
                    label: 'COMPARTIR',
                    kind: ARCButtonKind.ghost,
                    icon: ArcIcons.share(size: 16, color: AppColors.text),
                    onTap: _onShare,
                  ),
                  const SizedBox(width: _footerGap),
                  Expanded(
                    child: ARCButton(
                      label: 'LISTO',
                      full: true,
                      onTap: () => _onDone(context, ref),
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

  static const double _trioGapRef = _trioGap;
}

class _TrioGrid extends StatelessWidget {
  const _TrioGrid({required this.summary});

  final SessionSummaryData summary;

  @override
  Widget build(BuildContext context) {
    final List<_TrioItem> items = <_TrioItem>[
      _TrioItem(
        value: '${summary.gctAvgMs}',
        unit: 'ms',
        label: 'GCT avg',
      ),
      _TrioItem(
        value: summary.peakImpact.toStringAsFixed(1),
        unit: 'm/s²',
        label: 'Impacto pico',
      ),
      _TrioItem(
        value: summary.variability.toStringAsFixed(1),
        unit: '%',
        label: 'Variabilidad',
      ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: SummaryScreen._trioGapRef),
          Expanded(child: _TrioCard(item: items[i])),
        ],
      ],
    );
  }
}

class _TrioItem {
  const _TrioItem({
    required this.value,
    required this.unit,
    required this.label,
  });
  final String value;
  final String unit;
  final String label;
}

class _TrioCard extends StatelessWidget {
  const _TrioCard({required this.item});

  final _TrioItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(S.s3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(R.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Caption(item.label),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                item.value,
                style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 3),
              Text(
                item.unit,
                style: AppText.bodyXs.copyWith(color: AppColors.text3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextSession extends StatelessWidget {
  const _NextSession({required this.recommendations});

  final List<String> recommendations;

  // JSX literal — between-scale.
  static const double _badgeSize = 22;
  static const double _rowGap = 12;
  static const double _itemGap = 6;
  static const double _itemPaddingV = 12;
  static const double _itemPaddingH = 14;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Caption('Próxima sesión', color: AppColors.text2),
        const SizedBox(height: S.s3),
        for (int i = 0; i < recommendations.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: _itemGap),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: _itemPaddingH,
              vertical: _itemPaddingV,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: _badgeSize,
                  height: _badgeSize,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.accentDim,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: AppText.bodyXs.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: _rowGap),
                Expanded(
                  child: Text(
                    recommendations[i],
                    style: AppText.bodySm.copyWith(color: AppColors.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
