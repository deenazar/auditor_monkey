import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/logging/logger_provider.dart';
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
  late final GoRouter _router = createAppRouter(
    logger: ref.read(loggerProvider),
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
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
