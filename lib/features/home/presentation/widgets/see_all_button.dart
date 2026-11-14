import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/wow/spring_press.dart';

/// The "See all" text button under a Home section. Springy on touch, with a
/// haptic, and at least 44pt tall and wide.
class SeeAllButton extends StatelessWidget {
  const SeeAllButton({required this.onTap, this.label = 'See all', super.key});

  final VoidCallback onTap;

  /// The visible text. Also the screen reader label.
  final String label;

  @override
  Widget build(BuildContext context) {
    return SpringPress(
      onTap: onTap,
      semanticLabel: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppSpacing.minTapTarget,
          minHeight: AppSpacing.minTapTarget,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
          child: Center(
            widthFactor: 1,
            child: ExcludeSemantics(
              child: Text(
                label,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.accentText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
