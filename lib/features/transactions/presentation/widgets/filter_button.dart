import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass.dart';
import '../../application/transactions_list_providers.dart';
import '../../domain/transaction_filter.dart';
import '../filter_sheet.dart';

/// The filter button: a card square with an active-facet count badge. Opens
/// the filter sheet.
class TransactionsFilterButton extends ConsumerWidget {
  const TransactionsFilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count = ref.watch(
      transactionFilterProvider.select((TransactionFilter f) => f.facetCount),
    );
    return PressScale(
      semanticLabel: count == 0 ? 'Filters' : 'Filters, $count active',
      onTap: () => showTransactionFilterSheet(context),
      child: SizedBox.square(
        dimension: AppSpacing.minTapTarget + 4,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.field,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.line),
                  ),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.slidersHorizontal,
                    size: AppSizes.iconInline,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                top: -4,
                right: -4,
                child: AnimatedContainer(
                  duration: AppMotion.resolve(context, AppMotion.durationFast),
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: AppTextStyles.overline.copyWith(
                      fontSize: 10,
                      color: AppColors.onDark,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
