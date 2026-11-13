import '../../../core/utils/date_keys.dart';
import '../../../core/utils/validators.dart';
import '../../transactions/domain/transaction_entry.dart';

/// Quick Add allows dates up to this many days after today.
const int maxDaysAhead = 31;

/// Longest note.
const int maxNoteLength = 200;

/// The counter under the note shows from this length.
const int noteCounterFrom = 180;

/// Which part of the form a problem belongs to.
enum QuickAddField { amount, category, account, toAccount, note, date }

class QuickAddIssue {
  const QuickAddIssue(this.field, this.message);

  final QuickAddField field;

  /// Short plain text, safe to show and never logged with values.
  final String message;
}

final RegExp _controlChars = RegExp(r'[\u0000-\u001F\u007F]');

/// Note rule: optional, trimmed, at most 200 characters, single line, no
/// control characters. Returns `null` when fine.
QuickAddIssue? noteIssue(String? note) {
  final String text = (note ?? '').trim();
  if (text.length > maxNoteLength) {
    return const QuickAddIssue(
      QuickAddField.note,
      'Use 200 characters or fewer.',
    );
  }
  if (_controlChars.hasMatch(text)) {
    return const QuickAddIssue(
      QuickAddField.note,
      'Remove special characters.',
    );
  }
  return null;
}

/// Date rule: a real `YYYY-MM-DD` date from 1900-01-01 and at most
/// [maxDaysAhead] days after [today]. Returns `null` when fine.
QuickAddIssue? dateIssue(
  String date, {
  required String today,
  bool allowFarDate = false,
}) {
  if (!isValidDate(date)) {
    return const QuickAddIssue(QuickAddField.date, 'Enter a valid date.');
  }
  if (!allowFarDate && date.compareTo(addDays(today, maxDaysAhead)) > 0) {
    return const QuickAddIssue(
      QuickAddField.date,
      'Pick a date up to 31 days ahead.',
    );
  }
  return null;
}

/// The form values to check. Offered sets come from the loaded data.
class QuickAddForm {
  const QuickAddForm({
    required this.type,
    required this.amountPaise,
    required this.date,
    required this.today,
    required this.note,
    required this.accountId,
    required this.toAccountId,
    required this.categoryId,
    required this.offeredAccountIds,
    required this.offeredCategoryIds,
    this.unchangedDate,
  });

  final TransactionType type;

  /// `null` when empty or zero.
  final int? amountPaise;
  final String date;
  final String today;
  final String note;
  final String? accountId;
  final String? toAccountId;
  final String? categoryId;
  final Set<String> offeredAccountIds;

  /// Offered categories of this type's kind (empty for a transfer).
  final Set<String> offeredCategoryIds;

  /// Edit mode: the date the entry already has. It stays allowed even when
  /// it is further ahead than [maxDaysAhead] (past dates are always fine).
  final String? unchangedDate;
}

/// First problem in the form, or `null` when it can be saved. The
/// repository checks everything again.
QuickAddIssue? validateQuickAdd(QuickAddForm f) {
  if (f.amountPaise == null) {
    return const QuickAddIssue(QuickAddField.amount, 'Enter an amount.');
  }
  final bool isTransfer = f.type == TransactionType.transfer;
  if (!isTransfer) {
    final String? c = f.categoryId;
    if (c == null || !f.offeredCategoryIds.contains(c)) {
      return const QuickAddIssue(QuickAddField.category, 'Pick a category.');
    }
  }
  final String? a = f.accountId;
  if (a == null || !f.offeredAccountIds.contains(a)) {
    return const QuickAddIssue(QuickAddField.account, 'Pick an account.');
  }
  if (isTransfer) {
    final String? to = f.toAccountId;
    if (to == null || !f.offeredAccountIds.contains(to) || to == a) {
      return const QuickAddIssue(
        QuickAddField.toAccount,
        'Pick two different accounts.',
      );
    }
  }
  return noteIssue(f.note) ??
      dateIssue(
        f.date,
        today: f.today,
        allowFarDate: f.unchangedDate != null && f.date == f.unchangedDate,
      );
}

/// The draft for the repository (transfer: no category; expense / income:
/// no To account). Call only after [validateQuickAdd] returned `null`.
TransactionDraft buildQuickAddDraft(QuickAddForm f) {
  final bool isTransfer = f.type == TransactionType.transfer;
  final String note = f.note.trim();
  return TransactionDraft(
    type: f.type,
    amount: f.amountPaise!,
    date: f.date,
    accountId: f.accountId!,
    toAccountId: isTransfer ? f.toAccountId : null,
    categoryId: isTransfer ? null : f.categoryId,
    note: note.isEmpty ? null : note,
  );
}
