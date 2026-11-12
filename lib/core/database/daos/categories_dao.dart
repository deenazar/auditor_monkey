import 'package:drift/drift.dart';

import '../app_database.dart';
import '../row_ops.dart';
import '../tables/categories.dart';
import '../tables/transactions.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: <Type>[Categories, Transactions])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.attachedDatabase);

  Future<void> insertRow(CategoriesCompanion row) =>
      into(categories).insert(row);

  Future<int> updateRow(String id, CategoriesCompanion changes) =>
      (update(categories)
            ..where((Categories t) => t.id.equals(id) & t.deletedAt.isNull()))
          .write(changes);

  Future<CategoryRow?> findById(String id, {bool includeDeleted = false}) {
    final SimpleSelectStatement<$CategoriesTable, CategoryRow> query = select(
      categories,
    )..where((Categories t) => t.id.equals(id));
    if (!includeDeleted) {
      query.where((Categories t) => t.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  Stream<List<CategoryRow>> watchLive({String? kind}) {
    final SimpleSelectStatement<$CategoriesTable, CategoryRow> query =
        select(categories)
          ..where((Categories t) => t.deletedAt.isNull())
          ..orderBy(<OrderClauseGenerator<$CategoriesTable>>[
            (Categories t) => OrderingTerm.asc(t.sortOrder),
            (Categories t) =>
                OrderingTerm(expression: t.name.collate(Collate.noCase)),
          ]);
    if (kind != null) {
      query.where((Categories t) => t.kind.equals(kind));
    }
    return query.watch();
  }

  Future<int> countLive() async {
    final Expression<int> count = categories.id.count();
    final TypedResult row =
        await (selectOnly(categories)
              ..addColumns(<Expression<Object>>[count])
              ..where(categories.deletedAt.isNull()))
            .getSingle();
    return row.read(count) ?? 0;
  }

  /// True when live transactions use this category.
  Future<bool> isInUse(String id) async {
    final List<QueryRow> rows = await customSelect(
      'SELECT EXISTS (SELECT 1 FROM transactions '
      'WHERE category_id = ? AND deleted_at IS NULL) AS used',
      variables: <Variable<Object>>[Variable<String>(id)],
      readsFrom: <TableInfo<Table, Object?>>{transactions},
    ).get();
    return rows.single.read<bool>('used');
  }

  Future<int> softDelete(String id, int now) =>
      softDeleteRow(attachedDatabase, categories, id, now);

  Future<int> restore(String id, int now) =>
      restoreRow(attachedDatabase, categories, id, now);
}
