import 'package:drift/drift.dart';

import '../app_database.dart';
import '../row_ops.dart';
import '../tables/daily_activities.dart';

part 'daily_activities_dao.g.dart';

@DriftAccessor(tables: <Type>[DailyActivities])
class DailyActivitiesDao extends DatabaseAccessor<AppDatabase>
    with _$DailyActivitiesDaoMixin {
  DailyActivitiesDao(super.attachedDatabase);

  Future<void> insertRow(DailyActivitiesCompanion row) =>
      into(dailyActivities).insert(row);

  Future<int> updateRow(String id, DailyActivitiesCompanion changes) =>
      (update(dailyActivities)..where(
            (DailyActivities t) => t.id.equals(id) & t.deletedAt.isNull(),
          ))
          .write(changes);

  Future<DailyActivityRow?> findById(String id, {bool includeDeleted = false}) {
    final SimpleSelectStatement<$DailyActivitiesTable, DailyActivityRow> query =
        select(dailyActivities)..where((DailyActivities t) => t.id.equals(id));
    if (!includeDeleted) {
      query.where((DailyActivities t) => t.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  Stream<List<DailyActivityRow>> watchForDate(String date) =>
      (select(dailyActivities)
            ..where(
              (DailyActivities t) => t.deletedAt.isNull() & t.date.equals(date),
            )
            ..orderBy(<OrderClauseGenerator<$DailyActivitiesTable>>[
              (DailyActivities t) => OrderingTerm.asc(t.createdAt),
            ]))
          .watch();

  Future<int> softDelete(String id, int now) =>
      softDeleteRow(attachedDatabase, dailyActivities, id, now);

  Future<int> restore(String id, int now) =>
      restoreRow(attachedDatabase, dailyActivities, id, now);
}
