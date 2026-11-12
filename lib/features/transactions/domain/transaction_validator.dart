import '../../../core/utils/validation_failure.dart';
import '../../../core/utils/validators.dart';
import 'transaction_entry.dart';

/// Checks a transaction draft (no database needed) and returns a cleaned
/// copy. The repository then checks that the referenced rows exist.
TransactionDraft validateTransactionDraft(TransactionDraft draft) {
  validatePaise('amount', draft.amount);
  validateDate('date', draft.date);
  final String? note = validateOptionalText('note', draft.note, max: 200);
  final String? source = validateOptionalText(
    'importSource',
    draft.importSource,
    max: 120,
  );
  ensure(
    draft.accountId.isNotEmpty,
    'accountId',
    FailureCode.required,
    'Pick an account.',
  );

  if (draft.type == TransactionType.transfer) {
    ensure(
      draft.toAccountId != null && draft.toAccountId!.isNotEmpty,
      'toAccountId',
      FailureCode.required,
      'Pick the account to move money to.',
    );
    ensure(
      draft.toAccountId != draft.accountId,
      'toAccountId',
      FailureCode.rule,
      'Pick two different accounts.',
    );
    ensure(
      draft.categoryId == null,
      'categoryId',
      FailureCode.rule,
      'A transfer has no category.',
    );
    ensure(
      draft.loanId == null,
      'loanId',
      FailureCode.rule,
      'A transfer cannot be linked to a loan.',
    );
  } else {
    ensure(
      draft.toAccountId == null,
      'toAccountId',
      FailureCode.rule,
      'Only a transfer has a second account.',
    );
    ensure(
      draft.categoryId != null && draft.categoryId!.isNotEmpty,
      'categoryId',
      FailureCode.required,
      'Pick a category.',
    );
  }

  return TransactionDraft(
    type: draft.type,
    amount: draft.amount,
    date: draft.date,
    accountId: draft.accountId,
    toAccountId: draft.toAccountId,
    categoryId: draft.categoryId,
    note: note,
    loanId: draft.loanId,
    importSource: source,
  );
}
