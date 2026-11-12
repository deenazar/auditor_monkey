import 'package:flutter/material.dart';

import '../../../../core/money/money.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../domain/account.dart';
import 'account_colours.dart';
import 'account_type_label.dart';

/// An account card in its own colour (DESIGN.md Accounts pattern).
///
/// Left: a side-tab in `primaryDeep` with the account name written
/// vertically in `onDark`. On a PF card (the tab would match the card) the
/// tab is `ink` instead. Right: type in `overline`, the balance in
/// `displayAmount` and "Opening ₹…" in `caption`.
///
/// Takes plain values, not database rows, so it can be tested and reused.
/// The width comes from the parent; the height is `accountCardHeight`.
class AccountCard extends StatelessWidget {
  const AccountCard({
    required this.name,
    required this.type,
    required this.colourToken,
    required this.balancePaise,
    required this.openingPaise,
    this.archived = false,
    this.onTap,
    super.key,
  });

  final String name;
  final AccountType type;

  /// Colour token name as stored, e.g. `accountSbi`.
  final String colourToken;

  /// Current balance in paise (can be negative for a card).
  final int balancePaise;

  /// Opening balance in paise.
  final int openingPaise;

  final bool archived;

  /// Called when the card is tapped. Null makes the card non-interactive.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = accountColourFor(colourToken);
    final Color text = accountTextColourFor(colourToken);
    final Color tab = background == AppColors.primaryDeep
        ? AppColors.ink
        : AppColors.primaryDeep;
    final String typeLabel = accountTypeLabel(type);
    final String balance = formatPaise(balancePaise);
    final String opening = formatPaise(openingPaise);

    final String overlineText = archived
        ? '${typeLabel.toUpperCase()} · ARCHIVED'
        : typeLabel.toUpperCase();

    return Semantics(
      label:
          '$name, $typeLabel, balance $balance, opening $opening'
          '${archived ? ', archived' : ''}',
      button: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: AppSizes.accountCardHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  width: AppSizes.accountSideTabWidth,
                  child: ColoredBox(
                    color: tab,
                    child: _VerticalName(name: name),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          overlineText,
                          style: AppTextStyles.overline.copyWith(color: text),
                        ),
                        Expanded(
                          child: AmountText(
                            paise: balancePaise,
                            style: AppTextStyles.displayAmount,
                            color: text,
                            alignment: AlignmentDirectional.bottomStart,
                          ),
                        ),
                        Text(
                          'Opening $opening',
                          style: AppTextStyles.caption.copyWith(color: text),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The account name, rotated to read bottom to top. It shrinks to fit the
/// tab, so long names and large text stay inside the tab.
class _VerticalName extends StatelessWidget {
  const _VerticalName({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          name,
          style: AppTextStyles.bodyStrong.copyWith(color: AppColors.onDark),
        ),
      ),
    );
  }
}
