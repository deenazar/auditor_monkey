import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/repository_support.dart';
import '../../../core/database/row_ops.dart';
import '../../../core/sync/sync_status.dart';
import '../../../core/utils/validation_failure.dart';
import '../../../core/utils/validators.dart';
import '../../categories/domain/category.dart';
import '../domain/budget.dart';
import '../domain/budget_validator.dart';

const String _tag = 'budgets';
const String _duplicate = 'This category already has a budget for that month.';

extension BudgetRowMapper on BudgetRow {
  Budget toDomain() => Budget(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    syncStatus: SyncStatus.parse(syncStatus),
    categoryId: categoryId,
    month: month,
    amount: amount,
  );
}

class BudgetsRepository {
  const BudgetsRepository(this._ctx);

  final RepositoryContext _ctx;

  Future<Budget> create(BudgetDraft draft) => _ctx.run(
    _tag,
    'create',
    () async {
      final BudgetDraft d = validateBudgetDraft(draft);
      final int now = _ctx.clock.nowMs();
      final String id = _ctx.ids.newId();
      await _ctx.db.transaction(() async {
        await _requireExpenseCategory(d.categoryId);
        await _ctx.db.budgetsDao.insertRow(
          BudgetsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            categoryId: d.categoryId,
            month: d.month,
            amount: d.amount,
          ),
        );
      });
      return (await _ctx.db.budgetsDao.findById(id))!.toDomain();
    },
    idOf: (Budget b) => b.id,
    duplicateMessage: _duplicate,
  );

  Future<Budget> update(String id, BudgetDraft draft) => _ctx.run(
    _tag,
    'update',
    () async {
      final BudgetDraft d = validateBudgetDraft(draft);
      await _ctx.db.transaction(() async {
        final BudgetRow? existing = await _ctx.db.budgetsDao.findById(id);
        if (existing == null) throw const NotFoundFailure();
        await _requireExpenseCategory(d.categoryId);
        await _ctx.db.budgetsDao.updateRow(
          id,
          BudgetsCompanion(
            categoryId: Value<String>(d.categoryId),
            month: Value<String>(d.month),
            amount: Value<int>(d.amount),
            updatedAt: Value<int>(
              updatedAtFor(existing.createdAt, _ctx.clock.nowMs()),
            ),
            syncStatus: const Value<String>('pending'),
          ),
        );
      });
      return (await _ctx.db.budgetsDao.findById(id))!.toDomain();
    },
    idOf: (_) => id,
    duplicateMessage: _duplicate,
  );

  Future<void> softDelete(String id) => _ctx.run(_tag, 'softDelete', () async {
    await _ctx.db.transaction(() async {
      if (await _ctx.db.budgetsDao.findById(id) == null) {
        throw const NotFoundFailure();
      }
      await _ctx.db.budgetsDao.softDelete(id, _ctx.clock.nowMs());
    });
  }, idOf: (_) => id);

  /// Restores a budget. Refused when its category is deleted, or when the
  /// month already has another live budget for the category.
  Future<Budget> restore(String id) => _ctx.run(
    _tag,
    'restore',
    () async {
      await _ctx.db.transaction(() async {
        final BudgetRow? existing = await _ctx.db.budgetsDao.findById(
          id,
          includeDeleted: true,
        );
        if (existing == null) throw const NotFoundFailure();
        await _requireExpenseCategory(existing.categoryId);
        await _ctx.db.budgetsDao.restore(id, _ctx.clock.nowMs());
      });
      return (await _ctx.db.budgetsDao.findById(id))!.toDomain();
    },
    idOf: (_) => id,
    duplicateMessage: _duplicate,
  );

  Future<Budget?> getById(String id, {bool includeDeleted = false}) =>
      _ctx.run(_tag, 'getById', () async {
        final BudgetRow? row = await _ctx.db.budgetsDao.findById(
          id,
          includeDeleted: includeDeleted,
        );
        return row?.toDomain();
      });

  /// Live budgets of one month (`YYYY-MM`), kept up to date.
  Stream<List<Budget>> watchForMonth(String month) {
    validateMonth('month', month);
    return _ctx.guardStream(
      _tag,
      'watchForMonth',
      _ctx.db.budgetsDao
          .watchForMonth(month)
          .map(
            (List<BudgetRow> rows) =>
                rows.map((BudgetRow r) => r.toDomain()).toList(growable: false),
          ),
    );
  }

  Future<void> _requireExpenseCategory(String categoryId) async {
    final CategoryRow? category = await _ctx.db.categoriesDao.findById(
      categoryId,
    );
    if (category == null) {
      throw const ValidationFailure(
        'categoryId',
        FailureCode.referenceMissing,
        'That category is not available.',
      );
    }
    if (category.kind != CategoryKind.expense.name) {
      throw const ValidationFailure(
        'categoryId',
        FailureCode.kindMismatch,
        'Budgets are only for expense categories.',
      );
    }
  }
}
