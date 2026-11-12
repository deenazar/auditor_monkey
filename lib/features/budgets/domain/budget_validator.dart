import '../../../core/utils/validation_failure.dart';
import '../../../core/utils/validators.dart';
import 'budget.dart';

BudgetDraft validateBudgetDraft(BudgetDraft draft) {
  ensure(
    draft.categoryId.isNotEmpty,
    'categoryId',
    FailureCode.required,
    'Pick a category.',
  );
  validateMonth('month', draft.month);
  validatePaise('amount', draft.amount);
  return draft;
}
