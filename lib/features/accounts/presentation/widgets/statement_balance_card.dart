import 'package:flutter/material.dart';

import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/amount_text.dart';
import 'account_colours.dart';

/// The balance card at the top of a statement: the account colour, the
/// `overline` "BALANCE" and the balance in `displayAmount`. Flat, no shadow.
class StatementBalanceCard extends StatelessWidget {
  const StatementBalanceCard({
    required this.colourToken,
    required this.balancePaise,
    super.key,
  });

  final String colourToken;

  /// Current balance in paise (negative shows `-₹`).
  final int balancePaise;

  @override
  Widget build(BuildContext context) {
    final Color text = accountTextColourFor(colourToken);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accountColourFor(colourToken),
        borderRadius: AppRadius.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'BALANCE',
              style: AppTextStyles.overline.copyWith(color: text),
            ),
            const SizedBox(height: AppSpacing.space2),
            AmountText(
              paise: balancePaise,
              style: AppTextStyles.displayAmount,
              color: text,
            ),
          ],
        ),
      ),
    );
  }
}
