import '../../../core/database/app_database.dart';
import '../../../core/database/repository_support.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/id_generator.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../setup/domain/account_presets.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../transactions/domain/transaction_entry.dart';
import '../domain/demo_accounts.dart';
import '../domain/demo_seed_generator.dart';

/// Writes demo accounts and entries into [db] with the normal repositories,
/// in ONE transaction. Only ever called on the demo file.
Future<int> seedDemoData(
  AppDatabase db, {
  required Clock clock,
  required AppLogger logger,
}) async {
  final RepositoryContext ctx = RepositoryContext(
    db: db,
    clock: clock,
    ids: const IdGenerator(),
    logger: logger,
  );
  final DateTime today = DateTime.fromMillisecondsSinceEpoch(clock.nowMs());
  final List<TransactionDraft> drafts = generateDemoTransactions(today);
  final Stopwatch watch = Stopwatch()..start();
  await db.transaction(() async {
    await AccountsRepository(ctx).createAll(
      demoAccountDrafts(),
      fixedIds: <String?>[for (final AccountPreset p in accountPresets) p.id],
    );
    final TransactionsRepository tx = TransactionsRepository(ctx);
    for (final TransactionDraft d in drafts) {
      await tx.create(d);
    }
  });
  logger.info(
    'demo',
    'seeded ${drafts.length} entries in ${watch.elapsedMilliseconds}ms',
  );
  return drafts.length;
}
