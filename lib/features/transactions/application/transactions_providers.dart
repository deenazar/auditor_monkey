import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/transactions_repository.dart';

final Provider<TransactionsRepository> transactionsRepositoryProvider =
    Provider<TransactionsRepository>(
      (Ref ref) => TransactionsRepository(ref.watch(repositoryContextProvider)),
    );
