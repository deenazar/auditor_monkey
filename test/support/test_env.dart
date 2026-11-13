import 'package:auditor_monkey/core/database/app_database.dart';
import 'package:auditor_monkey/core/database/repository_support.dart';
import 'package:auditor_monkey/core/logging/app_logger.dart';
import 'package:auditor_monkey/core/logging/log_record.dart';
import 'package:auditor_monkey/core/logging/log_sink.dart';
import 'package:auditor_monkey/core/utils/clock.dart';
import 'package:auditor_monkey/core/utils/id_generator.dart';
import 'package:auditor_monkey/features/accounts/data/accounts_repository.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/budgets/data/budgets_repository.dart';
import 'package:auditor_monkey/features/categories/data/categories_repository.dart';
import 'package:auditor_monkey/features/daily_activities/data/daily_activities_repository.dart';
import 'package:auditor_monkey/features/gold/data/gold_repository.dart';
import 'package:auditor_monkey/features/loans/data/loans_repository.dart';
import 'package:auditor_monkey/features/transactions/data/transactions_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// A clock the test controls.
class FakeClock implements Clock {
  FakeClock([this.now = 1700000000000]);

  int now;

  @override
  int nowMs() => now;

  void advance([int ms = 1000]) => now += ms;
}

/// Keeps log records in memory so tests can read them.
class MemoryLogSink implements LogSink {
  final List<LogRecord> records = <LogRecord>[];

  @override
  void write(LogRecord record) => records.add(record);

  String get allText => records
      .map((LogRecord r) => '${r.tag} ${r.message} ${r.error ?? ''}')
      .join('\n');
}

/// An in-memory database with every repository, ready for a test.
class TestEnv {
  TestEnv._(this.db, this.clock, this.sink, this.ctx);

  /// [ids] replaces the random id maker (e.g. to force all-digit ids).
  factory TestEnv({IdGenerator ids = const IdGenerator()}) {
    final FakeClock clock = FakeClock();
    final MemoryLogSink sink = MemoryLogSink();
    final AppLogger logger = AppLogger(
      sinks: <LogSink>[sink],
      isRelease: false,
    );
    final AppDatabase db = AppDatabase(
      NativeDatabase.memory(),
      logger: logger,
      clock: clock,
    );
    final RepositoryContext ctx = RepositoryContext(
      db: db,
      clock: clock,
      ids: ids,
      logger: logger,
    );
    return TestEnv._(db, clock, sink, ctx);
  }

  final AppDatabase db;
  final FakeClock clock;
  final MemoryLogSink sink;
  final RepositoryContext ctx;

  late final AccountsRepository accounts = AccountsRepository(ctx);
  late final CategoriesRepository categories = CategoriesRepository(ctx);
  late final TransactionsRepository transactions = TransactionsRepository(ctx);
  late final BudgetsRepository budgets = BudgetsRepository(ctx);
  late final LoansRepository loans = LoansRepository(ctx);
  late final GoldRepository gold = GoldRepository(ctx);
  late final DailyActivitiesRepository activities = DailyActivitiesRepository(
    ctx,
  );

  Future<void> close() => db.close();

  /// Runs SQL that bypasses the repositories (to test the DB CHECK rules).
  Future<void> rawSql(String sql, [List<Object?> args = const <Object?>[]]) =>
      db.customStatement(sql, args);

  Future<Account> account(
    String name, {
    AccountType type = AccountType.bank,
    int opening = 0,
  }) => accounts.create(
    AccountDraft(
      name: name,
      type: type,
      colour: 'accountSbi',
      openingBalance: opening,
    ),
  );

  /// Id of a seeded category by name and kind, e.g. `('Groceries','expense')`.
  Future<String> seededCategoryId(String name, String kind) async {
    final QueryRow row = await db
        .customSelect(
          'SELECT id FROM categories WHERE name = ? AND kind = ?',
          variables: <Variable<Object>>[
            Variable<String>(name),
            Variable<String>(kind),
          ],
        )
        .getSingle();
    return row.read<String>('id');
  }

  Future<int> count(String table, {bool liveOnly = false}) async {
    final QueryRow row = await db
        .customSelect(
          'SELECT COUNT(*) AS c FROM $table'
          '${liveOnly ? ' WHERE deleted_at IS NULL' : ''}',
        )
        .getSingle();
    return row.read<int>('c');
  }

  /// The raw stored row of [table] with [id], as a column map.
  Future<Map<String, Object?>> rawRow(String table, String id) async {
    final QueryRow row = await db
        .customSelect(
          'SELECT * FROM $table WHERE id = ?',
          variables: <Variable<Object>>[Variable<String>(id)],
        )
        .getSingle();
    return row.data;
  }
}
