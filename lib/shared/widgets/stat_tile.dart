import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// A stat tile (DESIGN.md "Stat tile"): `tile` background, `overline` label
/// centred at the top, then one chart or number centred below it.
class StatTile extends StatelessWidget {
  const StatTile({required this.label, required this.child, super.key});

  /// Upper-case label text is written by the caller, e.g. "INCOME VS EXPENSE".
  final String label;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.tile,
        borderRadius: AppRadius.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.overline.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.space4),
            child,
          ],
        ),
      ),
    );
  }
}
