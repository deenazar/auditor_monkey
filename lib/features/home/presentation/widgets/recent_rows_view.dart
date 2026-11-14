import '../../../../core/utils/date_labels.dart';
import '../../../accounts/domain/account.dart';
import '../../../categories/domain/category.dart';
import '../../../transactions/domain/transaction_entry.dart';
import 'recent_row.dart';

/// Resolves ids to names and icons for the rows of "Recent transactions".
/// [today] is `YYYY-MM-DD`; future dates keep their date label.
List<RecentRowView> buildRecentRows(
  List<TransactionEntry> entries,
  List<Category> categories,
  List<Account> accounts,
  String today,
) {
  final Map<String, Category> cats = <String, Category>{
    for (final Category c in categories) c.id: c,
  };
  final Map<String, String> accs = <String, String>{
    for (final Account a in accounts) a.id: a.name,
  };
  return <RecentRowView>[
    for (final TransactionEntry e in entries) _view(e, cats, accs, today),
  ];
}

RecentRowView _view(
  TransactionEntry e,
  Map<String, Category> cats,
  Map<String, String> accs,
  String today,
) {
  final String account = accs[e.accountId] ?? 'Account';
  final String when = e.date == today
      ? 'Today'
      : shortDateLabel(e.date, todayKey: today);
  final String note = (e.note ?? '').trim();
  if (e.type == TransactionType.transfer) {
    return RecentRowView(
      entry: e,
      title: '$account to ${accs[e.toAccountId] ?? 'Account'}',
      account: 'Transfer',
      date: when,
      iconName: '',
      colourGroup: 'other',
    );
  }
  final Category? cat = cats[e.categoryId];
  return RecentRowView(
    entry: e,
    title: cat?.name ?? (note.isNotEmpty ? note : 'Entry'),
    account: account,
    date: when,
    iconName: cat?.icon ?? '',
    colourGroup: e.type == TransactionType.income
        ? 'income'
        : cat?.colourGroup.name ?? 'other',
  );
}
