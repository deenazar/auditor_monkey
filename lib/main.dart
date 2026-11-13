import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/logging/app_logger.dart';
import 'core/utils/no_retry.dart';
import 'features/demo_data/application/demo_mode.dart';
import 'features/demo_data/data/demo_files.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppLogger logger = AppLogger.instance;
  FlutterError.onError = (FlutterErrorDetails details) {
    logger.error(
      'flutter',
      'framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    logger.error('platform', 'uncaught error', error: error, stackTrace: stack);
    return true;
  };

  // Show the font licenses (OFL) on the licenses page.
  LicenseRegistry.addLicense(() async* {
    for (final (String name, String dir) in <(String, String)>[
      ('Unbounded font', 'unbounded'),
      ('DM Sans font', 'dm_sans'),
      ('DM Mono font', 'dm_mono'),
    ]) {
      final String text = await rootBundle.loadString(
        'assets/fonts/$dir/OFL.txt',
      );
      yield LicenseEntryWithLineBreaks(<String>[name], text);
    }
  });

  logger.info('app', 'app started');
  // Debug and profile only: is demo mode left on from the last run?
  final bool demoOn = !kReleaseMode && await readDemoMarker();
  runApp(
    ProviderScope(
      retry: noRetry,
      overrides: [demoModeInitialProvider.overrideWithValue(demoOn)],
      child: const AuditorMonkeyApp(),
    ),
  );
}
