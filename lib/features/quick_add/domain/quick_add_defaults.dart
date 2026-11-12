import '../../../core/database/seed/default_categories.dart';
import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/transaction_entry.dart';
import 'category_order.dart';
import 'quick_add_hints.dart';

/// Accounts Quick Add offers: live and not archived, in the order given.
List<Account> offeredAccounts(List<Account> live) => List<Account>.unmodifiable(
  live.where((Account a) => !a.archived && a.deletedAt == null),
);

/// Categories Quick Add offers: live, not archived, and not one of the 4
/// loan categories (hidden until loan screens exist; see [loanCategoryIds]).
/// Sorted by sort order, then id.
List<Category> offeredCategories(List<Category> live, CategoryKind kind) {
  final List<Category> out = <Category>[
    for (final Category c in live)
      if (c.kind == kind &&
          !c.archived &&
          c.deletedAt == null &&
          !loanCategoryIds.contains(c.id))
        c,
  ];
  out.sort((Category a, Category b) {
    final int c = a.sortOrder.compareTo(b.sortOrder);
    return c != 0 ? c : a.id.compareTo(b.id);
  });
  return List<Category>.unmodifiable(out);
}

/// The default choices for one type (all null when nothing can be offered).
class DefaultPicks {
  const DefaultPicks({this.accountId, this.toAccountId, this.categoryId});

  static const DefaultPicks none = DefaultPicks();

  final String? accountId;
  final String? toAccountId;
  final String? categoryId;
}

/// Defaults for all three types.
class QuickAddDefaults {
  const QuickAddDefaults({
    required this.expense,
    required this.income,
    required this.transfer,
    required this.transferAvailable,
  });

  final DefaultPicks expense;
  final DefaultPicks income;
  final DefaultPicks transfer;

  /// Transfer needs at least two offered accounts.
  final bool transferAvailable;

  DefaultPicks of(TransactionType type) => switch (type) {
    TransactionType.expense => expense,
    TransactionType.income => income,
    TransactionType.transfer => transfer,
  };
}

/// Resolves defaults (pure Dart).
///
/// Expense / income: last used account and category if still offered, else
/// the first offered account and the first category in display order.
/// Transfer: From = last transfer's From if offered, else the expense
/// default account; To = last transfer's To if offered and not From, else
/// the first offered account that is not From.
QuickAddDefaults resolveDefaults({
  required QuickAddHints hints,
  required List<Account> accounts,
  required OrderedCategories expenseCategories,
  required OrderedCategories incomeCategories,
}) {
  final Set<String> accountIds = <String>{
    for (final Account a in accounts) a.id,
  };
  String? firstAccount() => accounts.isEmpty ? null : accounts.first.id;

  DefaultPicks forKind(TransactionType type, OrderedCategories ordered) {
    final LastUsedPick? last = hints.lastUsed[type];
    final String? account = last != null && accountIds.contains(last.accountId)
        ? last.accountId
        : firstAccount();
    final String? lastCategory = last?.categoryId;
    final List<Category> all = ordered.all;
    final bool lastOffered =
        lastCategory != null && all.any((Category c) => c.id == lastCategory);
    final String? category = lastOffered
        ? lastCategory
        : (all.isEmpty ? null : all.first.id);
    return DefaultPicks(accountId: account, categoryId: category);
  }

  final DefaultPicks expense = forKind(
    TransactionType.expense,
    expenseCategories,
  );
  final DefaultPicks income = forKind(TransactionType.income, incomeCategories);

  final bool transferAvailable = accounts.length >= 2;
  DefaultPicks transfer = DefaultPicks.none;
  if (transferAvailable) {
    final LastUsedPick? last = hints.lastUsed[TransactionType.transfer];
    final String from = last != null && accountIds.contains(last.accountId)
        ? last.accountId
        : (expense.accountId ?? accounts.first.id);
    final String? lastTo = last?.toAccountId;
    final String to =
        lastTo != null && lastTo != from && accountIds.contains(lastTo)
        ? lastTo
        : accounts.firstWhere((Account a) => a.id != from).id;
    transfer = DefaultPicks(accountId: from, toAccountId: to);
  }
  return QuickAddDefaults(
    expense: expense,
    income: income,
    transfer: transfer,
    transferAvailable: transferAvailable,
  );
}
