import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_shadows.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/rolling_amount.dart';
import '../../../../shared/wow/haptics.dart';
import '../../../../shared/wow/tilt_3d.dart';

/// The lime summary card that overlaps the hero (reference: "+12%
/// Spendings | VISA Main Card"): savings this month on the left, spent
/// this month on the right. Tilts in 3D under the finger, layered shadow.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    required this.savingsPercent,
    required this.monthSpent,
    this.onSpentTap,
    super.key,
  });

  /// Opens this month's spending (Transactions, filtered). Null = no tap.
  final VoidCallback? onSpentTap;

  final int? savingsPercent;
  final int monthSpent;

  @override
  Widget build(BuildContext context) {
    final String saved = savingsPercent == null
        ? '–'
        : '${savingsPercent! > 0 ? '+' : ''}$savingsPercent%';
    final TextStyle big = AppTextStyles.headline.copyWith(
      color: AppColors.accentText,
    );
    final TextStyle small = AppTextStyles.caption.copyWith(
      color: AppColors.accentText,
    );
    return Tilt3D(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.lime,
          borderRadius: AppRadius.card,
          boxShadow: AppShadows.shadowLayered,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.space5,
            horizontal: AppSpacing.space4,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Semantics(
                  label: 'Saved this month: $saved',
                  excludeSemantics: true,
                  child: Column(
                    children: <Widget>[
                      Text(saved, style: big),
                      const SizedBox(height: AppSpacing.space1),
                      Text('Saved', style: small),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Semantics(
                  button: onSpentTap != null,
                  hint: 'Shows this month\'s expenses',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onSpentTap == null
                        ? null
                        : () {
                            AppHaptics.tap();
                            onSpentTap!();
                          },
                    child: Column(
                      children: <Widget>[
                        RollingAmount.text(
                          paise: monthSpent,
                          style: big,
                          rollKey: 'home-month-spent',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.space1),
                        Text('Spent this month', style: small),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
