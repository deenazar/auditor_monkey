import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/connection/open_connection.dart';
import '../../../core/database/database_files.dart';
import '../../../core/logging/logger_provider.dart';
import '../../../core/utils/clock.dart';
import '../data/demo_files.dart';
import '../data/demo_seeder.dart';

const String _tag = 'demo';

/// Whether demo mode was on at app start. `main` overrides it with the
/// marker file; always false in release builds.
final Provider<bool> demoModeInitialProvider = Provider<bool>(
  (Ref ref) => false,
);

/// True while demo data is shown (debug and profile builds only).
final Provider<bool> demoModeActiveProvider = Provider<bool>(
  (Ref ref) => !kReleaseMode && ref.watch(demoModeControllerProvider),
);

/// Loads and clears demo data. The real database file is never written.
final NotifierProvider<DemoModeController, bool> demoModeControllerProvider =
    NotifierProvider<DemoModeController, bool>(DemoModeController.new);

class DemoModeController extends Notifier<bool> {
  @override
  bool build() => !kReleaseMode && ref.read(demoModeInitialProvider);

  /// Creates a fresh demo file, fills it and switches the app to it.
  Future<void> load() async {
    if (kReleaseMode || state) return;
    final logger = ref.read(loggerProvider);
    final DatabaseDirectory dirFn =
        ref.read(databaseDirectoryProvider) ?? defaultDatabaseDirectory;
    final files = DemoFiles(await dirFn());
    await files.deleteDatabase();
    final AppDatabase db = AppDatabase(
      openAppConnection(fileName: demoDatabaseFileName, directory: dirFn),
      logger: logger,
      clock: ref.read(clockProvider),
    );
    try {
      await seedDemoData(db, clock: ref.read(clockProvider), logger: logger);
      await db.close();
    } catch (error) {
      logger.error(_tag, 'load demo data failed', error: error);
      await db.close();
      await files.deleteDatabase();
      rethrow;
    }
    await files.writeMarker();
    state = true;
    logger.info(_tag, 'demo mode on');
  }

  /// Switches back to the real file, then deletes the demo file and marker.
  Future<void> clear() async {
    if (kReleaseMode || !state) return;
    final logger = ref.read(loggerProvider);
    final DatabaseDirectory dirFn =
        ref.read(databaseDirectoryProvider) ?? defaultDatabaseDirectory;
    final files = DemoFiles(await dirFn());
    await files.deleteMarker();
    state = false;
    // Close the demo database before its file goes away.
    await ref.read(databaseCloseTrackerProvider).closeDemoAndWait();
    await files.deleteDatabase();
    logger.info(_tag, 'demo mode off');
  }
}
