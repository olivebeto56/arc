// Reusable empty-state placeholder. Used by History when the period filter
// excludes everything; will be reused by Settings (no bands) and by future
// screens that need a "nothing here yet" affordance.

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'arc_button.dart';
import 'caption.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.caption,
    required this.body,
    this.cta,
    this.onCta,
  });

  final String caption;
  final String body;
  final String? cta;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Caption(caption),
            const SizedBox(height: S.s3),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: AppColors.text2),
            ),
            if (cta != null && onCta != null) ...<Widget>[
              const SizedBox(height: S.s5),
              ARCButton(label: cta!, onTap: onCta),
            ],
          ],
        ),
      ),
    );
  }
}
