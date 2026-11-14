import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/today_provider.dart';
import '../../budgets/application/budgets_providers.dart';
import '../../budgets/domain/budget.dart';

/// This month's budget total (paise; 0 when there are no budgets).
///
/// The Dashboard reads its budget total inside `dashboardSummaryProvider`
/// (one snapshot); this provider is for screens that only need the number.
final Provider<AsyncValue<int>> monthBudgetTotalProvider =
    Provider<AsyncValue<int>>((Ref ref) {
      final String month = ref.watch(currentMonthProvider);
      return ref
          .watch(budgetsForMonthProvider(month))
          .whenData(
            (List<Budget> budgets) =>
                budgets.fold<int>(0, (int sum, Budget b) => sum + b.amount),
          );
    });
