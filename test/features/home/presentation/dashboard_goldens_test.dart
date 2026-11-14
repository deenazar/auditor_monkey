// Golden tests of the Dashboard sections on Home (plan T6): the real section
// widgets from home_sections.dart stacked the way Home shows them, below
// the hero. The numbers come from the October 2026 fixture read through
// DashboardRepository, so the pictures show the plan's numbers.
@Tags(<String>['golden'])
library;

import 'dart:async';

import 'package:auditor_monkey/features/accounts/application/accounts_providers.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/categories/application/categories_providers.dart';
import 'package:auditor_monkey/features/categories/domain/category.dart';
import 'package:auditor_monkey/features/home/application/dashboard_providers.dart';
import 'package:auditor_monkey/features/home/data/dashboard_repository.dart';
import 'package:auditor_monkey/features/home/domain/dashboard_summary.dart';
import 'package:auditor_monkey/features/home/presentation/widgets/home_recent_section.dart';
import 'package:auditor_monkey/features/home/presentation/widgets/home_sections.dart';
import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fixtures/test_month_2026_10.dart';
import '../../../support/golden.dart';
import '../../../support/home_fixtures.dart';
import '../../../support/rupee_golden.dart';

/// Tall enough for the five sections (about 1.9 phone heights).
const double _sectionsHeight = 2000;

/// The October fixture, read once per test.
class _October {
  _October({
    required this.summary,
    required this.balances,
    required this.categories,
    required this.accounts,
  });

  final DashboardSummary summary;
  final List<AccountBalance> balances;
  final List<Category> categories;
  final List<Account> accounts;
}

/// Builds the fixture and reads it (in real async time, the database is
/// real SQLite).
Future<_October> _loadOctober(WidgetTester tester) async {
  final _October? data = await tester.runAsync(() async {
    final TestMonth m = await buildTestMonth();
    final DashboardSummary s = await DashboardRepository(m.env.ctx)
        .load(today: '2026-10-31');
    final List<AccountBalance> b = await m.env.accounts.getBalances();
    final List<Category> c = await m.env.categories.watchAll().first;
    final List<Account> a = await m.env.accounts.watchAll().first;
    await m.close();
    return _October(summary: s, balances: b, categories: c, accounts: a);
  });
  return data!;
}

/// The same summary with a different budget total (and the matching
/// remaining comes from the new total).
DashboardSummary _withBudget(DashboardSummary s, int budget) =>
    DashboardSummary(
      today: s.today,
      month: s.month,
      days: s.days,
      spent: s.spent,
      income: s.income,
      budgetTotal: budget,
      topCategories: s.topCategories,
      recent: s.recent,
    );

/// Overrides for the dashboard sections. [summary] or [summaryError] feeds
/// the month summary; [summaryLoading] keeps it loading. The same for the
/// balances.
List<Override> _overrides(
  _October data, {
  DashboardSummary? summary,
  Object? summaryError,
  bool summaryLoading = false,
  List<AccountBalance>? balances,
  bool balancesLoading = false,
}) {
  final DashboardSummary? s = summary;
  return <Override>[
    dashboardSummaryProvider.overrideWith((Ref ref) {
      if (summaryLoading) return _never<DashboardSummary>();
      if (summaryError != null) {
        return Stream<DashboardSummary>.error(summaryError);
      }
      return Stream<DashboardSummary>.value(s ?? data.summary);
    }),
    accountBalancesProvider.overrideWith((Ref ref) {
      if (balancesLoading) return _never<List<AccountBalance>>();
      return Stream<List<AccountBalance>>.value(balances ?? data.balances);
    }),
    expenseCategoriesProvider.overrideWith(
      (Ref ref) => Stream<List<Category>>.value(<Category>[
        for (final Category c in data.categories)
          if (c.kind == CategoryKind.expense) c,
      ]),
    ),
    incomeCategoriesProvider.overrideWith(
      (Ref ref) => Stream<List<Category>>.value(<Category>[
        for (final Category c in data.categories)
          if (c.kind == CategoryKind.income) c,
      ]),
    ),
    accountsProvider.overrideWith(
      (Ref ref) => Stream<List<Account>>.value(data.accounts),
    ),
  ];
}

/// A stream that never emits (a provider stuck loading).
Stream<T> _never<T>() => StreamController<T>().stream;

