import '../../../core/utils/validation_failure.dart';
import '../../../core/utils/validators.dart';
import 'loan.dart';

LoanDraft validateLoanDraft(LoanDraft draft) {
  final String person = validateName('person', draft.person, max: 60);
  validatePaise('principal', draft.principal);
  validateDate('startDate', draft.startDate);
  final String? due = draft.dueDate;
  if (due != null) {
    validateDate('dueDate', due);
    ensure(
      due.compareTo(draft.startDate) >= 0,
      'dueDate',
      FailureCode.rule,
      'Due date cannot be before the start date.',
    );
  }
  return LoanDraft(
    direction: draft.direction,
    person: person,
    principal: draft.principal,
    startDate: draft.startDate,
    dueDate: due,
    note: validateOptionalText('note', draft.note, max: 200),
    closed: draft.closed,
  );
}
