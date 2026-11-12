import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/logging/app_logger.dart';
import '../features/accounts/presentation/accounts_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../shared/widgets/fade_indexed_stack.dart';
import 'app_shell.dart';

abstract final class AppRoutes {
  static const String home = '/home';
  static const String insights = '/insights';
  static const String transactions = '/transactions';
  static const String accounts = '/accounts';
}

/// Creates a new router. Call once per app instance (never a global), so
/// tests do not share navigation state.
GoRouter createAppRouter({
  AppLogger? logger,
  String initialLocation = AppRoutes.home,
}) {
  final AppLogger log = logger ?? AppLogger.instance;
  return GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      StatefulShellRoute(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) => navigationShell,
        navigatorContainerBuilder:
            (
              BuildContext context,
              StatefulNavigationShell navigationShell,
              List<Widget> children,
            ) => AppShell(
              navigationShell: navigationShell,
              logger: log,
              body: FadeIndexedStack(
                index: navigationShell.currentIndex,
                children: children,
              ),
            ),
        branches: <StatefulShellBranch>[
          _branch(AppRoutes.home, const HomeScreen()),
          _branch(AppRoutes.insights, const InsightsScreen()),
          _branch(AppRoutes.transactions, const TransactionsScreen()),
          _branch(AppRoutes.accounts, const AccountsScreen()),
        ],
      ),
    ],
  );
}

StatefulShellBranch _branch(String path, Widget screen) {
  return StatefulShellBranch(
    routes: <RouteBase>[
      GoRoute(
        path: path,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            NoTransitionPage<void>(key: state.pageKey, child: screen),
      ),
    ],
  );
}
