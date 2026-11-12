import '../../transactions/domain/transaction_entry.dart';
import '../domain/quick_add_defaults.dart';
import 'quick_add_data_provider.dart';
import 'quick_add_state.dart';

/// What the screen shows for [type]: the user's own pick, else the default.
///
/// Before the data is loaded ([data] is null) only the user's own picks
/// exist. For a transfer, a To account equal to From (a default arriving
/// after the user chose From) falls back to the first other account.
DefaultPicks resolvePicks(
  TransactionType type,
  Picks picks,
  QuickAddData? data,
) {
  final DefaultPicks d = data?.defaults.of(type) ?? DefaultPicks.none;
  final String? account = picks.accountId ?? d.accountId;
  String? to = type == TransactionType.transfer
      ? (picks.toAccountId ?? d.toAccountId)
      : null;
  if (to != null && to == account && data != null) {
    to = _firstOtherAccount(data, account);
  }
  return DefaultPicks(
    accountId: account,
    toAccountId: to,
    categoryId: type == TransactionType.transfer
        ? null
        : (picks.categoryId ?? d.categoryId),
  );
}

String? _firstOtherAccount(QuickAddData data, String? not) {
  for (final account in data.accounts) {
    if (account.id != not) return account.id;
  }
  return null;
}
