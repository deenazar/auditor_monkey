// Home wiring: drill-down filters, "See all", slice navigation, entry
// detail and section error isolation. Providers are faked, the router is a
// tiny one that only shows where it went.
import 'package:auditor_monkey/app/router.dart';
import 'package:auditor_monkey/core/utils/clock.dart';
import 'package:auditor_monkey/features/accounts/application/accounts_providers.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/home/application/dashboard_providers.dart';
import 'package:auditor_monkey/features/home/domain/dashboard_summary.dart';
import 'package:auditor_monkey/features/home/presentation/home_screen.dart';
import 'package:auditor_monkey/features/home/presentation/widgets/doughnut_legend.dart';
import 'package:auditor_monkey/features/home/presentation/widgets/recent_row.dart';
import 'package:auditor_monkey/features/home/presentation/widgets/top_spending_card.dart';
import 'package:auditor_monkey/features/transactions/application/transactions_list_providers.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_filter.dart';
import 'package:auditor_monkey/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/golden.dart';
import '../../../support/home_fixtures.dart';

const String _sbiId = '11111112-1111-4111-8111-111111111112';

Future<GoRouter> _pump(
  WidgetTester t, {
  List<Override> extra = const <Override>[],
  int budget = 0,
  bool dashboard = true,
  bool balances = true,
}) async {
  setPhoneSurface(t);
  t.view.physicalSize = const Size(goldenWidth * 2, 3600 * 2);
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const Scaffold(body: HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.transactions,
        builder: (_, _) => const Scaffold(body: Text('TX LIST')),
        routes: <RouteBase>[
          GoRoute(
            path: ':id',
            builder: (_, _) => const Scaffold(body: Text('TX DETAIL')),
          ),
        ],
      ),
      GoRoute(
        path: '${AppRoutes.accounts}/:id',
        builder: (_, _) => const Scaffold(body: Text('STATEMENT')),
      ),
    ],
  );
  await t.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        clockProvider.overrideWithValue(goldenClock()),
        ...homeOverrides(
          homeSummary(),
          budget: budget,
          dashboard: dashboard,
          withBalances: balances,
        ),
        ...extra,
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        builder: (BuildContext c, Widget? child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  return router;
}

TransactionFilter _filter(WidgetTester t) =>
    ProviderScope.containerOf(t.element(find.byType(MaterialApp)))
        .read(transactionFilterProvider);

String _at(GoRouter r) => r.routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('Spent tap: this month + expense, opens Transactions', (
    WidgetTester t,
  ) async {
    final GoRouter r = await _pump(t);
    await t.tap(find.text('Spent this month'));
    await t.pumpAndSettle();
    final TransactionFilter f = _filter(t);
    expect(f.from, '2026-11-01');
    expect(f.to, '2026-11-30');
    expect(f.types, <TransactionType>{TransactionType.expense});
    expect(f.categoryIds, isEmpty);
    expect(f.query, '');
    expect(_at(r), AppRoutes.transactions);
  });

  testWidgets('Top spending row: month + expense + that category', (
    WidgetTester t,
  ) async {
    final GoRouter r = await _pump(t);
    await t.tap(
      find.descendant(
        of: find.byType(TopSpendingCard),
        matching: find.text('Groceries'),
      ),
    );
    await t.pumpAndSettle();
    final TransactionFilter f = _filter(t);
    expect(f.categoryIds, <String>{homeExpenseCategories[0].id});
    expect(f.types, <TransactionType>{TransactionType.expense});
    expect(f.from, '2026-11-01');
    expect(_at(r), AppRoutes.transactions);
  });

  testWidgets('See all clears the filter (and the search) and opens the tab', (
    WidgetTester t,
  ) async {
    final GoRouter r = await _pump(t);
    final ProviderContainer c = ProviderScope.containerOf(
      t.element(find.byType(MaterialApp)),
    );
    c.read(transactionFilterProvider.notifier)
      ..setQuery('milk')
      ..setFacets(
        const TransactionFilter(
          types: <TransactionType>{TransactionType.income},
        ),
      );
    await t.pump();
    await t.tap(find.text('See all'));
    await t.pumpAndSettle();
    expect(_filter(t), TransactionFilter.none);
    expect(_at(r), AppRoutes.transactions);
  });

  testWidgets('a slice: first tap selects, second tap opens the account', (
    WidgetTester t,
  ) async {
    final GoRouter r = await _pump(t);
    final Finder sbi = find.descendant(
      of: find.byType(DoughnutLegend),
      matching: find.text('SBI'),
    );
    await t.tap(sbi);
    await t.pumpAndSettle();
    expect(_at(r), AppRoutes.home);
    await t.tap(sbi);
    await t.pumpAndSettle();
    expect(_at(r), '${AppRoutes.accounts}/$_sbiId');
  });

  testWidgets('a recent row tap opens the entry detail', (
    WidgetTester t,
  ) async {
    final GoRouter r = await _pump(t);
    await t.tap(find.byType(RecentRow).first);
    await t.pumpAndSettle();
    expect(_at(r), startsWith('${AppRoutes.transactions}/'));
    expect(find.text('TX DETAIL'), findsOneWidget);
  });

  testWidgets('summary fails: month sections show Try again, doughnut works', (
    WidgetTester t,
  ) async {
    await _pump(
      t,
      dashboard: false,
      extra: <Override>[
        dashboardSummaryProvider.overrideWith(
          (Ref ref) => Stream<DashboardSummary>.error(StateError('x')),
        ),
      ],
    );
    expect(find.text('Try again'), findsWidgets);
    expect(find.byType(DoughnutLegend), findsOneWidget);
    expect(find.text('NET WORTH'), findsOneWidget);
    expect(find.byType(RecentRow), findsNothing);
  });

  testWidgets('balances fail: only the doughnut shows Try again', (
    WidgetTester t,
  ) async {
    await _pump(
      t,
      balances: false,
      extra: <Override>[
        accountBalancesProvider.overrideWith(
          (Ref ref) => Stream<List<AccountBalance>>.error(StateError('x')),
        ),
      ],
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(DoughnutLegend), findsNothing);
    expect(find.byType(TopSpendingCard), findsOneWidget);
    expect(find.byType(RecentRow), findsNWidgets(5));
  });

  testWidgets('no budget yet: the Budget tile says so', (WidgetTester t) async {
    await _pump(t);
    expect(find.text('No budget yet'), findsOneWidget);
  });
}
