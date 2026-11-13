import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/demo_data/application/demo_mode.dart';
import '../logging/logger_provider.dart';
import '../utils/clock.dart';
import '../utils/id_generator.dart';
import 'app_database.dart';
import 'connection/open_connection.dart';
import 'database_files.dart';
import 'repository_support.dart';

/// The one database for the app. Closed when the provider is disposed.
/// Tests override it with an in-memory `AppDatabase`.
///
/// In debug and profile builds it follows demo mode: the demo file is opened
/// instead of the real one. `kReleaseMode` is a compile-time constant, so
/// release builds drop this branch.
final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>((
  Ref ref,
) {
  final bool demo = !kReleaseMode && ref.watch(demoModeActiveProvider);
  final AppDatabase db = AppDatabase(
    openAppConnection(
      fileName: demo ? demoDatabaseFileName : databaseFileName,
      directory: ref.watch(databaseDirectoryProvider),
    ),
    logger: ref.watch(loggerProvider),
    clock: ref.watch(clockProvider),
  );
  final DatabaseCloseTracker tracker = ref.read(databaseCloseTrackerProvider);
  tracker.opened(db, demo: demo);
  ref.onDispose(() => tracker.dropped(db));
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
