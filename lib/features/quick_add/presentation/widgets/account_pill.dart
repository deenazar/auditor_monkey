import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/money/money.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../../accounts/presentation/widgets/account_colours.dart';
import 'press_surface.dart';
import 'quick_add_view_models.dart';

/// An account chosen in Quick Add: a `tile` pill with the account's colour
/// dot and name, a `chevron-down` (or, with [showBalance], the balance under
/// the name). Tall enough for the 44 tap target; grows with text scale.
///
/// [account] null shows [placeholder] (no account picked yet).
class AccountPill extends StatelessWidget {
  const AccountPill({
    required this.account,
    required this.onTap,
    this.placeholder = 'Pick account',
    this.showBalance = false,
    this.showChevron = true,
    super.key,
  });

  final AccountOption? account;
  final VoidCallback onTap;
  final String placeholder;

  /// Shows the balance under the name (transfer pills).
  final bool showBalance;

  /// Shows `chevron-down` at the end (expense and income).
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final AccountOption? a = account;
    final String spoken = a == null
        ? placeholder
        : showBalance && a.balancePaise != null
        ? '${a.name}, balance ${formatPaise(a.balancePaise!)}'
        : a.name;
    return Semantics(
      button: true,
      label: spoken,
      excludeSemantics: true,
      onTap: onTap,
      child: PressSurface(
        onTap: onTap,
        builder: (BuildContext context, bool pressed) {
          return AnimatedContainer(
            duration: AppMotion.resolve(context, AppMotion.durationFast),
            curve: AppMotion.curveEnter,
            constraints: const BoxConstraints(minHeight: AppSizes.chipHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space2,
            ),
            decoration: const BoxDecoration(
              color: AppColors.tile,
              borderRadius: AppRadius.pill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (a != null) ...<Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: accountColourFor(a.colourToken),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: AppSizes.colourDot),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                ],
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        a?.name ?? placeholder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: a == null
                            ? AppTextStyles.body.copyWith(
                                color: AppColors.inkMuted,
                              )
                            : AppTextStyles.bodyStrong,
                      ),
                      if (showBalance && a != null && a.balancePaise != null)
                        AmountText(
                          paise: a.balancePaise!,
                          style: AppTextStyles.caption,
                        ),
                    ],
                  ),
                ),
                if (showChevron) ...<Widget>[
                  const SizedBox(width: AppSpacing.space2),
                  const Icon(
                    LucideIcons.chevronDown,
                    size: AppSizes.iconChip,
                    color: AppColors.ink,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