/// The dashboard sections in Home's order, stacked on a tall surface.
class _DashboardSections extends ConsumerWidget {
  const _DashboardSections();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DashboardSummary> async = ref.watch(
      dashboardSummaryProvider,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MonthTilesSection(summary: async, index: 0),
          StatTilesSection(summary: async, index: 1),
          const SizedBox(height: AppSpacing.space8),
          const BalanceSection(index: 2),
          const SizedBox(height: AppSpacing.space6),
          TopSpendingSection(summary: async, index: 3),
          const SizedBox(height: AppSpacing.space6),
          RecentSection(summary: async, firstIndex: 4, onDeleted: () {}),
        ],
      ),
    );
  }
}

/// Pumps the sections on a tall phone surface and returns when settled.
/// [settle] false pumps one frame (for skeletons that never stop).
Future<void> _pumpSections(
  WidgetTester tester,
  List<Override> overrides, {
  double textScale = 1,
  bool settle = true,
}) async {
  setGoldenSurface(tester);
  tester.view.physicalSize = const Size(
    goldenWidth * goldenPixelRatio,
    _sectionsHeight * goldenPixelRatio,
  );
  await tester.pumpWidget(
    rupeeGoldenApp(
      const Scaffold(
        backgroundColor: AppColors.canvas,
        body: SingleChildScrollView(child: _DashboardSections()),
      ),
      overrides: overrides,
      textScale: textScale,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  testWidgets('golden: dashboard_data (October 2026 fixture)', (
    WidgetTester tester,
  ) async {
    final _October data = await _loadOctober(tester);
    await _pumpSections(tester, _overrides(data));
    await expectGolden(tester, 'dashboard_data');
  });

  testWidgets('golden: dashboard_loading (skeletons)', (
    WidgetTester tester,
  ) async {
    final _October data = await _loadOctober(tester);
    await _pumpSections(
      tester,
      _overrides(data, summaryLoading: true, balancesLoading: true),
      settle: false,
    );
    await expectGolden(tester, 'dashboard_loading');
  });

  testWidgets('golden: dashboard_empty_month (empty top spending)', (
    WidgetTester tester,
  ) async {
    final _October data = await _loadOctober(tester);
    await _pumpSections(
      tester,
      _overrides(data, summary: homeDashboard(emptyHomeSummary())),
    );
    await expectGolden(tester, 'dashboard_empty_month');
  });

  testWidgets('golden: dashboard_no_budget', (WidgetTester tester) async {
    final _October data = await _loadOctober(tester);
    await _pumpSections(
      tester,
      _overrides(data, summary: _withBudget(data.summary, 0)),
    );
    await expectGolden(tester, 'dashboard_no_budget');
  });

  testWidgets('golden: dashboard_over_budget', (WidgetTester tester) async {
    final _October data = await _loadOctober(tester);
    await _pumpSections(
      tester,
      _overrides(data, summary: _withBudget(data.summary, 100000)),
    );
    await expectGolden(tester, 'dashboard_over_budget');
  });

  testWidgets('golden: dashboard_only_negative (owed line + mascot)', (
    WidgetTester tester,
  ) async {
    final _October data = await _loadOctober(tester);
    final List<AccountBalance> owed = <AccountBalance>[
      for (final AccountBalance b in data.balances)
        if (b.balance < 0) b,
    ];
    await _pumpSections(tester, _overrides(data, balances: owed));
    await expectGolden(tester, 'dashboard_only_negative');
  });

  testWidgets('golden: dashboard_section_error (summary failed)', (
    WidgetTester tester,
  ) async {
    final _October data = await _loadOctober(tester);
    await _pumpSections(
      tester,
      _overrides(data, summaryError: StateError('offline')),
    );
    await expectGolden(tester, 'dashboard_section_error');
  });

  testWidgets('golden: dashboard_text_scale_2', (WidgetTester tester) async {
    final _October data = await _loadOctober(tester);
    await _pumpSections(tester, _overrides(data), textScale: 2);
    await expectGolden(tester, 'dashboard_text_scale_2');
  });

  testWidgets('golden: dashboard_slice_selected', (WidgetTester tester) async {
    final _October data = await _loadOctober(tester);
    await _pumpSections(tester, _overrides(data));
    await tester.tap(find.bySemanticsLabel('SBI, ₹80,000.00, 40%'));
    await tester.pump(const Duration(milliseconds: 300));
    await expectGolden(tester, 'dashboard_slice_selected');
  });
}
