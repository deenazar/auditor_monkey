import 'package:flutter/material.dart';

import '../../../../core/money/money.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/amount_text.dart';
import 'account_colours.dart';

/// A compact account row for the "All accounts" list: a colour dot, the
/// name in `bodyStrong`, and the balance on the right. The whole row is
/// the tap target (at least 44pt tall) and opens the statement.
class AccountListRow extends StatelessWidget {
  const AccountListRow({
    required this.name,
    required this.colourToken,
    required this.balancePaise,
    required this.onTap,
    super.key,
  });

  final String name;
  final String colourToken;
  final int balancePaise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$name, balance ${formatPaise(balancePaise)}',
      button: true,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
          child: Row(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accountColourFor(colourToken),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: AppSizes.colourDot),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Flexible(
                flex: 0,
                child: AmountText(
                  paise: balancePaise,
                  style: AppTextStyles.bodyStrong,
                  alignment: AlignmentDirectional.centerEnd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
