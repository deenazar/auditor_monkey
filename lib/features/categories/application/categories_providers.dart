import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/categories_repository.dart';
import '../domain/category.dart';

final Provider<CategoriesRepository> categoriesRepositoryProvider =
    Provider<CategoriesRepository>(
      (Ref ref) => CategoriesRepository(ref.watch(repositoryContextProvider)),
    );

/// Live expense categories in display order.
final StreamProvider<List<Category>> expenseCategoriesProvider =
    StreamProvider<List<Category>>(
      (Ref ref) => ref
          .watch(categoriesRepositoryProvider)
          .watchAll(kind: CategoryKind.expense),
    );

/// Live income categories in display order.
final StreamProvider<List<Category>> incomeCategoriesProvider =
    StreamProvider<List<Category>>(
      (Ref ref) => ref
          .watch(categoriesRepositoryProvider)
          .watchAll(kind: CategoryKind.income),
    );
