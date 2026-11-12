import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/repository_support.dart';
import '../../../core/database/row_ops.dart';
import '../../../core/sync/sync_status.dart';
import '../../../core/utils/validation_failure.dart';
import '../domain/category.dart';
import '../domain/category_validator.dart';

const String _tag = 'categories';
const String _duplicate = 'A category with this name already exists.';

extension CategoryRowMapper on CategoryRow {
  Category toDomain() => Category(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    syncStatus: SyncStatus.parse(syncStatus),
    name: name,
    kind: CategoryKind.values.byName(kind),
    colourGroup: CategoryColourGroup.values.byName(colourGroup),
    icon: icon,
    sortOrder: sortOrder,
    archived: archived,
  );
}

class CategoriesRepository {
  const CategoriesRepository(this._ctx);

  final RepositoryContext _ctx;

  Future<Category> create(CategoryDraft draft) => _ctx.run(
    _tag,
    'create',
    () async {
      final CategoryDraft d = validateCategoryDraft(draft);
      final int now = _ctx.clock.nowMs();
      final String id = _ctx.ids.newId();
      await _ctx.db.categoriesDao.insertRow(
        CategoriesCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          name: d.name,
          kind: d.kind.name,
          colourGroup: d.colourGroup.name,
          icon: d.icon,
          sortOrder: Value<int>(d.sortOrder),
          archived: Value<bool>(d.archived),
        ),
      );
      return (await _ctx.db.categoriesDao.findById(id))!.toDomain();
    },
    idOf: (Category c) => c.id,
    duplicateMessage: _duplicate,
  );

  /// Changing the kind is refused while live transactions use the category,
  /// because their type must match the kind.
  Future<Category> update(String id, CategoryDraft draft) => _ctx.run(
    _tag,
    'update',
    () async {
      final CategoryDraft d = validateCategoryDraft(draft);
      return _ctx.db.transaction(() async {
        final CategoryRow? existing = await _ctx.db.categoriesDao.findById(id);
        if (existing == null) throw const NotFoundFailure();
        if (existing.kind != d.kind.name &&
            await _ctx.db.categoriesDao.isInUse(id)) {
          throw const InUseFailure(
            'This category has entries, so its kind cannot change.',
          );
        }
        await _ctx.db.categoriesDao.updateRow(
          id,
          CategoriesCompanion(
            name: Value<String>(d.name),
            kind: Value<String>(d.kind.name),
            colourGroup: Value<String>(d.colourGroup.name),
            icon: Value<String>(d.icon),
            sortOrder: Value<int>(d.sortOrder),
            archived: Value<bool>(d.archived),
            updatedAt: Value<int>(
              updatedAtFor(existing.createdAt, _ctx.clock.nowMs()),
            ),
            syncStatus: const Value<String>('pending'),
          ),
        );
        return (await _ctx.db.categoriesDao.findById(id))!.toDomain();
      });
    },
    idOf: (_) => id,
    duplicateMessage: _duplicate,
  );

  /// Soft delete. Refused while live transactions use it. Its live budgets
  /// are soft deleted in the same step.
  Future<void> softDelete(String id) => _ctx.run(_tag, 'softDelete', () async {
    await _ctx.db.transaction(() async {
      if (await _ctx.db.categoriesDao.findById(id) == null) {
        throw const NotFoundFailure();
      }
      if (await _ctx.db.categoriesDao.isInUse(id)) {
        throw const InUseFailure(
          'This category is still used by entries. Delete or move them first.',
        );
      }
      final int now = _ctx.clock.nowMs();
      await _ctx.db.budgetsDao.softDeleteForCategory(id, now);
      await _ctx.db.categoriesDao.softDelete(id, now);
    });
  }, idOf: (_) => id);

  /// Restores the category only. Its deleted budgets stay deleted.
  Future<Category> restore(String id) => _ctx.run(
    _tag,
    'restore',
    () async {
      await _ctx.db.transaction(() async {
        if (await _ctx.db.categoriesDao.findById(id, includeDeleted: true) ==
            null) {
          throw const NotFoundFailure();
        }
        await _ctx.db.categoriesDao.restore(id, _ctx.clock.nowMs());
      });
      return (await _ctx.db.categoriesDao.findById(id))!.toDomain();
    },
    idOf: (_) => id,
    duplicateMessage: _duplicate,
  );

  Future<Category?> getById(String id, {bool includeDeleted = false}) =>
      _ctx.run(_tag, 'getById', () async {
        final CategoryRow? row = await _ctx.db.categoriesDao.findById(
          id,
          includeDeleted: includeDeleted,
        );
        return row?.toDomain();
      });

  /// Live categories in display order, optionally only one kind.
  Stream<List<Category>> watchAll({CategoryKind? kind}) => _ctx.guardStream(
    _tag,
    'watchAll',
    _ctx.db.categoriesDao
        .watchLive(kind: kind?.name)
        .map(
          (List<CategoryRow> rows) =>
              rows.map((CategoryRow r) => r.toDomain()).toList(growable: false),
        ),
  );
}
