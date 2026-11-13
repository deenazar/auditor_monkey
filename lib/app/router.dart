import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/database/database_provider.dart';
import '../core/logging/app_logger.dart';
import '../features/accounts/presentation/account_statement_screen.dart';
import '../features/accounts/presentation/accounts_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/setup/application/setup_providers.dart';
import '../features/setup/presentation/setup_wizard_screen.dart';
import '../features/setup/presentation/start_screen.dart';
import '../features/transactions/presentation/transaction_detail_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../shared/theme/app_motion.dart';

import '../shared/widgets/fade_indexed_stack.dart';
import '../shared/widgets/shared_axis_transition.dart';
import 'app_shell.dart';

abstract final class AppRoutes {
  static const String home = '/home';
  static const String insights = '/insights';
  static const String transactions = '/transactions';
  static const String accounts = '/accounts';

  /// Shown while the app opens its data (and when it cannot).
  static const String start = '/start';

  /// The setup wizard (all four steps live on this one route).
  static const String setup = '/setup';

  /// Route name of the statement (child of the Accounts branch).
  static const String accountStatementName = 'account-statement';

  /// Route name of the transaction detail (child of the Transactions branch).
  static const String transactionDetailName = 'transaction-detail';

  /// Path of one entry's detail. [transactionId] is put in the path as is;
  /// the screen checks it.
  static String transactionDetail(String transactionId) =>
      '$transactions/${Uri.encodeComponent(transactionId)}';

  /// Path of one account's statement. [accountId] is put in the path as is;
  /// the screen checks it.
  static String accountStatement(String accountId) =>
      '$accounts/${Uri.encodeComponent(accountId)}';
}

/// Where the app must go for the current "setup done" status, or `null` to
/// stay. Pure, so it is unit tested.
///
/// - Still loading or failed: `/start` (the start screen shows which).
///   The place the person wanted is kept in `?from=` and used afterwards.
/// - No accounts: `/setup`.
/// - Accounts exist: `/start` goes to `from` (or Home), and `/setup` (the
///   wizard just finished) goes to Accounts.
String? resolveSetupRedirect({
  required Uri location,
  required AsyncValue<bool> status,
}) {
  final String path = location.path;
  final bool? done = status.hasValue ? status.requireValue : null;
  if (done == null) {
    if (path == AppRoutes.start) return null;
    final String target = path == AppRoutes.setup ? '' : location.toString();
    return Uri(
      path: AppRoutes.start,
      queryParameters: target.isEmpty ? null : <String, String>{'from': target},
    ).toString();
  }
  if (!done) return path == AppRoutes.setup ? null : AppRoutes.setup;
  if (path == AppRoutes.setup) return AppRoutes.accounts;
  if (path == AppRoutes.start) {
    return _safeFrom(location.queryParameters['from']) ?? AppRoutes.home;
  }
  return null;
}

/// Only in-app paths may be used as the place to return to.
String? _safeFrom(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return null;
  }
  final String path = Uri.tryParse(from)?.path ?? '';
  if (path.isEmpty || path == AppRoutes.start || path == AppRoutes.setup) {
    return null;
  }
  return from;
}

/// Creates a new router. Call once per app instance (never a global), so
/// tests do not share navigation state.
///
/// [setupStatus] says whether setup is done (from Riverpod in the app);
/// [refreshListenable] must notify when it changes so the redirect runs
/// again. Without them the router assumes setup is done.
GoRouter createAppRouter({
  AppLogger? logger,
  String initialLocation = AppRoutes.home,
  AsyncValue<bool> Function()? setupStatus,
  Listenable? refreshListenable,
}) {
  final AppLogger log = logger ?? AppLogger.instance;
  final AsyncValue<bool> Function() status =
      setupStatus ?? () => const AsyncData<bool>(true);
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
    redirect: (BuildContext context, GoRouterState state) {
      final String? target = resolveSetupRedirect(
        location: state.uri,
        status: status(),
      );
      if (target != null) {
        log.debug('nav', 'redirect ${Uri.parse(target).path}');
      }
      return target;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.start,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            NoTransitionPage<void>(
              key: state.pageKey,
              child: const _StartRoute(),
            ),
      ),
      GoRoute(
        path: AppRoutes.setup,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            NoTransitionPage<void>(
              key: state.pageKey,
              child: const SetupWizardScreen(),
            ),
      ),
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
          _branch(
            AppRoutes.transactions,
            const TransactionsScreen(),
            children: <RouteBase>[
              GoRoute(
                path: ':transactionId',
                name: AppRoutes.transactionDetailName,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    _slidePage(
                      context,
                      state,
                      TransactionDetailScreen(
                        transactionId:
                            state.pathParameters['transactionId'] ?? '',
                      ),
                    ),
              ),
            ],
          ),
          _branch(
            AppRoutes.accounts,
            const AccountsScreen(),
            children: <RouteBase>[
              GoRoute(
                path: ':accountId',
                name: AppRoutes.accountStatementName,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    _slidePage(
                      context,
                      state,
                      AccountStatementScreen(
                        accountId: state.pathParameters['accountId'] ?? '',
                      ),
                    ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

StatefulShellBranch _branch(
  String path,
  Widget screen, {
  List<RouteBase> children = const <RouteBase>[],
}) {
  return StatefulShellBranch(
    routes: <RouteBase>[
      GoRoute(
        path: path,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            NoTransitionPage<void>(key: state.pageKey, child: screen),
        routes: children,
      ),
    ],
  );
}

/// Child page: shared-axis push (see [SharedAxisTransition]).
Page<void> _slidePage(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.durationMedium,
    reverseTransitionDuration: AppMotion.durationMedium,
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) => SharedAxisTransition(animation: animation, child: child),
  );
}

/// `/start`: loading ring, or a safe message when the data cannot be read.
class _StartRoute extends ConsumerWidget {
  const _StartRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> status = ref.watch(setupCompleteProvider);
    final bool failed = status.hasError && !status.hasValue;
    return StartScreen(
      error: failed ? status.error : null,
      // Opening the database again is harmless; nothing is deleted.
      onRetry: failed ? () => ref.invalidate(appDatabaseProvider) : null,
    );
  }
}
