import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../accounts/presentation/widgets/account_colours.dart';
import '../../../accounts/presentation/widgets/account_type_label.dart';
import '../../application/setup_wizard_state.dart';

/// One account in the pick step (DESIGN "Selectable tile"). Selected: a
/// `navIndicator` fill and a `primaryDeep` check. Not selected: `tile`.
/// Tapping the tile toggles it; the pencil opens the edit sheet.
class AccountPickTile extends StatelessWidget {
  const AccountPickTile({
    required this.account,
    required this.onToggle,
    required this.onEdit,
    super.key,
  });

  final WizardAccount account;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final bool selected = account.selected;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? AppColors.navIndicator : AppColors.tile,
        borderRadius: AppRadius.card,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              label: account.name,
              hint: selected ? 'Selected' : 'Not selected',
              button: true,
              selected: selected,
              onTap: onToggle,
              excludeSemantics: true,
              child: InkWell(
                borderRadius: AppRadius.card,
                onTap: onToggle,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppSizes.iconCircle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    child: Row(
                      children: <Widget>[
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: accountColourFor(account.colour),
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox.square(
                            dimension: AppSizes.colourDot,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                account.name,
                                style: AppTextStyles.bodyStrong,
                              ),
                              Text(
                                accountTypeLabel(account.type),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(
                            LucideIcons.check,
                            size: AppSizes.iconInline,
                            color: AppColors.primaryDeep,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Edit ${account.name}',
            onPressed: onEdit,
            icon: const Icon(
              LucideIcons.pencil,
              size: AppSizes.iconInline,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
