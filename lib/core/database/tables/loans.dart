import 'package:drift/drift.dart';

import 'sync_columns.dart';

@DataClassName('LoanRow')
@TableIndex.sql(
  'CREATE INDEX ix_loans_pending ON loans (sync_status) '
  "WHERE sync_status = 'pending'",
)
class Loans extends Table with SyncColumns {
  TextColumn get direction => text()();
  TextColumn get person => text()();
  IntColumn get principal => integer()();
  TextColumn get startDate => text()();
  TextColumn get dueDate => text().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get closed => boolean().withDefault(const Constant<bool>(false))();

  @override
  List<String> get customConstraints => const <String>[
    "CHECK (direction IN ('lent', 'borrowed'))",
    'CHECK (length(trim(person)) BETWEEN 1 AND 60)',
    "CHECK (typeof(principal) = 'integer' AND principal > 0 "
        'AND principal <= 100000000000000)',
    'CHECK (length(start_date) = 10 AND date(start_date) IS start_date)',
    'CHECK (due_date IS NULL OR (length(due_date) = 10 '
        'AND date(due_date) IS due_date AND due_date >= start_date))',
    'CHECK (note IS NULL OR length(note) <= 200)',
  ];
}
