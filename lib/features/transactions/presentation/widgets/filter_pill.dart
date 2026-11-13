import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';

/// A selectable pill in the filter sheet (44 pt tall). Selected: [colour]
/// (or `ink`) fill with matching text; otherwise a white pill with a line.
class FilterPill extends StatelessWidget {
  const FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.colour,
    this.leading,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Fill when selected. `null` uses `ink`.
  final Color? colour;

  /// Optional small icon or dot before the label.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final Color fill = selected ? (colour ?? AppColors.ink) : AppColors.card;
    // White on `ink`; on a light account colour the text is `ink`.
    final Color text = !selected
        ? AppColors.ink
        : (colour != null && colour!.computeLuminance() > 0.5)
        ? AppColors.ink
        : AppColors.onDark;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.resolve(context, AppMotion.durationMedium),
          curve: AppMotion.curveEnter,
          constraints: const BoxConstraints(minHeight: AppSizes.chipHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AppRadius.pill,
            border: Border.all(
              color: selected ? fill : AppColors.line,
              width: AppSizes.fieldLineWidth / 2,
            ),
          ),
          child: Center(
            widthFactor: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  leading!,
                  const SizedBox(width: AppSpacing.space2),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStrong.copyWith(
                      fontSize: 13,
                      color: text,
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
