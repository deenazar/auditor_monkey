import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// A stat tile (DESIGN.md "Stat tile"): `tile` background, `overline` label
/// centred at the top, then one chart or number centred below it.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    super.key,
  });

  /// Upper-case label text is written by the caller, e.g. "INCOME VS EXPENSE".
  final String label;

  final Widget child;

  /// Inner padding. Defaults to the card padding; compact rows use less.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.tile,
        borderRadius: AppRadius.card,
      ),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Scales down instead of wrapping when a tile is narrow.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            child,
          ],
        ),
      ),
    );
  }
}
