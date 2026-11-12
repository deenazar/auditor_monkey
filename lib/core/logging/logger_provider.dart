import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_logger.dart';

/// Access the logger from widgets and providers. Override in tests.
final Provider<AppLogger> loggerProvider = Provider<AppLogger>(
  (Ref ref) => AppLogger.instance,
);
