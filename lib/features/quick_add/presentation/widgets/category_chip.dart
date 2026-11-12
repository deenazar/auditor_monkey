import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/category_colours.dart';
import '../../../../shared/widgets/category_icon.dart';
import 'choice_pill.dart';
import 'quick_add_view_models.dart';

/// One category chip (DESIGN.md "Choice chip").
///
/// The leading circle is the group tint with an `ink` icon. Selected: the
/// chip is `primaryDeep` and the circle turns `background`. Use [CategoryChip.all]
/// for the "All" chip that opens the full list.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.name,
    required this.iconName,
    required this.colourGroup,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// Chip for a category view model.
  factory CategoryChip.fromData(
    CategoryChipData data, {
    required bool selected,
    required VoidCallback onTap,
    Key? key,
  }) => CategoryChip(
    key: key,
    name: data.name,
    iconName: data.icon,
    colourGroup: data.colourGroup,
    selected: selected,
    onTap: onTap,
  );

  /// The "All" chip: a neutral circle with the layout-grid icon.
  static Widget all({
    required bool selected,
    required VoidCallback onTap,
    Key? key,
  }) => ChoicePill(
    key: key,
    selected: selected,
    onTap: onTap,
    semanticsLabel: 'All categories',
    leadingBuilder: (bool sel) => ChipIconBadge(
      icon: LucideIcons.layoutGrid,
      fill: sel ? AppColors.background : categoryGroupTint(categoryGroupOther),
    ),
    child: const _Label('All'),
  );

  final String name;

  /// Lucide icon name in kebab case.
  final String iconName;

  /// Stored group name, e.g. `food`.
  final String colourGroup;

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoicePill(
      selected: selected,
      onTap: onTap,
      semanticsLabel: name,
      leadingBuilder: (bool sel) => ChipIconBadge(
        icon: categoryIconFor(iconName),
        fill: sel ? AppColors.background : categoryGroupTint(colourGroup),
      ),
      child: _Label(name),
    );
  }
}

/// Longest chip label before it is cut with an ellipsis (logical pixels).
const double _labelMaxWidth = 160;

/// Chip label: one line, cut with an ellipsis past 160 pt.
class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _labelMaxWidth),
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
