import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/transaction_entry.dart';
import '../application/quick_add_data_provider.dart';
import '../domain/category_order.dart';
import '../domain/quick_add_validator.dart';
import 'widgets/quick_add_view_models.dart';

/// Chips shown in the category row before the list is opened: the suggested
/// categories (the same limit as the ordering rule). The picked category is
/// always shown too.
const int quickAddChipLimit = maxSuggestedCategories;

/// Earliest date the date picker offers.
final DateTime quickAddFirstDate = DateTime(1900, 1, 1);

/// The date picker's last day for [today]: today + [maxDaysAhead].
DateTime quickAddLastDate(DateTime today) =>
    DateTime(today.year, today.month, today.day + maxDaysAhead);

/// Parses a stored `YYYY-MM-DD` day (local midnight).
DateTime dayOf(String date) => DateTime.parse(date);

/// Chip data for one category.
CategoryChipData chipDataOf(Category c) => CategoryChipData(
  id: c.id,
  name: c.name,
  icon: c.icon,
  colourGroup: c.colourGroup.name,
);

/// Accounts for pills and pickers. Balances come from the account balance
/// stream; an account without one has no balance (none is shown).
List<AccountOption> accountOptionsOf(
  List<Account> accounts,
  Map<String, int> balances,
) => <AccountOption>[
  for (final Account a in accounts)
    AccountOption(
      id: a.id,
      name: a.name,
      colourToken: a.colour,
      balancePaise: balances[a.id],
    ),
];

/// The category with [id] among the expense and income lists, or null.
Category? categoryById(QuickAddData data, String? id) {
  if (id == null) return null;
  for (final Category c in <Category>[
    ...data.expenseCategories.all,
    ...data.incomeCategories.all,
  ]) {
    if (c.id == id) return c;
  }
  return null;
}

/// Recent chips: "Groceries" for a category, "SBI → Axis" for a transfer.
List<RecentEntryView> recentViewsOf(QuickAddData data) {
  final Map<String, String> names = <String, String>{
    for (final Account a in data.accounts) a.id: a.name,
  };
  return <RecentEntryView>[
    for (final TransactionEntry e in data.recent)
      if (e.type == TransactionType.transfer)
        RecentEntryView(
          type: e.type,
          amountPaise: e.amount,
          label: '${names[e.accountId] ?? ''} › ${names[e.toAccountId] ?? ''}',
          colourGroup: 'other',
        )
      else
        RecentEntryView(
          type: e.type,
          amountPaise: e.amount,
          label: categoryById(data, e.categoryId)?.name ?? 'Entry',
          colourGroup:
              categoryById(data, e.categoryId)?.colourGroup.name ?? 'other',
          categoryIcon: categoryById(data, e.categoryId)?.icon,
        ),
  ];
}

/// The chips for the category row: the first [quickAddChipLimit] offered
/// categories, plus the picked one when it is not among them.
List<Category> visibleCategories(List<Category> all, String? selectedId) {
  final List<Category> visible = all.take(quickAddChipLimit).toList();
  if (selectedId != null && visible.every((Category c) => c.id != selectedId)) {
    for (final Category c in all) {
      if (c.id == selectedId) visible.add(c);
    }
  }
  return visible;
}
