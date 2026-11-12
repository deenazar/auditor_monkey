import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/daily_activities_dao.dart';
import '../../../core/database/repository_support.dart';
import '../../../core/database/row_ops.dart';
import '../../../core/sync/sync_status.dart';
import '../../../core/utils/validation_failure.dart';
import '../../../core/utils/validators.dart';
import '../domain/daily_activity.dart';
import '../domain/daily_activity_validator.dart';

const String _tag = 'daily_activities';

extension DailyActivityRowMapper on DailyActivityRow {
  DailyActivity toDomain() => DailyActivity(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    syncStatus: SyncStatus.parse(syncStatus),
    date: date,
    title: title,
    note: note,
  );
}

class DailyActivitiesRepository {
  const DailyActivitiesRepository(this._ctx);

  final RepositoryContext _ctx;

  DailyActivitiesDao get _dao => _ctx.db.dailyActivitiesDao;

  Future<DailyActivity> create(DailyActivityDraft draft) =>
      _ctx.run(_tag, 'create', () async {
        final DailyActivityDraft d = validateDailyActivityDraft(draft);
        final int now = _ctx.clock.nowMs();
        final String id = _ctx.ids.newId();
        await _dao.insertRow(
          DailyActivitiesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            date: d.date,
            title: d.title,
            note: Value<String?>(d.note),
          ),
        );
        return (await _dao.findById(id))!.toDomain();
      }, idOf: (DailyActivity a) => a.id);

  Future<DailyActivity> update(String id, DailyActivityDraft draft) =>
      _ctx.run(_tag, 'update', () async {
        final DailyActivityDraft d = validateDailyActivityDraft(draft);
        return _ctx.db.transaction(() async {
          final DailyActivityRow? existing = await _dao.findById(id);
          if (existing == null) throw const NotFoundFailure();
          await _dao.updateRow(
            id,
            DailyActivitiesCompanion(
              date: Value<String>(d.date),
              title: Value<String>(d.title),
              note: Value<String?>(d.note),
              updatedAt: Value<int>(
                updatedAtFor(existing.createdAt, _ctx.clock.nowMs()),
              ),
              syncStatus: const Value<String>('pending'),
            ),
          );
          return (await _dao.findById(id))!.toDomain();
        });
      }, idOf: (_) => id);

  Future<void> softDelete(String id) => _ctx.run(_tag, 'softDelete', () async {
    if (await _dao.findById(id) == null) throw const NotFoundFailure();
    await _dao.softDelete(id, _ctx.clock.nowMs());
  }, idOf: (_) => id);

  Future<DailyActivity> restore(String id) =>
      _ctx.run(_tag, 'restore', () async {
        if (await _dao.findById(id, includeDeleted: true) == null) {
          throw const NotFoundFailure();
        }
        await _dao.restore(id, _ctx.clock.nowMs());
        return (await _dao.findById(id))!.toDomain();
      }, idOf: (_) => id);

  Future<DailyActivity?> getById(String id, {bool includeDeleted = false}) =>
      _ctx.run(_tag, 'getById', () async {
        final DailyActivityRow? row = await _dao.findById(
          id,
          includeDeleted: includeDeleted,
        );
        return row?.toDomain();
      });

  /// Live activities of one day (`YYYY-MM-DD`), oldest first.
  Stream<List<DailyActivity>> watchForDate(String date) {
    validateDate('date', date);
    return _ctx.guardStream(
      _tag,
      'watchForDate',
      _dao
          .watchForDate(date)
          .map(
            (List<DailyActivityRow> rows) => rows
                .map((DailyActivityRow r) => r.toDomain())
                .toList(growable: false),
          ),
    );
  }
}
