import '../../transactions/domain/transaction_entry.dart';

/// Most recent entries the strip shows.
const int maxRecentEntries = 6;

/// Entries the strip may repeat: the newest first, distinct, max 6.
///
/// Kept: rows whose account, To account and category are all offered.
/// Rows with the same (type, amount, account, To, category, note) collapse
/// into the newest one. The entry's date is never used (the form keeps its
/// own date).
List<TransactionEntry> pickRecentEntries(
  List<TransactionEntry> newestFirst, {
  required Set<String> offeredAccountIds,
  required Set<String> offeredCategoryIds,
}) {
  final Set<String> seen = <String>{};
  final List<TransactionEntry> out = <TransactionEntry>[];
  for (final TransactionEntry e in newestFirst) {
    if (!offeredAccountIds.contains(e.accountId)) continue;
    final String? to = e.toAccountId;
    if (to != null && !offeredAccountIds.contains(to)) continue;
    final String? category = e.categoryId;
    if (category != null && !offeredCategoryIds.contains(category)) continue;
    final String key = <Object?>[
      e.type.name,
      e.amount,
      e.accountId,
      to,
      category,
      (e.note ?? '').trim(),
    ].join('\u0001');
    if (!seen.add(key)) continue;
    out.add(e);
    if (out.length == maxRecentEntries) break;
  }
  return List<TransactionEntry>.unmodifiable(out);
}
