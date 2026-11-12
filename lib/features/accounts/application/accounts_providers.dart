import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/utils/no_retry.dart';
import '../data/accounts_repository.dart';
import '../domain/account.dart';

final Provider<AccountsRepository> accountsRepositoryProvider =
    Provider<AccountsRepository>(
      (Ref ref) => AccountsRepository(ref.watch(repositoryContextProvider)),
    );

/// Live accounts in display order.
final StreamProvider<List<Account>> accountsProvider =
    StreamProvider<List<Account>>(
      (Ref ref) => ref.watch(accountsRepositoryProvider).watchAll(),
    );

/// Live accounts with balances. Updates on every transaction change.
final StreamProvider<List<AccountBalance>> accountBalancesProvider =
    StreamProvider<List<AccountBalance>>(
      (Ref ref) => ref.watch(accountsRepositoryProvider).watchBalances(),
      retry: noRetry,
    );

/// Total of all live account balances (paise).
final StreamProvider<int> netWorthProvider = StreamProvider<int>(
  (Ref ref) => ref.watch(accountsRepositoryProvider).watchNetWorth(),
  retry: noRetry,
);
