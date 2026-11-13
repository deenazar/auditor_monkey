import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import 'press_surface.dart';

/// A pill chip used across Quick Add (categories, recent, date, note).
///
/// Not selected: `tile` fill, `ink` label. Selected: `primaryDeep` fill and
/// `onDark` label. Height is `chipHeight` (the 44 tap target). The fill
/// changes with `durationFast` and `curveEnter`.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    required this.child,
    required this.selected,
    this.onTap,
    this.semanticsLabel,
    this.leadingBuilder,
    this.enabled = true,
    super.key,
  });

  /// The label (usually a [Text] or an amount).
  final Widget child;

  final bool selected;
  final VoidCallback? onTap;

  /// Read by screen readers instead of the visible text.
  final String? semanticsLabel;

  /// Leading badge. Gets the selected flag so it can change its fill.
  final Widget Function(bool selected)? leadingBuilder;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Widget? leading = leadingBuilder?.call(selected);
    final Color labelColour = selected ? AppColors.onDark : AppColors.ink;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled && onTap != null,
      label: semanticsLabel,
      excludeSemantics: semanticsLabel != null,
      onTap: enabled ? onTap : null,
      child: PressSurface(
        enabled: enabled,
        onTap: onTap,
        builder: (BuildContext context, bool pressed) {
          return AnimatedContainer(
            duration: AppMotion.resolve(context, AppMotion.durationFast),
            curve: AppMotion.curveEnter,
            height: AppSizes.chipHeight,
            padding: EdgeInsetsDirectional.only(
              start: leading == null ? AppSpacing.space4 : AppSpacing.space1,
              end: AppSpacing.space4,
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryDeep : AppColors.tile,
              borderRadius: AppRadius.pill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  leading,
                  const SizedBox(width: AppSpacing.space2),
                ],
                Flexible(
                  child: DefaultTextStyle.merge(
                    style: AppTextStyles.body.copyWith(color: labelColour),
                    child: child,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The leading circle of a chip (`chipIconCircle`, icon `iconChip`).
class ChipIconBadge extends StatelessWidget {
  const ChipIconBadge({required this.icon, required this.fill, super.key});

  final IconData icon;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: SizedBox.square(
        dimension: AppSizes.chipIconCircle,
        child: Center(
          child: Icon(icon, size: AppSizes.iconChip, color: AppColors.ink),
        ),
      ),
    );
  }
}
