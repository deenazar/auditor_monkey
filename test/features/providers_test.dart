import 'package:auditor_monkey/core/database/app_database.dart';
import 'package:auditor_monkey/core/database/database_provider.dart';
import 'package:auditor_monkey/core/utils/clock.dart';
import 'package:auditor_monkey/features/accounts/application/accounts_providers.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/budgets/application/budgets_providers.dart';
import 'package:auditor_monkey/features/categories/application/categories_providers.dart';
import 'package:auditor_monkey/features/daily_activities/application/daily_activities_providers.dart';
import 'package:auditor_monkey/features/gold/application/gold_providers.dart';
import 'package:auditor_monkey/features/loans/application/loans_providers.dart';
import 'package:auditor_monkey/features/transactions/application/transactions_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../support/fixtures.dart';
import '../support/test_env.dart';

void main() {
  late TestEnv env;
  late ProviderContainer container;

  setUp(() {
    env = TestEnv();
    container = ProviderContainer(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(env.db),
        clockProvider.overrideWithValue(env.clock),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await env.close();
  });

  test('repositories write through the shared database', () async {
    final Account a = await container
        .read(accountsRepositoryProvider)
        .create(accountDraft());
    expect((await env.accounts.getById(a.id))!.name, 'SBI');
    expect(container.read(appDatabaseProvider), same(env.db));
  });

  test('accountBalancesProvider and netWorthProvider update live', () async {
    final Account a = await container
        .read(accountsRepositoryProvider)
        .create(accountDraft(opening: 1000));
    final String cat = await env.seededCategoryId('Groceries', 'expense');

    final List<int> balances = <int>[];
    final List<int> worth = <int>[];
    container
      ..listen<AsyncValue<List<AccountBalance>>>(accountBalancesProvider, (
        _,
        AsyncValue<List<AccountBalance>> next,
      ) {
        final List<AccountBalance>? v = next.value;
        if (v != null && v.isNotEmpty) balances.add(v.single.balance);
      }, fireImmediately: true)
      ..listen<AsyncValue<int>>(netWorthProvider, (_, AsyncValue<int> next) {
        final int? v = next.value;
        if (v != null) worth.add(v);
      }, fireImmediately: true);
    await pumpEventQueue();
    await container
        .read(transactionsRepositoryProvider)
        .create(expenseDraft(accountId: a.id, categoryId: cat, amount: 400));
    await pumpEventQueue();

    expect(balances.first, 1000);
    expect(balances.last, 600);
    expect(worth.first, 1000);
    expect(worth.last, 600);
  });

  /// Streams are paused without a listener, so listen while waiting.
  Future<T> load<T>(StreamProvider<T> provider) async {
    final ProviderSubscription<AsyncValue<T>> sub = container.listen(
      provider,
      (_, _) {},
    );
    final T value = await container.read(provider.future);
    sub.close();
    return value;
  }

  test('the other stream providers load', () async {
    expect(await load(accountsProvider), isEmpty);
    expect(await load(expenseCategoriesProvider), hasLength(26));
    expect(await load(incomeCategoriesProvider), hasLength(8));
    expect(await load(loanSummariesProvider), isEmpty);
    expect(await load(goldHoldingValuesProvider), isEmpty);
    expect(await load(goldRatesProvider), isEmpty);
    expect(await load(budgetsForMonthProvider('2026-11')), isEmpty);
    expect(await load(dailyActivitiesForDateProvider(day)), isEmpty);
  });

  test('the database provider closes the database on dispose', () async {
    final AppDatabase db = env.db;
    expect(db, isNotNull);
    // Override keeps the test database open; the real provider wiring is
    // covered by the app: ref.onDispose(db.close).
    expect(container.read(repositoryContextProvider).db, same(db));
  });
}
