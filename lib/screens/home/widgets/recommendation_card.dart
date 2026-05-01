// from: design/design_handoff_arc_app/design/screens/screens-onboarding.jsx
//        (ScreenHomeA recommendation card — heavy variant with full cyan
//         border, accent stripe and 3 px ring shadow)

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/home_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/arc_card.dart';
import '../../../widgets/caption.dart';

class RecommendationCard extends ConsumerWidget {
  const RecommendationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String text = ref.watch(recommendationProvider);

    return ARCCard(
      accent: true,
      borderColor: AppColors.accent,
      ringShadow: true,
      padding: const EdgeInsets.all(S.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Caption('Recomendación · histórico', color: AppColors.accent),
          const SizedBox(height: S.s2),
          Text(text, style: AppText.body),
        ],
      ),
    );
  }
}
