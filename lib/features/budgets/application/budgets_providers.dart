import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/budgets_repository.dart';
import '../domain/budget.dart';

final Provider<BudgetsRepository> budgetsRepositoryProvider =
    Provider<BudgetsRepository>(
      (Ref ref) => BudgetsRepository(ref.watch(repositoryContextProvider)),
    );

/// Live budgets for a month (`YYYY-MM`).
final budgetsForMonthProvider = StreamProvider.family<List<Budget>, String>(
  (Ref ref, String month) =>
      ref.watch(budgetsRepositoryProvider).watchForMonth(month),
);
