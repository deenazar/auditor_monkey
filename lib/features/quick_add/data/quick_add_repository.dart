import '../../../core/database/app_database.dart';
import '../../../core/database/daos/transactions_quick_add_queries.dart';
import '../../../core/database/repository_support.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/validators.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../transactions/domain/transaction_entry.dart';
import '../domain/quick_add_hints.dart';

const String _tag = 'quick_add';

/// How many days back the hints look (entries dated later are included).
const int quickAddWindowDays = 90;

/// Read-only queries for Quick Add: last used, usage and recent entries.
class QuickAddRepository {
  const QuickAddRepository(this._ctx);

  final RepositoryContext _ctx;

  /// Loads all hints in ONE read transaction (a consistent snapshot).
  /// [today] is `YYYY-MM-DD`. Logs counts and timing only.
  Future<QuickAddHints> loadHints({required String today}) => _ctx.run(
    _tag,
    'loadHints',
    () async {
      validateDate('today', today);
      final String since = addDays(today, -quickAddWindowDays);
      final Stopwatch watch = Stopwatch()..start();
      final QuickAddHints hints = await _ctx.db.transaction(() => _read(since));
      watch.stop();
      _ctx.logger.debug(
        _tag,
        'hints loaded: ${hints.recent.length} recent, '
        '${hints.lastUsed.length} last used, '
        '${watch.elapsedMilliseconds} ms',
      );
      return hints;
    },
  );

  Future<QuickAddHints> _read(String since) async {
    final dao = _ctx.db.transactionsDao;
    final Map<TransactionType, LastUsedPick> lastUsed =
        <TransactionType, LastUsedPick>{};
    for (final TransactionType type in TransactionType.values) {
      final List<LastUsedRow> rows = await dao
          .quickAddLastUsed(type.name, since)
          .get();
      if (rows.isNotEmpty) {
        final LastUsedRow r = rows.first;
        lastUsed[type] = LastUsedPick(
          accountId: r.accountId,
          toAccountId: r.toAccountId,
          categoryId: r.categoryId,
        );
      }
    }
    final Map<TransactionType, List<CategoryUsage>> usage =
        <TransactionType, List<CategoryUsage>>{};
    for (final TransactionType type in <TransactionType>[
      TransactionType.expense,
      TransactionType.income,
    ]) {
      final List<CategoryUsageRow> rows = await dao
          .quickAddUsage(type.name, since)
          .get();
      usage[type] = List<CategoryUsage>.unmodifiable(
        rows.map(
          (CategoryUsageRow r) => CategoryUsage(
            categoryId: r.categoryId,
            uses: r.uses,
            lastUsed: r.lastUsed,
          ),
        ),
      );
    }
    final List<TransactionRow> recent = await dao.quickAddRecent(since).get();
    return QuickAddHints(
      lastUsed: Map<TransactionType, LastUsedPick>.unmodifiable(lastUsed),
      usage: Map<TransactionType, List<CategoryUsage>>.unmodifiable(usage),
      recent: List<TransactionEntry>.unmodifiable(
        recent.map((TransactionRow r) => r.toDomain()),
      ),
    );
  }
}
