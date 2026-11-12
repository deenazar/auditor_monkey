// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_activities_dao.dart';

// ignore_for_file: type=lint
mixin _$DailyActivitiesDaoMixin on DatabaseAccessor<AppDatabase> {
  $DailyActivitiesTable get dailyActivities => attachedDatabase.dailyActivities;
  DailyActivitiesDaoManager get managers => DailyActivitiesDaoManager(this);
}

class DailyActivitiesDaoManager {
  final _$DailyActivitiesDaoMixin _db;
  DailyActivitiesDaoManager(this._db);
  $$DailyActivitiesTableTableManager get dailyActivities =>
      $$DailyActivitiesTableTableManager(
        _db.attachedDatabase,
        _db.dailyActivities,
      );
}
