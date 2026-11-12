import 'package:drift/drift.dart';

import '../app_database.dart';
import '../row_ops.dart';
import '../tables/budgets.dart';

part 'budgets_dao.g.dart';

@DriftAccessor(tables: <Type>[Budgets])
class BudgetsDao extends DatabaseAccessor<AppDatabase> with _$BudgetsDaoMixin {
  BudgetsDao(super.attachedDatabase);

  Future<void> insertRow(BudgetsCompanion row) => into(budgets).insert(row);

  Future<int> updateRow(String id, BudgetsCompanion changes) =>
      (update(budgets)
            ..where((Budgets t) => t.id.equals(id) & t.deletedAt.isNull()))
          .write(changes);

  Future<BudgetRow?> findById(String id, {bool includeDeleted = false}) {
    final SimpleSelectStatement<$BudgetsTable, BudgetRow> query = select(
      budgets,
    )..where((Budgets t) => t.id.equals(id));
    if (!includeDeleted) {
      query.where((Budgets t) => t.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  Stream<List<BudgetRow>> watchForMonth(String month) =>
      (select(budgets)
            ..where((Budgets t) => t.deletedAt.isNull() & t.month.equals(month))
            ..orderBy(<OrderClauseGenerator<$BudgetsTable>>[
              (Budgets t) => OrderingTerm.asc(t.createdAt),
            ]))
          .watch();

  Future<int> softDelete(String id, int now) =>
      softDeleteRow(attachedDatabase, budgets, id, now);

  Future<int> restore(String id, int now) =>
      restoreRow(attachedDatabase, budgets, id, now);

  /// Soft delete every live budget of a category (used when the category is
  /// deleted). Returns how many were changed.
  Future<int> softDeleteForCategory(String categoryId, int now) =>
      attachedDatabase.customUpdate(
        'UPDATE budgets SET deleted_at = ?, '
        'updated_at = max(?, created_at), sync_status = \'pending\' '
        'WHERE category_id = ? AND deleted_at IS NULL',
        variables: <Variable<Object>>[
          Variable<int>(now),
          Variable<int>(now),
          Variable<String>(categoryId),
        ],
        updates: <TableInfo<Table, Object?>>{budgets},
        updateKind: UpdateKind.update,
      );
}
