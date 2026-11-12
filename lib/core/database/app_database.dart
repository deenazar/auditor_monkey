import 'package:drift/drift.dart';

import '../logging/app_logger.dart';
import '../utils/clock.dart';
import 'daos/accounts_dao.dart';
import 'daos/budgets_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/daily_activities_dao.dart';
import 'daos/gold_dao.dart';
import 'daos/loans_dao.dart';
import 'daos/transactions_dao.dart';
import 'seed/default_categories.dart';
import 'tables/accounts.dart';
import 'tables/budgets.dart';
import 'tables/categories.dart';
import 'tables/daily_activities.dart';
import 'tables/gold_holdings.dart';
import 'tables/gold_rates.dart';
import 'tables/loans.dart';
import 'tables/transactions.dart';

part 'app_database.g.dart';

const String _tag = 'db';

@DriftDatabase(
  tables: <Type>[
    Accounts,
    Categories,
    Transactions,
    Budgets,
    Loans,
    GoldHoldings,
    GoldRates,
    DailyActivities,
  ],
  daos: <Type>[
    AccountsDao,
    CategoriesDao,
    TransactionsDao,
    BudgetsDao,
    LoansDao,
    GoldDao,
    DailyActivitiesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// [executor] comes from `openAppConnection()` in the app, or from an
  /// in-memory database in tests.
  AppDatabase(super.executor, {AppLogger? logger, Clock? clock})
    : _logger = logger ?? AppLogger.instance,
      _clock = clock ?? const SystemClock();

  final AppLogger _logger;
  final Clock _clock;

  /// Version of the database layout. Raise it by one for every layout change
  /// and follow the steps in docs/DATABASE.md. Version 1 = all 8 tables.
  /// Must stay a plain number: `make-migrations` reads it from the source.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      final int seeded = await _seedDefaultCategories();
      _logger.info(
        _tag,
        'created database v$schemaVersion, seeded $seeded categories',
      );
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from > to) {
        // Never drop or guess. A newer database must not be opened by an
        // older app.
        _logger.error(
          _tag,
          'refusing to open database v$from with app schema v$to',
        );
        throw StateError('Database is newer than this app version.');
      }
      _logger.info(_tag, 'migrating database v$from -> v$to');
      // Step-by-step migrations go here. See docs/DATABASE.md.
    },
    beforeOpen: (OpeningDetails details) async {
      // Foreign keys are off by default in SQLite. Must be set outside a
      // transaction, so it lives here.
      await customStatement('PRAGMA foreign_keys = ON');
      if (!details.hadUpgrade && !details.wasCreated) {
        _logger.info(_tag, 'opened database v${details.versionNow}');
      }
    },
  );

  /// Inserts the 34 default categories in one batch. Returns the count.
  Future<int> _seedDefaultCategories() async {
    final int now = _clock.nowMs();
    await batch((Batch b) {
      b.insertAll(categories, <CategoriesCompanion>[
        for (int i = 0; i < defaultCategories.length; i++)
          CategoriesCompanion.insert(
            id: defaultCategories[i].id,
            createdAt: now,
            updatedAt: now,
            name: defaultCategories[i].name,
            kind: defaultCategories[i].kind.name,
            colourGroup: defaultCategories[i].colourGroup.name,
            icon: defaultCategories[i].icon,
            sortOrder: Value<int>(i),
          ),
      ]);
    });
    return defaultCategories.length;
  }
}
