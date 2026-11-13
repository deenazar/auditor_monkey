import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/categories/domain/category.dart';
import 'package:auditor_monkey/features/mascot/application/mascot_events.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_data_provider.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_saved.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_state.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fixtures.dart';
import '../../../support/quick_add_env.dart';
import '../../../support/test_env.dart';

void main() {
  late TestEnv env;
  late List<Account> acc; // Hand, SBI, Axis
  late String groceries;
  late String fuel;
  late String salary;
  QuickAddHarness? h;

  setUp(() async {
    env = quickAddTestEnv();
    acc = await threeAccounts(env);
    groceries = await env.seededCategoryId('Groceries', 'expense');
    fuel = await env.seededCategoryId('Fuel', 'expense');
    salary = await env.seededCategoryId('Salary', 'income');
  });
  tearDown(() async {
    h?.dispose();
    h = null;
    await env.close();
  });

  Future<TransactionEntry> make(TransactionDraft d) async {
    env.clock.advance();
    return env.transactions.create(d);
  }

  Future<QuickAddHarness> open(TransactionEntry e) async {
    final QuickAddHarness harness = QuickAddHarness(env, edit: e);
    h = harness;
    await harness.loaded();
    return harness;
  }

  test('starts from the entry and reads as an edit', () async {
    final TransactionEntry e = await make(
      TransactionDraft(
        type: TransactionType.expense,
        amount: 12550,
        date: '2026-10-03',
        accountId: acc[1].id,
        categoryId: fuel,
        note: 'Petrol',
      ),
    );
    final QuickAddHarness q = await open(e);
    expect(q.state.isEditing, isTrue);
    expect(q.state.type, TransactionType.expense);
    expect(q.state.amount.paise, 12550);
    expect(q.state.date, '2026-10-03');
    expect(q.state.note, 'Petrol');
    expect(q.view.current.accountId, acc[1].id);
    expect(q.view.current.categoryId, fuel);
    expect(q.view.saveLabel, 'Save changes');
    expect(q.view.headerTitle, 'Edit entry');
    expect(q.view.canSave, isTrue);
  });

  test('add mode is unchanged', () async {
    final QuickAddHarness q = QuickAddHarness(env);
    h = q;
    await q.loaded();
    expect(q.state.isEditing, isFalse);
    expect(q.view.saveLabel, 'Save expense');
    expect(q.view.headerTitle, isNull);
  });

  test('save updates the same row, no new one, toast says edited', () async {
    final TransactionEntry e = await make(
      expenseDraft(accountId: acc[0].id, categoryId: groceries, amount: 1000),
    );
    final QuickAddHarness q = await open(e);
    q.notifier.clear();
    q.type('75');
    q.notifier.pickAccount(acc[2].id);
    q.notifier.setNote('  changed ');
    env.clock.advance();
    await q.notifier.save();
    expect(q.state.status, SaveStatus.done);
    expect(await env.count('transactions'), 1);
    final TransactionEntry back = (await env.transactions.getById(e.id))!;
    expect(back.amount, 7500);
    expect(back.accountId, acc[2].id);
    expect(back.note, 'changed');
    expect(back.date, e.date);
    final SavedEntry? announced = q.container.read(quickAddSavedProvider);
    expect(announced!.edited, isTrue);
    expect(announced.id, e.id);
  });

  test('keeps loanId and importSource', () async {
    final loan = await env.loans.create(loanDraft());
    final TransactionEntry e = await make(
      TransactionDraft(
        type: TransactionType.expense,
        amount: 1000,
        date: day,
        accountId: acc[0].id,
        categoryId: groceries,
        loanId: loan.id,
        importSource: 'sheet row 9',
      ),
    );
    final QuickAddHarness q = await open(e);
    q.notifier.clear();
    q.type('5');
    await q.notifier.save();
    expect(q.state.status, SaveStatus.done);
    final TransactionEntry back = (await env.transactions.getById(e.id))!;
    expect(back.loanId, loan.id);
    expect(back.importSource, 'sheet row 9');
    expect(back.amount, 500);
  });

  test('a loan-linked entry cannot switch type', () async {
    final loan = await env.loans.create(loanDraft());
    final TransactionEntry e = await make(
      TransactionDraft(
        type: TransactionType.expense,
        amount: 1000,
        date: day,
        accountId: acc[0].id,
        categoryId: groceries,
        loanId: loan.id,
      ),
    );
    final QuickAddHarness q = await open(e);
    expect(q.notifier.setType(TransactionType.income), isFalse);
    expect(q.notifier.setType(TransactionType.transfer), isFalse);
    expect(q.state.type, TransactionType.expense);
    expect(q.notifier.setType(TransactionType.expense), isTrue);
  });

  test('a plain entry can switch type', () async {
    final TransactionEntry e = await make(
      expenseDraft(accountId: acc[0].id, categoryId: groceries, amount: 1000),
    );
    final QuickAddHarness q = await open(e);
    expect(q.notifier.setType(TransactionType.income), isTrue);
    q.notifier.pickCategory(salary);
    await q.notifier.save();
    expect(q.state.status, SaveStatus.done);
    final TransactionEntry back = (await env.transactions.getById(e.id))!;
    expect(back.type, TransactionType.income);
    expect(back.categoryId, salary);
  });

  test('an archived account and category stay editable', () async {
    final TransactionEntry e = await make(
      expenseDraft(accountId: acc[2].id, categoryId: groceries, amount: 1000),
    );
    await env.accounts.update(
      acc[2].id,
      const AccountDraft(
        name: 'Axis',
        type: AccountType.bank,
        colour: 'accountSbi',
        archived: true,
      ),
    );
    final Category cat = (await env.categories.getById(groceries))!;
    await env.categories.update(
      groceries,
      CategoryDraft(
        name: cat.name,
        kind: cat.kind,
        colourGroup: cat.colourGroup,
        icon: cat.icon,
        sortOrder: cat.sortOrder,
        archived: true,
      ),
    );
    final QuickAddHarness q = await open(e);
    final QuickAddData data = (await q.loaded());
    expect(data.accountIds, contains(acc[2].id));
    expect(data.categoryIdsOf(TransactionType.expense), contains(groceries));
    q.type('1');
    await q.notifier.save();
    expect(q.state.status, SaveStatus.done, reason: q.state.saveError);
    // Add mode still hides them.
    final QuickAddHarness add = QuickAddHarness(env);
    addTearDown(add.dispose);
    final QuickAddData addData = await add.loaded();
    expect(addData.accountIds, isNot(contains(acc[2].id)));
    expect(
      addData.categoryIdsOf(TransactionType.expense),
      isNot(contains(groceries)),
    );
  });

  test('past dates are allowed; far future only when unchanged', () async {
    final TransactionEntry old = await make(
      expenseDraft(
        accountId: acc[0].id,
        categoryId: groceries,
        date: '2019-01-05',
      ),
    );
    QuickAddHarness q = await open(old);
    q.notifier.setDate('2018-12-31');
    await q.notifier.save();
    expect(q.state.status, SaveStatus.done);
    q.dispose();

    final TransactionEntry far = await make(
      expenseDraft(
        accountId: acc[0].id,
        categoryId: groceries,
        date: '2027-06-01', // more than 31 days after the test day
      ),
    );
    q = await open(far);
    q.type('1');
    await q.notifier.save(); // date unchanged: fine
    expect(q.state.status, SaveStatus.done);
    q.dispose();

    q = await open(far);
    q.notifier.setDate('2027-07-01'); // still too far, and changed
    await q.notifier.save();
    expect(q.state.status, SaveStatus.idle);
    expect(q.state.saveError, isNotNull);
    h = q;
  });

  test('edits get no monkey reaction, adds do', () async {
    final TransactionEntry e = await make(
      expenseDraft(accountId: acc[0].id, categoryId: groceries),
    );
    final QuickAddHarness q = await open(e);
    final mascot = q.container.read(mascotEventsProvider.notifier);
    mascot.saved(
      const SavedEntry(
        id: 'x',
        type: TransactionType.expense,
        amount: 1,
        edited: true,
      ),
    );
    expect(q.container.read(mascotEventsProvider), isNull);
    mascot.saved(
      const SavedEntry(id: 'x', type: TransactionType.expense, amount: 1),
    );
    expect(q.container.read(mascotEventsProvider), isNotNull);
  });

  test(
    'a deleted entry cannot be saved: failed with a plain message',
    () async {
      final TransactionEntry e = await make(
        expenseDraft(accountId: acc[0].id, categoryId: groceries),
      );
      final QuickAddHarness q = await open(e);
      await env.transactions.softDelete(e.id);
      await q.notifier.save();
      expect(q.state.status, SaveStatus.failed);
      expect(q.state.saveError, isNotNull);
    },
  );
}
