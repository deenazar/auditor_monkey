import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass.dart';

/// mini_checklist `.chip`: glass, a mono value over a small caps label.
class StatChip extends StatelessWidget {
  const StatChip({
    required this.value,
    required this.label,
    this.valueColour = AppColors.glassInk,
    super.key,
  });

  final String value;
  final String label;
  final Color valueColour;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Glass(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              value,
              maxLines: 1,
              style: AppTextStyles.amount.copyWith(color: valueColour),
            ),
            Text(
              label.toUpperCase(),
              maxLines: 1,
              style: AppTextStyles.overline.copyWith(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.glassInk.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
