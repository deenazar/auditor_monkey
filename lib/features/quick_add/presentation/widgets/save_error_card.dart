import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/wow/shake_in.dart';

/// Card above Save when saving failed (DESIGN.md Q10): a `danger` warning
/// icon and the message. The card fades in with `durationFast`. It is a live
/// region, so screen readers announce it. [message] should be a sentence a
/// person can act on, never raw error text.
class SaveErrorCard extends StatelessWidget {
  const SaveErrorCard({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ShakeIn(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: AppMotion.resolve(context, AppMotion.durationFast),
        builder: (BuildContext context, double opacity, Widget? child) =>
            Opacity(opacity: opacity, child: child),
        child: Semantics(
          liveRegion: true,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.tile,
              borderRadius: AppRadius.card,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    LucideIcons.triangleAlert,
                    size: AppSizes.iconInline,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(child: Text(message, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
