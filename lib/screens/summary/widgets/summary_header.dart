// from: design/design_handoff_arc_app/design/screens/screens-post.jsx
//        (ScreenSummary header block)

import 'package:flutter/widgets.dart';

import '../../../models/session_summary.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/caption.dart';

class SummaryHeader extends StatelessWidget {
  const SummaryHeader({super.key, required this.summary});

  final SessionSummaryData summary;

  @override
  Widget build(BuildContext context) {
    final String mm = summary.totalDuration.inMinutes.toString().padLeft(2, '0');
    final String ss =
        (summary.totalDuration.inSeconds % 60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Caption(summary.dateLabel),
        const SizedBox(height: 6),
        const Text('Sesión completada', style: AppText.title2),
        const SizedBox(height: 12),
        DefaultTextStyle.merge(
          style: AppText.bodySm.copyWith(color: AppColors.text2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _Stat(value: '$mm:$ss', label: 'tiempo'),
              const _Sep(),
              _Stat(
                value: summary.distanceKm.toStringAsFixed(2),
                label: 'km',
              ),
              const _Sep(),
              _Stat(value: summary.avgPaceLabel, label: '/km'),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          value,
          style: AppText.bodySm.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9),
      child: Text(
        '·',
        style: AppText.bodySm.copyWith(color: AppColors.border),
      ),
    );
  }
}
