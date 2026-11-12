import '../../../core/money/money.dart';
import '../../../core/utils/validation_failure.dart';
import '../../../core/utils/validators.dart';
import 'account.dart';

/// Checks an account draft and returns a cleaned copy (name trimmed).
AccountDraft validateAccountDraft(AccountDraft draft) {
  final String name = validateName('name', draft.name, max: 40);
  ensure(
    accountColourTokens.contains(draft.colour),
    'colour',
    FailureCode.invalidChoice,
    'Pick a colour from the list.',
  );
  ensure(
    draft.openingBalance >= 0 || draft.type == AccountType.card,
    'openingBalance',
    FailureCode.outOfRange,
    'Only card accounts can start below zero.',
  );
  validatePaise('openingBalance', draft.openingBalance, min: -maxPaise);
  return AccountDraft(
    name: name,
    type: draft.type,
    colour: draft.colour,
    openingBalance: draft.openingBalance,
    sortOrder: draft.sortOrder,
    archived: draft.archived,
  );
}
