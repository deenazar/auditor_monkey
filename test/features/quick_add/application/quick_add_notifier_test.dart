import 'package:auditor_monkey/core/database/seed/default_categories.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_data_provider.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_state.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_undo.dart';
import 'package:auditor_monkey/features/quick_add/domain/amount_input.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fixtures.dart';
import '../../../support/quick_add_env.dart';
import '../../../support/test_env.dart';

void main() {
  late TestEnv env;
  late QuickAddHarness h;
  late List<Account> acc; // Hand, SBI, Axis
  late String groceries;
  late String fuel;
  late String salary;

  setUp(() async {
    env = quickAddTestEnv();
    acc = await threeAccounts(env);
    groceries = await env.seededCategoryId('Groceries', 'expense');
    fuel = await env.seededCategoryId('Fuel', 'expense');
    salary = await env.seededCategoryId('Salary', 'income');
    h = QuickAddHarness(env);
  });
  tearDown(() async {
    h.dispose();
    await env.close();
  });

  test('opens on expense, today, empty; pad works before data loads', () {
    expect(h.state.type, TransactionType.expense);
    expect(h.state.date, day);
    expect(h.view.data, isNull);
    expect(h.view.canSave, isFalse);
    h.type('250');
    expect(h.state.amount.paise, 25000);
    expect(h.view.canSave, isFalse); // still loading
  });

  test('save before the data is loaded does nothing', () async {
    h.type('250');
    await h.notifier.save();
    expect(h.state.status, SaveStatus.idle);
    expect(await env.count('transactions'), 0);
  });

  test('key flow: amount then save writes the right draft', () async {
    await h.loaded();
    h.type('250');
    expect(h.view.canSave, isTrue);
    await h.notifier.save();
    expect(h.state.status, SaveStatus.done);
    final TransactionEntry t = (await env.transactions.getById(
      h.state.saved!.id,
    ))!;
    expect(t.amount, 25000);
    expect(t.type, TransactionType.expense);
    expect(t.accountId, acc.first.id); // first account by sort order
    expect(t.date, day);
    expect(h.state.saved!.amount, 25000);
  });

  test('loan categories are hidden but others are offered', () async {
    final QuickAddData d = await h.loaded();
    final Set<String> ids = d.categoryIdsOf(TransactionType.expense)
      ..addAll(d.categoryIdsOf(TransactionType.income));
    expect(ids.intersection(loanCategoryIds), isEmpty);
    expect(ids, contains(groceries));
    expect(ids, contains(salary));
  });

  test('defaults arriving late never replace a pick', () async {
    h.notifier.pickCategory(fuel);
    h.notifier.pickAccount(acc[2].id);
    await h.loaded();
    expect(h.view.current.categoryId, fuel);
    expect(h.view.current.accountId, acc[2].id);
    h.type('5');
    await h.notifier.save();
    final TransactionEntry t = (await env.transactions.getById(
      h.state.saved!.id,
    ))!;
    expect(t.categoryId, fuel);
    expect(t.accountId, acc[2].id);
  });

  test('last used account and category become the next default', () async {
    env.clock.advance();
    await env.transactions.create(
      expenseDraft(accountId: acc[1].id, categoryId: fuel),
    );
    await h.loaded();
    expect(h.view.current.accountId, acc[1].id);
    expect(h.view.current.categoryId, fuel);
  });

  test('tab switch keeps amount, date, note and per-type picks', () async {
    await h.loaded();
    h.type('99');
    h.notifier.setDate('2026-11-10');
    h.notifier.setNote('hello');
    h.notifier.pickCategory(fuel);
    h.notifier.setType(TransactionType.income);
    h.notifier.pickCategory(salary);
    h.notifier.pickAccount(acc[1].id);
    h.notifier.setType(TransactionType.expense);
    expect(h.state.amount.paise, 9900);
    expect(h.state.date, '2026-11-10');
    expect(h.state.note, 'hello');
    expect(h.view.current.categoryId, fuel);
    h.notifier.setType(TransactionType.income);
    expect(h.view.current.categoryId, salary);
    expect(h.view.current.accountId, acc[1].id);
  });

  test('transfer: defaults, swap, picking the other side swaps', () async {
    await h.loaded();
    h.notifier.setType(TransactionType.transfer);
    expect(h.view.current.accountId, acc[0].id);
    expect(h.view.current.toAccountId, acc[1].id);
    h.notifier.swapAccounts();
    expect(h.view.current.accountId, acc[1].id);
    expect(h.view.current.toAccountId, acc[0].id);
    h.notifier.pickTo(acc[1].id); // To = From: swap
    expect(h.view.current.accountId, acc[0].id);
    expect(h.view.current.toAccountId, acc[1].id);
    h.notifier.pickFrom(acc[1].id); // From = To: swap
    expect(h.view.current.accountId, acc[1].id);
    expect(h.view.current.toAccountId, acc[0].id);
    h.notifier.pickTo(acc[2].id);
    expect(h.view.current.toAccountId, acc[2].id);
    expect(h.view.current.accountId, acc[1].id);
  });

  test('transfer saves both accounts and no category', () async {
    await h.loaded();
    h.notifier.setType(TransactionType.transfer);
    h.notifier.pickFrom(acc[1].id);
    h.notifier.pickTo(acc[2].id);
    h.type('2000');
    await h.notifier.save();
    final TransactionEntry t = (await env.transactions.getById(
      h.state.saved!.id,
    ))!;
    expect(t.type, TransactionType.transfer);
    expect(t.accountId, acc[1].id);
    expect(t.toAccountId, acc[2].id);
    expect(t.categoryId, isNull);
    expect(h.view.saveLabel, 'Save transfer');
  });

  test('transfer is refused with one account', () async {
    await env.accounts.softDelete(acc[1].id);
    await env.accounts.softDelete(acc[2].id);
    final QuickAddHarness one = QuickAddHarness(env);
    addTearDown(one.dispose);
    await one.loaded();
    expect(one.view.transferAvailable, isFalse);
    expect(one.notifier.setType(TransactionType.transfer), isFalse);
    expect(one.state.type, TransactionType.expense);
  });

  test('refused digits give a hint and leave the amount', () async {
    h.type('1.23');
    h.notifier.pressDigit('4');
    expect(h.state.amountHint, AmountRefusal.tooManyDecimals);
    expect(h.state.amount.text, '1.23');
    expect(h.state.refusalCount, 1);
    h.notifier.pressDigit('4');
    expect(h.state.refusalCount, 2);
    h.notifier.backspace();
    expect(h.state.amountHint, isNull);
    h.notifier.paste('abc');
    expect(h.state.amountHint, AmountRefusal.invalidPaste);
    h.notifier.paste('₹1,000');
    expect(h.state.amount.paise, 100000);
    expect(h.state.amountHint, isNull);
    h.notifier.clear();
    expect(h.state.amount.isEmpty, isTrue);
  });

  test('applyRecent fills the form, keeps the date, does not save', () async {
    env.clock.advance();
    final TransactionEntry past = await env.transactions.create(
      expenseDraft(
        accountId: acc[2].id,
        categoryId: fuel,
        amount: 12050,
        note: 'petrol',
        date: '2026-11-01',
      ),
    );
    await h.loaded();
    expect(h.view.data!.recent.single.id, past.id);
    h.notifier.setType(TransactionType.income);
    h.notifier.setDate('2026-11-05');
    h.notifier.applyRecent(past);
    expect(h.state.type, TransactionType.expense);
    expect(h.state.amount.paise, 12050);
    expect(h.state.note, 'petrol');
    expect(h.state.date, '2026-11-05');
    expect(h.view.current.accountId, acc[2].id);
    expect(h.view.current.categoryId, fuel);
    expect(await env.count('transactions'), 1);
  });

  test('invalid form: message, no database write', () async {
    await h.loaded();
    h.type('5');
    h.notifier.setNote('x' * 201);
    await h.notifier.save();
    expect(h.state.status, SaveStatus.idle);
    expect(h.state.saveError, 'Use 200 characters or fewer.');
    expect(await env.count('transactions'), 0);
    h.notifier.setNote('ok');
    expect(h.state.saveError, isNull);
    h.notifier.setDate('2027-01-01'); // far ahead
    await h.notifier.save();
    expect(h.state.saveError, 'Pick a date up to 31 days ahead.');
  });

  test('failed save keeps every field and Save works again', () async {
    await h.loaded();
    h.type('75.5');
    h.notifier.setNote('keep me');
    h.notifier.pickAccount(acc[2].id);
    await env.accounts.softDelete(acc[2].id); // gone after the data loaded
    await h.notifier.save();
    expect(h.state.status, SaveStatus.failed);
    expect(h.state.saveError, 'That account is not available.');
    expect(h.state.amount.text, '75.5');
    expect(h.state.note, 'keep me');
    expect(h.state.picksOf(TransactionType.expense).accountId, acc[2].id);
    expect(await env.count('transactions'), 0);
    h.notifier.pickAccount(acc[0].id);
    expect(h.state.saveError, isNull);
    await h.notifier.save();
    expect(h.state.status, SaveStatus.done);
    expect(await env.count('transactions'), 1);
  });

  test('two un-awaited save calls make exactly one row', () async {
    await h.loaded();
    h.type('250');
    final Future<void> first = h.notifier.save();
    final Future<void> second = h.notifier.save();
    expect(h.state.status, SaveStatus.saving);
    await Future.wait(<Future<void>>[first, second]);
    expect(await env.count('transactions'), 1);
    await h.notifier.save(); // after done: still nothing new
    expect(await env.count('transactions'), 1);
  });

  test('edits are ignored while saving and after done', () async {
    await h.loaded();
    h.type('250');
    final Future<void> saving = h.notifier.save();
    h.notifier.pressDigit('9');
    h.notifier.setNote('late');
    h.notifier.setType(TransactionType.income);
    await saving;
    expect(h.state.amount.text, '250');
    expect(h.state.note, '');
    expect(h.state.type, TransactionType.expense);
  });

  test('undo soft deletes the saved entry', () async {
    await h.loaded();
    h.type('250');
    await h.notifier.save();
    final String id = h.state.saved!.id;
    expect(await h.container.read(quickAddUndoProvider)(id), isTrue);
    expect(await env.transactions.getById(id), isNull);
    // Undo twice: nothing to remove, reported as false, no throw.
    expect(await h.container.read(quickAddUndoProvider)(id), isFalse);
  });

  test('today comes from the clock when the sheet opens', () async {
    env.clock.now = DateTime(2027, 3, 5, 10).millisecondsSinceEpoch;
    final QuickAddHarness later = QuickAddHarness(env);
    addTearDown(later.dispose);
    expect(later.state.date, '2027-03-05');
  });
}
