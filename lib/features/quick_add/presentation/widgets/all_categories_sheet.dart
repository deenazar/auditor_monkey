import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/category_colours.dart';
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../../../shared/wow/wow_sheet.dart';
import 'category_chip.dart';
import 'quick_add_view_models.dart';

/// The full category list (DESIGN.md P2). Sections per colour group, in
/// group order, each a wrap of chips under an `overline` heading. Empty
/// groups are left out. Tapping a chip returns its id from [show].
class AllCategoriesSheet extends StatelessWidget {
  const AllCategoriesSheet({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  /// Opens the sheet and returns the picked category id, or null when it is
  /// closed without a pick. Uses `durationMedium` / `curveEnter`.
  static Future<String?> show(
    BuildContext context, {
    required List<CategoryChipData> categories,
    required String? selectedId,
  }) {
    return showWowSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      animationStyle: wowSheetAnimation(context),
      builder: (BuildContext sheetContext) => AllCategoriesSheet(
        categories: categories,
        selectedId: selectedId,
        onSelected: (String id) => Navigator.of(sheetContext).pop(id),
      ),
    );
  }

  final List<CategoryChipData> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  /// Groups that are not in the known list show under `other`.
  static String _groupOf(String group) =>
      categoryGroupOrder.contains(group) ? group : categoryGroupOther;

  @override
  Widget build(BuildContext context) {
    final List<Widget> sections = <Widget>[];
    for (final String group in categoryGroupOrder) {
      final List<CategoryChipData> inGroup = <CategoryChipData>[
        for (final CategoryChipData c in categories)
          if (_groupOf(c.colourGroup) == group) c,
      ];
      if (inGroup.isEmpty) continue;
      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: AppSpacing.space6));
      }
      // Groups enter one after another (Motion & 3D).
      sections.add(
        StaggeredEntrance(
          index: sections.length ~/ 2,
          child: _Section(
            group: group,
            chips: inGroup,
            selectedId: selectedId,
            onSelected: onSelected,
          ),
        ),
      );
    }

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
            child: const Text('Categories', style: AppTextStyles.title),
          ),
          const SizedBox(height: AppSpacing.space6),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sections,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.group,
    required this.chips,
    required this.selectedId,
    required this.onSelected,
  });

  final String group;
  final List<CategoryChipData> chips;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final String heading = group.toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(heading, style: AppTextStyles.overline),
        ),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: <Widget>[
            for (final CategoryChipData chip in chips)
              CategoryChip.fromData(
                chip,
                selected: chip.id == selectedId,
                onTap: () => onSelected(chip.id),
              ),
          ],
        ),
      ],
    );
  }
}
