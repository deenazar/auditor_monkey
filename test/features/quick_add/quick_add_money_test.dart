// Money correctness of Quick Add (plan 5.3): every save goes through the
// notifier and the real repositories; every number below is computed by hand
// in integer paise. A transfer must change BOTH balances and NO spending,
// income, category or monthly total.
import 'dart:io';

import 'package:auditor_monkey/core/database/app_database.dart';
import 'package:auditor_monkey/core/database/database_provider.dart';
import 'package:auditor_monkey/core/logging/app_logger.dart';
import 'package:auditor_monkey/core/logging/logger_provider.dart';
import 'package:auditor_monkey/core/money/money.dart';
import 'package:auditor_monkey/core/utils/clock.dart';
import 'package:auditor_monkey/features/accounts/application/accounts_providers.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/categories/domain/category.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_data_provider.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_notifier.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_state.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_undo.dart';
import 'package:auditor_monkey/features/transactions/application/transactions_providers.dart';
import 'package:auditor_monkey/features/transactions/domain/statement_line.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/provider_env.dart';
import '../../support/quick_add_env.dart';
import '../../support/test_env.dart';

const String from = '2026-11-01';
const String to = '2026-11-30';
const String month = '2026-11';

/// Everything the owner can see that a save may change.
class Snap {
  const Snap({
    required this.balances,
    required this.netWorth,
    required this.expense,
    required this.income,
    required this.byCategory,
    required this.monthly,
  });

  final Map<String, int> balances; // by account name
  final int netWorth;
  final int expense;
  final int income;
  final Map<String, int> byCategory; // by category id
  final Map<String, (int, int)> monthly; // name -> (income, expense)

  @override
  bool operator ==(Object other) =>
      other is Snap &&
      _eq(balances, other.balances) &&
      netWorth == other.netWorth &&
      expense == other.expense &&
      income == other.income &&
      _eq(byCategory, other.byCategory) &&
      _eq(monthly, other.monthly);

  static bool _eq<T>(Map<String, T> a, Map<String, T> b) =>
      a.length == b.length &&
      a.entries.every((MapEntry<String, T> e) => b[e.key] == e.value);

  @override
  int get hashCode => Object.hash(netWorth, expense, income);

  @override
  String toString() =>
      'Snap($balances net=$netWorth exp=$expense inc=$income '
      '$byCategory $monthly)';
}

Future<Snap> snapshot(ProviderContainer c) async {
  c.listen(accountBalancesProvider, (_, _) {});
  c.listen(netWorthProvider, (_, _) {});
  final List<AccountBalance> balances = await c.read(
    accountBalancesProvider.future,
  );
  final int net = await c.read(netWorthProvider.future);
  final repo = c.read(transactionsRepositoryProvider);
  final List<CategoryTotal> cats = await repo.expenseByCategory(
    from: from,
    to: to,
  );
  final Map<String, (int, int)> monthly = <String, (int, int)>{};
  for (final AccountBalance b in balances) {
    final List<MonthlyTotal> m = await repo.monthlyTotalsForAccount(
      b.account.id,
      fromMonth: month,
      toMonth: month,
    );
    monthly[b.account.name] = (m.single.income, m.single.expense);
  }
  return Snap(
    balances: <String, int>{
      for (final AccountBalance b in balances) b.account.name: b.balance,
    },
    netWorth: net,
    expense: await repo.expenseTotal(from: from, to: to),
    income: await repo.incomeTotal(from: from, to: to),
    byCategory: <String, int>{
      for (final CategoryTotal t in cats) t.categoryId: t.total,
    },
    monthly: monthly,
  );
}

