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
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../../../shared/wow/haptics.dart';
import '../../../../shared/wow/tilt_3d.dart';
import '../../../../shared/wow/wow_sheet.dart';
import '../../../accounts/presentation/widgets/account_colours.dart';
import 'quick_add_view_models.dart';

/// "Pick account" sheet (DESIGN.md P1). One row per account: colour dot,
/// name, balance under it, and a `primaryDeep` check on the selected one.
/// [disabledId] (in the To picker, the From account) is shown but cannot be
/// picked. [show] returns the picked id, or null when closed.
class AccountPickerSheet extends StatelessWidget {
  const AccountPickerSheet({
    required this.title,
    required this.accounts,
    required this.selectedId,
    required this.onSelected,
    this.disabledId,
    super.key,
  });

  /// Opens the sheet (`durationMedium` / `curveEnter`) and returns the
  /// picked account id.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<AccountOption> accounts,
    required String? selectedId,
    String? disabledId,
  }) {
    return showWowSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      animationStyle: wowSheetAnimation(context),
      builder: (BuildContext sheetContext) => AccountPickerSheet(
        title: title,
        accounts: accounts,
        selectedId: selectedId,
        disabledId: disabledId,
        onSelected: (String id) => Navigator.of(sheetContext).pop(id),
      ),
    );
  }

  final String title;
  final List<AccountOption> accounts;
  final String? selectedId;
  final String? disabledId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space6,
        AppSpacing.screenPadding,
        AppSpacing.space6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(title, style: AppTextStyles.title),
          ),
          const SizedBox(height: AppSpacing.space4),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (int i = 0; i < accounts.length; i++) ...<Widget>[
                    StaggeredEntrance(
                      index: i,
                      child: Tilt3D(
                        maxDegrees: 4,
                        haptic: false,
                        child: _AccountRow(
                          account: accounts[i],
                          selected: accounts[i].id == selectedId,
                          disabled: accounts[i].id == disabledId,
                          onTap: () => onSelected(accounts[i].id),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.listRowGap),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final AccountOption account;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color nameColour = disabled ? AppColors.iconInactive : AppColors.ink;
    return Semantics(
      button: true,
      selected: selected,
      enabled: !disabled,
      label: account.balancePaise == null
          ? account.name
          : '${account.name}, balance ${formatPaise(account.balancePaise!)}',
      excludeSemantics: true,
      onTap: disabled ? null : onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled
            ? null
            : () {
                AppHaptics.tap();
                onTap();
              },
        child: AnimatedContainer(
          duration: AppMotion.resolve(context, AppMotion.durationFast),
          curve: AppMotion.curveEnter,
          constraints: const BoxConstraints(minHeight: AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space2,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.navIndicator : AppColors.tile,
            borderRadius: AppRadius.card,
          ),
          child: Row(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accountColourFor(account.colourToken),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: AppSizes.colourDot),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: nameColour,
                      ),
                    ),
                    if (account.balancePaise != null)
                      AmountText(
                        paise: account.balancePaise!,
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
    );
  }
}
