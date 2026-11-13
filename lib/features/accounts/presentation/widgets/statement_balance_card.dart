import 'package:flutter/material.dart';

import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../../../shared/widgets/rolling_amount.dart';
import 'account_colours.dart';

/// The balance card at the top of a statement: the account colour, the
/// `overline` "BALANCE" and the balance in `displayAmount`. Flat, no shadow.
class StatementBalanceCard extends StatelessWidget {
  const StatementBalanceCard({
    required this.colourToken,
    required this.balancePaise,
    this.rollKey,
    super.key,
  });

  final String colourToken;

  /// Current balance in paise (negative shows `-₹`).
  final int balancePaise;

  /// Lets the balance roll from 0 once per launch (see `RollingAmount`).
  final String? rollKey;

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
            RollingAmount(
              paise: balancePaise,
              rollKey: rollKey,
              builder: (BuildContext context, int value) => AmountText(
                paise: value,
                style: AppTextStyles.displayAmount,
                color: text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
