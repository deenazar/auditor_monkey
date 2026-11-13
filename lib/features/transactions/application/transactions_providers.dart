import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/transactions_list_repository.dart';
import '../data/transactions_repository.dart';

final Provider<TransactionsRepository> transactionsRepositoryProvider =
    Provider<TransactionsRepository>(
      (Ref ref) => TransactionsRepository(ref.watch(repositoryContextProvider)),
    );

final Provider<TransactionsListRepository> transactionsListRepositoryProvider =
    Provider<TransactionsListRepository>(
      (Ref ref) =>
          TransactionsListRepository(ref.watch(repositoryContextProvider)),
    );
