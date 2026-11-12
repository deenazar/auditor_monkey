import 'package:drift/drift.dart';

import '../app_database.dart';
import '../row_ops.dart';
import '../tables/loans.dart';
import '../tables/transactions.dart';

part 'loans_dao.g.dart';

/// A loan row with what is still owed (paise).
class LoanOutstandingRow {
  const LoanOutstandingRow({required this.row, required this.outstanding});

  final LoanRow row;
  final int outstanding;
}

/// Outstanding = principal - live repayments. A repayment is income for a
/// loan I lent, and expense for a loan I borrowed.
const String loanOutstandingSql = '''
SELECT l.*,
  l.principal - COALESCE((
    SELECT SUM(t.amount) FROM transactions t
     WHERE t.loan_id = l.id AND t.deleted_at IS NULL
       AND t.type = CASE l.direction WHEN 'lent' THEN 'income'
                                     ELSE 'expense' END), 0) AS outstanding
FROM loans l
WHERE l.deleted_at IS NULL
''';

@DriftAccessor(tables: <Type>[Loans, Transactions])
class LoansDao extends DatabaseAccessor<AppDatabase> with _$LoansDaoMixin {
  LoansDao(super.attachedDatabase);

  Future<void> insertRow(LoansCompanion row) => into(loans).insert(row);

  Future<int> updateRow(String id, LoansCompanion changes) => (update(
    loans,
  )..where((Loans t) => t.id.equals(id) & t.deletedAt.isNull())).write(changes);

  Future<LoanRow?> findById(String id, {bool includeDeleted = false}) {
    final SimpleSelectStatement<$LoansTable, LoanRow> query = select(loans)
      ..where((Loans t) => t.id.equals(id));
    if (!includeDeleted) {
      query.where((Loans t) => t.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// True when live transactions are linked to this loan.
  Future<bool> hasLiveTransactions(String id) async {
    final List<QueryRow> rows = await customSelect(
      'SELECT EXISTS (SELECT 1 FROM transactions '
      'WHERE loan_id = ? AND deleted_at IS NULL) AS used',
      variables: <Variable<Object>>[Variable<String>(id)],
      readsFrom: <TableInfo<Table, Object?>>{transactions},
    ).get();
    return rows.single.read<bool>('used');
  }

  Future<int> softDelete(String id, int now) =>
      softDeleteRow(attachedDatabase, loans, id, now);

  Future<int> restore(String id, int now) =>
      restoreRow(attachedDatabase, loans, id, now);

  Selectable<LoanOutstandingRow> outstanding() =>
      customSelect(
        '$loanOutstandingSql ORDER BY l.closed, l.start_date DESC, l.id',
        readsFrom: <TableInfo<Table, Object?>>{loans, transactions},
      ).map(
        (QueryRow r) => LoanOutstandingRow(
          row: loans.map(r.data),
          outstanding: r.read<int>('outstanding'),
        ),
      );
}
