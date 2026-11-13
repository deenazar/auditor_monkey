import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';

/// Two-part pill: "I have" / "I owe". Used for card accounts, where the
/// opening balance may be a debt. The selected part is `primaryDeep` with
/// `onDark` text. Each part is at least 44pt tall.
class OwesToggle extends StatelessWidget {
  const OwesToggle({required this.owes, required this.onChanged, super.key});

  /// True when the card is a debt ("I owe").
  final bool owes;

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.tile,
        borderRadius: AppRadius.pill,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _Part(
              label: 'I have',
              selected: !owes,
              onTap: () => onChanged(false),
            ),
            _Part(label: 'I owe', selected: owes, onTap: () => onChanged(true)),
          ],
        ),
      ),
    );
  }
}

class _Part extends StatelessWidget {
  const _Part({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
            duration: AppMotion.resolve(context, AppMotion.durationFast),
            curve: AppMotion.curveEnter,
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTapTarget,
              minWidth: AppSpacing.minTapTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryDeep : null,
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: selected ? AppColors.onDark : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
