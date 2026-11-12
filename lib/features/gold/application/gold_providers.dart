import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/gold_repository.dart';
import '../domain/gold.dart';

final Provider<GoldRepository> goldRepositoryProvider =
    Provider<GoldRepository>(
      (Ref ref) => GoldRepository(ref.watch(repositoryContextProvider)),
    );

/// Live gold holdings with current values.
final StreamProvider<List<GoldHoldingValue>> goldHoldingValuesProvider =
    StreamProvider<List<GoldHoldingValue>>(
      (Ref ref) => ref.watch(goldRepositoryProvider).watchHoldingValues(),
    );

/// Live gold rates, newest first.
final StreamProvider<List<GoldRate>> goldRatesProvider =
    StreamProvider<List<GoldRate>>(
      (Ref ref) => ref.watch(goldRepositoryProvider).watchRates(),
    );
