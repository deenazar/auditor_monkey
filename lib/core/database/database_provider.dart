import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/logger_provider.dart';
import '../utils/clock.dart';
import '../utils/id_generator.dart';
import 'app_database.dart';
import 'connection/open_connection.dart';
import 'repository_support.dart';

/// The one database for the app. Closed when the provider is disposed.
/// Tests override it with an in-memory `AppDatabase`.
final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>((
  Ref ref,
) {
  final AppDatabase db = AppDatabase(
    openAppConnection(),
    logger: ref.watch(loggerProvider),
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(db.close);
  return db;
});

/// Shared tools for every repository (database, clock, ids, logger).
final Provider<RepositoryContext> repositoryContextProvider =
    Provider<RepositoryContext>(
      (Ref ref) => RepositoryContext(
        db: ref.watch(appDatabaseProvider),
        clock: ref.watch(clockProvider),
        ids: ref.watch(idGeneratorProvider),
        logger: ref.watch(loggerProvider),
      ),
    );
