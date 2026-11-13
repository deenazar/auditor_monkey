import 'package:auditor_monkey/features/accounts/presentation/account_statement_screen.dart';
import 'package:auditor_monkey/features/accounts/presentation/accounts_screen.dart';
import 'package:auditor_monkey/features/setup/presentation/setup_wizard_screen.dart';
import 'package:auditor_monkey/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'golden.dart' show setPhoneSurface;
import 'provider_env.dart';
import 'test_env.dart';

/// A widget test with an in-memory database. The app is removed at the end
/// so database streams close and no timer is left pending.
void testWithEnv(
  String name,
  Future<void> Function(WidgetTester tester, TestEnv env) body,
) {
  testWidgets(name, (WidgetTester tester) async {
    final TestEnv env = TestEnv();
    addTearDown(env.close);
    await body(tester, env);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });
}

/// Pumps [home] with the in-memory database of [env] (no router).
Future<void> pumpWithEnv(
  WidgetTester tester,
  TestEnv env,
  Widget home, {
  List<Override> extra = const <Override>[],
  double textScale = 1,
  bool reduceMotion = true,
}) async {
  setPhoneSurface(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[...envOverrides(env), ...extra],
      child: MaterialApp(
        theme: AppTheme.light(),
        debugShowCheckedModeBanner: false,
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pump();
}

/// Pumps the Accounts and statement screens, and the wizard, behind a real
/// router, so taps that navigate work. [initial] is the first location.
Future<void> pumpRouted(
  WidgetTester tester,
  TestEnv env, {
  String initial = '/accounts',
  List<Override> extra = const <Override>[],
  double textScale = 1,
}) async {
  setPhoneSurface(tester);
  final GoRouter router = GoRouter(
    initialLocation: initial,
    routes: <RouteBase>[
      GoRoute(
        path: '/accounts',
        builder: (BuildContext context, GoRouterState state) =>
            const AccountsScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: ':accountId',
            builder: (BuildContext context, GoRouterState state) =>
                AccountStatementScreen(
                  accountId: state.pathParameters['accountId'] ?? '',
                ),
          ),
        ],
      ),
      GoRoute(
        path: '/setup',
        builder: (BuildContext context, GoRouterState state) =>
            const SetupWizardScreen(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[...envOverrides(env), ...extra],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump();
}