void main() {
  late TestEnv env;
  late String groceries;
  late String salary;

  setUp(() async {
    env = quickAddTestEnv();
    await threeAccounts(env);
    groceries = await env.seededCategoryId('Groceries', 'expense');
    salary = await env.seededCategoryId('Salary', 'income');
  });
  tearDown(() => env.close());

  /// A fresh container (as a fresh open of the sheet) with data loaded.
  Future<QuickAddHarness> open() async {
    final QuickAddHarness h = QuickAddHarness(env);
    addTearDown(h.dispose);
    await h.loaded();
    return h;
  }

  Future<String> idOf(String name) async => (await env.accounts.getBalances())
      .firstWhere((AccountBalance b) => b.account.name == name)
      .account
      .id;

  /// One full Quick Add entry. Returns the saved entry's id.
  Future<String> add({
    required TransactionType type,
    required String keys,
    String? account,
    String? toAccount,
    String? category,
  }) async {
    final QuickAddHarness h = await open();
    h.notifier.setType(type);
    if (type == TransactionType.transfer) {
      h.notifier.pickFrom(await idOf(account!));
      h.notifier.pickTo(await idOf(toAccount!));
    } else {
      h.notifier.pickAccount(await idOf(account!));
      h.notifier.pickCategory(category!);
    }
    h.type(keys);
    await h.notifier.save();
    expect(h.state.status, SaveStatus.done);
    env.clock.advance();
    return h.state.saved!.id;
  }

  Future<Snap> snap() async {
    final ProviderContainer c = containerFor(env);
    addTearDown(c.dispose);
    return snapshot(c);
  }

  test('start: Hand 1,000.00, SBI 5,000.00, Axis 0.00', () async {
    final Snap s = await snap();
    expect(s.balances, <String, int>{'Hand': 100000, 'SBI': 500000, 'Axis': 0});
    expect(s.netWorth, 600000);
  });

  test('expense 250 on Hand', () async {
    final Snap before = await snap();
    await add(
      type: TransactionType.expense,
      keys: '250',
      account: 'Hand',
      category: groceries,
    );
    final Snap s = await snap();
    expect(s.balances['Hand'], 100000 - 25000);
    expect(s.balances['SBI'], before.balances['SBI']);
    expect(s.netWorth, before.netWorth - 25000);
    expect(s.expense, 25000);
    expect(s.income, 0);
    expect(s.byCategory, <String, int>{groceries: 25000});
    expect(s.monthly['Hand'], (0, 25000));
    expect(s.monthly['SBI'], (0, 0));
  });

  test('income 1,200.50 on SBI', () async {
    await add(
      type: TransactionType.income,
      keys: '1200.50',
      account: 'SBI',
      category: salary,
    );
    final Snap s = await snap();
    expect(s.balances['SBI'], 500000 + 120050);
    expect(s.netWorth, 600000 + 120050);
    expect(s.income, 120050);
    expect(s.expense, 0);
    expect(s.byCategory, isEmpty);
    expect(s.monthly['SBI'], (120050, 0));
  });

  test('transfer 2,000 SBI to Axis: both balances, nothing else', () async {
    // Real history first, so "unchanged" means something.
    await add(
      type: TransactionType.expense,
      keys: '250',
      account: 'Hand',
      category: groceries,
    );
    await add(
      type: TransactionType.income,
      keys: '1200.50',
      account: 'SBI',
      category: salary,
    );
    final Snap before = await snap();
    await add(
      type: TransactionType.transfer,
      keys: '2000',
      account: 'SBI',
      toAccount: 'Axis',
    );
    final Snap after = await snap();
    expect(after.balances['SBI'], before.balances['SBI']! - 200000);
    expect(after.balances['Axis'], before.balances['Axis']! + 200000);
    expect(after.balances['Axis'], 200000);
    expect(after.balances['Hand'], before.balances['Hand']);
    expect(after.netWorth, before.netWorth);
    expect(after.expense, before.expense);
    expect(after.income, before.income);
    expect(after.byCategory, before.byCategory);
    expect(after.monthly, before.monthly);
    expect(after.monthly['SBI'], (120050, 0));
    expect(after.monthly['Axis'], (0, 0));
  });

  test('10 expenses of 0.01 leave exactly -10 paise (no drift)', () async {
    for (int i = 0; i < 10; i++) {
      await add(
        type: TransactionType.expense,
        keys: '0.01',
        account: 'Axis',
        category: groceries,
      );
    }
    final Snap s = await snap();
    expect(s.balances['Axis'], -10);
    expect(s.expense, 10);
    expect(s.netWorth, 600000 - 10);
    expect(s.monthly['Axis'], (0, 10));
  });

  test('the maximum amount saves and shows exactly', () async {
    await add(
      type: TransactionType.income,
      keys: '1000000000000',
      account: 'Axis',
      category: salary,
    );
    final Snap s = await snap();
    expect(s.balances['Axis'], maxPaise);
    expect(s.income, maxPaise);
    expect(s.netWorth, 600000 + maxPaise);
    expect(formatPaise(s.balances['Axis']!), '₹10,00,00,00,00,000.00');
  });

  test('undo of each type brings every number back', () async {
    final Snap start = await snap();
    final QuickAddUndo undo = QuickAddUndo(env.transactions, env.ctx.logger);
    for (final (TransactionType type, String keys, String account) spec
        in <(TransactionType, String, String)>[
          (TransactionType.expense, '250', 'Hand'),
          (TransactionType.income, '1200.50', 'SBI'),
          (TransactionType.transfer, '2000', 'SBI'),
        ]) {
      final String id = await add(
        type: spec.$1,
        keys: spec.$2,
        account: spec.$3,
        toAccount: 'Axis',
        category: spec.$1 == TransactionType.expense ? groceries : salary,
      );
      expect(await snap(), isNot(start), reason: spec.$1.name);
      expect(await undo(id), isTrue);
      expect(await snap(), start, reason: 'after undo of ${spec.$1.name}');
    }
  });

  test('numbers survive close and reopen of a database file', () async {
    final Directory dir = Directory.systemTemp.createTempSync('am_qa_money_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final File file = File('${dir.path}/test.sqlite');
    final FakeClock clock = FakeClock(
      DateTime(2026, 11, 12, 10).millisecondsSinceEpoch,
    );
    ProviderContainer open() => ProviderContainer(
      overrides: <Override>[
        appDatabaseProvider.overrideWith((Ref ref) {
          final AppDatabase db = AppDatabase(
            NativeDatabase(file),
            logger: AppLogger(sinks: const [], isRelease: false),
            clock: clock,
          );
          ref.onDispose(db.close);
          return db;
        }),
        clockProvider.overrideWithValue(clock),
        loggerProvider.overrideWithValue(
          AppLogger(sinks: const [], isRelease: false),
        ),
      ],
    );

    ProviderContainer c = open();
    final accounts = c.read(accountsRepositoryProvider);
    final Map<String, String> ids = <String, String>{};
    for (final (String, int) a in <(String, int)>[
      ('Hand', 100000),
      ('SBI', 500000),
      ('Axis', 0),
    ]) {
      ids[a.$1] = (await accounts.create(
        AccountDraft(
          name: a.$1,
          type: AccountType.bank,
          colour: 'accountSbi',
          openingBalance: a.$2,
          sortOrder: ids.length,
        ),
      )).id;
    }
    final String cat =
        (await c
                .read(appDatabaseProvider)
                .customSelect(
                  "SELECT id FROM categories WHERE name = 'Groceries'",
                )
                .getSingle())
            .read<String>('id');

    Future<void> save(
      TransactionType type,
      String keys, {
      String account = 'Hand',
      String? toAccount,
    }) async {
      c.listen(quickAddProvider, (_, _) {});
      c.listen(quickAddDataProvider, (_, _) {});
      await c.read(quickAddDataProvider.future);
      final QuickAddNotifier n = c.read(quickAddProvider.notifier);
      n.setType(type);
      if (type == TransactionType.transfer) {
        n
          ..pickFrom(ids[account]!)
          ..pickTo(ids[toAccount]!);
      } else {
        n
          ..pickAccount(ids[account]!)
          ..pickCategory(cat);
      }
      for (final String k in keys.split('')) {
        k == '.' ? n.pressDot() : n.pressDigit(k);
      }
      await n.save();
      expect(c.read(quickAddProvider).status, SaveStatus.done);
      clock.now += 1000;
      // Next "open": drop the sheet's state.
      c.invalidate(quickAddProvider);
      c.invalidate(quickAddDataProvider);
    }

    await save(TransactionType.expense, '250', account: 'Hand');
    await save(
      TransactionType.transfer,
      '2000',
      account: 'SBI',
      toAccount: 'Axis',
    );
    final Snap before = await snapshot(c);
    expect(before.balances, <String, int>{
      'Hand': 75000,
      'SBI': 300000,
      'Axis': 200000,
    });
    c.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    c = open();
    addTearDown(c.dispose);
    final Snap after = await snapshot(c);
    expect(after, before);
    expect(after.netWorth, 575000);
  });
}
