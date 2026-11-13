import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/logging/logger_provider.dart';
import '../features/setup/application/setup_providers.dart';
import '../shared/theme/app_theme.dart';
import 'router.dart';

/// Root widget. Creates its own router, so every app instance (and every
/// widget test) has separate navigation state.
class AuditorMonkeyApp extends ConsumerStatefulWidget {
  const AuditorMonkeyApp({this.initialLocation = AppRoutes.home, super.key});

  final String initialLocation;

  @override
  ConsumerState<AuditorMonkeyApp> createState() => _AuditorMonkeyAppState();
}

class _AuditorMonkeyAppState extends ConsumerState<AuditorMonkeyApp> {
  /// Tells the router to run its redirect again when "setup done" changes
  /// (a bridge from Riverpod to go_router).
  final _Notifier _setupChanged = _Notifier();
  ProviderSubscription<AsyncValue<bool>>? _setupSub;

  late final GoRouter _router = createAppRouter(
    logger: ref.read(loggerProvider),
    initialLocation: widget.initialLocation,
    setupStatus: () => ref.read(setupCompleteProvider),
    refreshListenable: _setupChanged,
  );

  @override
  void initState() {
    super.initState();
    _setupSub = ref.listenManual<AsyncValue<bool>>(
      setupCompleteProvider,
      (AsyncValue<bool>? previous, AsyncValue<bool> next) =>
          _setupChanged.ping(),
    );
  }

  @override
  void dispose() {
    _setupSub?.close();
    _router.dispose();
    _setupChanged.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Auditor Monkey',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}

/// A [ChangeNotifier] that can be pinged from outside.
class _Notifier extends ChangeNotifier {
  void ping() => notifyListeners();
}
