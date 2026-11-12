import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/account.dart';
import 'account_type_label.dart';

/// Account type choices as pill chips: cash, bank, card, wallet, PF, other.
///
/// The selected chip is `primaryDeep` with `onDark` text; the others are
/// `tile` with `ink` text. Each chip is at least 44pt tall.
class AccountTypeChips extends StatelessWidget {
  const AccountTypeChips({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final AccountType selected;
  final ValueChanged<AccountType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: <Widget>[
        for (final AccountType type in AccountType.values)
          _TypeChip(
            label: accountTypeLabel(type),
            selected: type == selected,
            onTap: () => onChanged(type),
          ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Duration duration = AppMotion.resolve(
      context,
      AppMotion.durationFast,
    );
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: duration,
            curve: AppMotion.curveEnter,
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTapTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space5),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryDeep : AppColors.tile,
              borderRadius: AppRadius.pill,
            ),
            child: Align(
              widthFactor: 1,
              child: Text(
                label,
                style:
                    (selected ? AppTextStyles.bodyStrong : AppTextStyles.body)
                        .copyWith(
                          color: selected ? AppColors.onDark : AppColors.ink,
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
