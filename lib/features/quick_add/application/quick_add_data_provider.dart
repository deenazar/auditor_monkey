import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/date_keys.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../accounts/domain/account.dart';
import '../../categories/application/categories_providers.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/transaction_entry.dart';
import '../data/quick_add_repository.dart';
import '../domain/category_order.dart';
import '../domain/quick_add_defaults.dart';
import '../domain/quick_add_hints.dart';
import '../domain/recent_entries.dart';
import 'quick_add_edit.dart';

final Provider<QuickAddRepository> quickAddRepositoryProvider =
    Provider<QuickAddRepository>(
      (Ref ref) => QuickAddRepository(ref.watch(repositoryContextProvider)),
    );

/// Everything the sheet needs from the database, loaded once per open.
class QuickAddData {
  const QuickAddData({
    required this.accounts,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.hints,
    required this.defaults,
    required this.recent,
  });

  /// Live, not archived, in display order.
  final List<Account> accounts;

  /// Per kind: suggested first, then the rest. Loan categories are left out.
  final OrderedCategories expenseCategories;
  final OrderedCategories incomeCategories;
  final QuickAddHints hints;
  final QuickAddDefaults defaults;

  /// Up to 6 distinct recent entries that can still be repeated.
  final List<TransactionEntry> recent;

  bool get transferAvailable => defaults.transferAvailable;

  OrderedCategories categoriesOf(TransactionType type) =>
      type == TransactionType.income ? incomeCategories : expenseCategories;

  Set<String> get accountIds => <String>{
    for (final Account a in accounts) a.id,
  };

  Set<String> categoryIdsOf(TransactionType type) =>
      type == TransactionType.transfer
      ? const <String>{}
      : <String>{for (final Category c in categoriesOf(type).all) c.id};
}

/// Loads accounts, categories and hints (one open = one load). The pad and
/// amount work before this finishes; the notifier merges the defaults later.
final FutureProvider<QuickAddData> quickAddDataProvider =
    FutureProvider.autoDispose<QuickAddData>((Ref ref) async {
      final String today = dateKey(
        DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs()),
      );
      final List<Account> live = await ref
          .read(accountsRepositoryProvider)
          .watchAll()
          .first;
      final List<Category> categories = await ref
          .read(categoriesRepositoryProvider)
          .watchAll()
          .first;
      final QuickAddHints hints = await ref
          .read(quickAddRepositoryProvider)
          .loadHints(today: today);

      // Edit mode: the entry's own account and category are offered even
      // when archived (or a hidden loan category), so it can be saved.
      final TransactionEntry? edit = ref.read(quickAddEditProvider);
      final List<Account> accounts = edit == null
          ? offeredAccounts(live)
          : _withOwnAccounts(live, edit);
      final OrderedCategories expense = orderCategories(
        offered: _withOwnCategory(
          offeredCategories(categories, CategoryKind.expense),
          categories,
          edit,
          CategoryKind.expense,
        ),
        usage: hints.usage[TransactionType.expense] ?? const <CategoryUsage>[],
        lastUsedId: hints.lastUsed[TransactionType.expense]?.categoryId,
      );
      final OrderedCategories income = orderCategories(
        offered: _withOwnCategory(
          offeredCategories(categories, CategoryKind.income),
          categories,
          edit,
          CategoryKind.income,
        ),
        usage: hints.usage[TransactionType.income] ?? const <CategoryUsage>[],
        lastUsedId: hints.lastUsed[TransactionType.income]?.categoryId,
      );
      return QuickAddData(
        accounts: accounts,
        expenseCategories: expense,
        incomeCategories: income,
        hints: hints,
        defaults: resolveDefaults(
          hints: hints,
          accounts: accounts,
          expenseCategories: expense,
          incomeCategories: income,
        ),
        recent: pickRecentEntries(
          hints.recent,
          offeredAccountIds: <String>{for (final Account a in accounts) a.id},
          offeredCategoryIds: <String>{
            for (final Category c in expense.all) c.id,
            for (final Category c in income.all) c.id,
          },
        ),
      );
    });

List<Account> _withOwnAccounts(List<Account> live, TransactionEntry edit) {
  final Set<String> own = <String>{edit.accountId, ?edit.toAccountId};
  return List<Account>.unmodifiable(
    live.where(
      (Account a) => a.deletedAt == null && (!a.archived || own.contains(a.id)),
    ),
  );
}

List<Category> _withOwnCategory(
  List<Category> offered,
  List<Category> live,
  TransactionEntry? edit,
  CategoryKind kind,
) {
  final String? id = edit?.categoryId;
  if (id == null || offered.any((Category c) => c.id == id)) return offered;
  for (final Category c in live) {
    if (c.id == id && c.kind == kind && c.deletedAt == null) {
      return List<Category>.unmodifiable(<Category>[...offered, c]);
    }
  }
  return offered;
}
