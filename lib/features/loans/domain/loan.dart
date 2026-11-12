import '../../../core/sync/synced_entity.dart';

/// `lent`: I gave money. `borrowed`: I received money.
enum LoanDirection { lent, borrowed }

final class Loan extends SyncedEntity {
  const Loan({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.deletedAt,
    required super.syncStatus,
    required this.direction,
    required this.person,
    required this.principal,
    required this.startDate,
    required this.dueDate,
    required this.note,
    required this.closed,
  });

  final LoanDirection direction;
  final String person;

  /// Paise, above zero.
  final int principal;
  final String startDate;
  final String? dueDate;
  final String? note;
  final bool closed;
}

class LoanDraft {
  const LoanDraft({
    required this.direction,
    required this.person,
    required this.principal,
    required this.startDate,
    this.dueDate,
    this.note,
    this.closed = false,
  });

  final LoanDirection direction;
  final String person;
  final int principal;
  final String startDate;
  final String? dueDate;
  final String? note;
  final bool closed;
}

/// A loan with what is still owed: principal minus repayments (paise).
/// Can go below zero when more than the principal was repaid.
class LoanSummary {
  const LoanSummary({required this.loan, required this.outstanding});

  final Loan loan;
  final int outstanding;
}
