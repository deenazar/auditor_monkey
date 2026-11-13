import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/amount_text.dart';

/// The last row of a statement: "Opening balance" and the amount the
/// account started with. It has no date, because the opening balance is
/// not tied to one (see the setup notes).
class OpeningBalanceRow extends StatelessWidget {
  const OpeningBalanceRow({required this.openingPaise, super.key});

  /// Opening balance in paise (negative for a card debt).
  final int openingPaise;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Opening balance, ${_spoken(openingPaise)}',
      excludeSemantics: true,
      child: Row(
        children: <Widget>[
          const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.navIndicator,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: AppSizes.iconCircle,
              child: Icon(
                LucideIcons.wallet,
                size: AppSizes.iconInline,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Opening balance', style: AppTextStyles.bodyStrong),
                AmountText(paise: openingPaise, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _spoken(int paise) => paise < 0 ? 'owed' : 'starting amount';
}
