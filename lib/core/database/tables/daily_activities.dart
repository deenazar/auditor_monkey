import 'package:drift/drift.dart';

import 'sync_columns.dart';

@DataClassName('DailyActivityRow')
@TableIndex.sql(
  'CREATE INDEX ix_daily_activities_date ON daily_activities (date)',
)
@TableIndex.sql(
  'CREATE INDEX ix_daily_activities_pending ON daily_activities '
  "(sync_status) WHERE sync_status = 'pending'",
)
class DailyActivities extends Table with SyncColumns {
  TextColumn get date => text()();
  TextColumn get title => text()();
  TextColumn get note => text().nullable()();

  @override
  List<String> get customConstraints => const <String>[
    'CHECK (length(date) = 10 AND date(date) IS date)',
    'CHECK (length(trim(title)) BETWEEN 1 AND 80)',
    'CHECK (note IS NULL OR length(note) <= 1000)',
  ];
}
