import '../../../../core/utils/validation_failure.dart';
import '../../../setup/domain/opening_balance_input.dart';
import '../../domain/account.dart';

/// What the add / edit account sheet (and the wizard's sheet) collects.
/// [balanceText] is what the user typed for the opening balance (rupees).
class AccountFormValues {
  const AccountFormValues({
    required this.name,
    required this.type,
    required this.colour,
    this.balanceText = '',
    this.owes = false,
  });

  final String name;
  final AccountType type;

  /// DESIGN.md colour token name.
  final String colour;
  final String balanceText;

  /// "I owe" toggle. Only ever true for card accounts.
  final bool owes;
}

/// A problem reported back by the save step, shown inline. [field] is
/// `name` or `balance` to put the message under that field; `null` shows it
/// as a general message under the form.
class AccountFormError {
  const AccountFormError(this.message, {this.field});

  final String message;
  final String? field;
}

/// Account details from the form values. The sheet has already checked the
/// amount; an unreadable one counts as 0 here. "I owe" makes it negative,
/// but only for cards.
AccountDetails toAccountDetails(AccountFormValues values) {
  final OpeningBalanceInput opening = parseOpeningBalance(
    values.balanceText,
    type: values.type,
    owes: values.owes,
  );
  return AccountDetails(
    name: values.name,
    type: values.type,
    colour: values.colour,
    openingBalance: opening.paise ?? 0,
  );
}

/// Turns a data-layer failure into an inline form error. Field names of
/// validation failures map to `name` or `balance`; other failures show as
/// a general message.
AccountFormError accountFormErrorFrom(DataFailure failure) {
  String? field;
  if (failure is ValidationFailure) {
    final String name = failure.field.toLowerCase();
    if (name.contains('name')) {
      field = 'name';
    } else if (name.contains('balance') || name.contains('opening')) {
      field = 'balance';
    }
  }
  return AccountFormError(failure.message, field: field);
}
