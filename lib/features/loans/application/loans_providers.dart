import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/loans_repository.dart';
import '../domain/loan.dart';

final Provider<LoansRepository> loansRepositoryProvider =
    Provider<LoansRepository>(
      (Ref ref) => LoansRepository(ref.watch(repositoryContextProvider)),
    );

/// Live loans with outstanding amounts.
final StreamProvider<List<LoanSummary>> loanSummariesProvider =
    StreamProvider<List<LoanSummary>>(
      (Ref ref) => ref.watch(loansRepositoryProvider).watchSummaries(),
    );
