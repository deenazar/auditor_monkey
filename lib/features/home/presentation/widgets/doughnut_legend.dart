import 'package:flutter/material.dart';

import '../../../../core/money/money.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/wow/spring_press.dart';
import '../../../accounts/presentation/widgets/account_colours.dart';
import '../../domain/balance_slices.dart';

/// The colour of one doughnut slice: the account's colour, or `iconInactive`
/// for "Other".
Color sliceColour(BalanceSlice slice) => slice.colourToken == null
    ? AppColors.iconInactive
    : accountColourFor(slice.colourToken!);

/// The legend under the doughnut: one row per slice with a dot, the name,
/// the amount and the percent. Tapping a row selects that slice (the same
/// as tapping the ring). Rows are at least 44pt tall.
///
/// Each row reads as one label, e.g. "PF, ₹1,00,000.00, 50%".
class DoughnutLegend extends StatelessWidget {
  const DoughnutLegend({
    required this.slices,
    required this.selectedIndex,
    required this.onSelect,
    super.key,
  });

  final List<BalanceSlice> slices;

  /// Index of the selected slice in [slices], or null.
  final int? selectedIndex;

  /// Called with the index of the tapped row.
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < slices.length; i++)
          _LegendRow(
            slice: slices[i],
            selected: selectedIndex == i,
            onTap: () => onSelect(i),
          ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.slice,
    required this.selected,
    required this.onTap,
  });

  final BalanceSlice slice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String label =
        '${slice.label}, ${formatPaise(slice.amount)}, ${slice.percentLabel}';
    return SpringPress(
      onTap: onTap,
      semanticLabel: label,
      selected: selected,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.navIndicator : null,
          borderRadius: AppRadius.pill,
        ),
        child: ExcludeSemantics(
          child: Row(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: sliceColour(slice),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: 12),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  slice.label,
                  style: AppTextStyles.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatPaise(slice.amount),
                    style: AppTextStyles.bodyStrong,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              SizedBox(
                width: 44,
                child: Text(
                  slice.percentLabel,
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
