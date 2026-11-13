import 'package:flutter/material.dart';

import '../../../../shared/theme/app_spacing.dart';
import 'category_chip.dart';
import 'quick_add_view_models.dart';

/// One horizontal row: the "All" chip first, then the category chips.
///
/// The caller orders [chips] (suggested first, at most six) and must include
/// the selected category even when it was picked from the full list. "All"
/// opens the full list through [onAll]; it is selected only when
/// [allSelected] is true.
class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({
    required this.chips,
    required this.selectedId,
    required this.onSelected,
    required this.onAll,
    this.allSelected = false,
    super.key,
  });

  final List<CategoryChipData> chips;

  /// Id of the selected category, or null when none is picked.
  final String? selectedId;

  final ValueChanged<String> onSelected;

  /// Called by the "All" chip.
  final VoidCallback onAll;

  final bool allSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: <Widget>[
          CategoryChip.all(selected: allSelected, onTap: onAll),
          for (final CategoryChipData chip in chips) ...<Widget>[
            const SizedBox(width: AppSpacing.space2),
            CategoryChip.fromData(
              chip,
              selected: chip.id == selectedId,
              onTap: () => onSelected(chip.id),
            ),
          ],
        ],
      ),
    );
  }
}
