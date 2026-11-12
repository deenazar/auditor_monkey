import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/logging/app_logger.dart';
import 'core/utils/no_retry.dart';

void main() {
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

  // Show the Outfit font license (OFL) on the licenses page.
  LicenseRegistry.addLicense(() async* {
    final String text = await rootBundle.loadString(
      'assets/fonts/outfit/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(<String>['Outfit font'], text);
  });

  logger.info('app', 'app started');
  runApp(const ProviderScope(retry: noRetry, child: AuditorMonkeyApp()));
}
