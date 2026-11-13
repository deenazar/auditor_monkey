import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/category_colours.dart';
import 'category_icon.dart';

/// A round badge with a category's outline icon (DESIGN.md "List row").
///
/// The fill is the group tint (20% of the group colour) unless [fill] is
/// given, e.g. `AppColors.background` on a selected chip. The icon is `ink`.
/// Decorative: the row or chip that holds it carries the label.
class CategoryIconCircle extends StatelessWidget {
  const CategoryIconCircle({
    required this.iconName,
    required this.colourGroup,
    this.size = AppSizes.iconCircle,
    this.iconSize = AppSizes.iconInline,
    this.fill,
    super.key,
  });

  /// Lucide icon name in kebab case, e.g. `shopping-cart`.
  final String iconName;

  /// Stored group name, e.g. `food`. Unknown names use the `other` tint.
  final String colourGroup;

  /// Diameter. Use `chipIconCircle` inside chips, `iconCircle` in rows.
  final double size;

  /// Icon size (`iconInline` by default, `iconChip` inside chips).
  final double iconSize;

  /// Overrides the group tint.
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill ?? categoryGroupTint(colourGroup),
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: Icon(
              categoryIconFor(iconName),
              size: iconSize,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
