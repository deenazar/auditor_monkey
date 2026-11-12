import 'package:auditor_monkey/core/database/seed/default_categories.dart';
import 'package:auditor_monkey/core/sync/sync_status.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/categories/domain/category.dart';
import 'package:auditor_monkey/features/quick_add/domain/category_order.dart';
import 'package:auditor_monkey/features/quick_add/domain/quick_add_defaults.dart';
import 'package:auditor_monkey/features/quick_add/domain/quick_add_hints.dart';
import 'package:auditor_monkey/features/quick_add/domain/quick_add_validator.dart';
import 'package:auditor_monkey/features/quick_add/domain/recent_entries.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:flutter_test/flutter_test.dart';

Account acc(String id, {int order = 0, bool archived = false}) => Account(
  id: id,
  createdAt: 0,
  updatedAt: 0,
  deletedAt: null,
  syncStatus: SyncStatus.synced,
  name: id,
  type: AccountType.bank,
  colour: 'primary',
  openingBalance: 0,
  sortOrder: order,
  archived: archived,
);

Category cat(
  String id, {
  int order = 0,
  CategoryKind kind = CategoryKind.expense,
  bool archived = false,
  int? deletedAt,
}) => Category(
  id: id,
  createdAt: 0,
  updatedAt: 0,
  deletedAt: deletedAt,
  syncStatus: SyncStatus.synced,
  name: id,
  kind: kind,
  colourGroup: CategoryColourGroup.other,
  icon: 'x',
  sortOrder: order,
  archived: archived,
);

TransactionEntry entry(
  String id, {
  TransactionType type = TransactionType.expense,
  int amount = 100,
  String account = 'a1',
  String? to,
  String? category = 'c1',
  String? note,
}) => TransactionEntry(
  id: id,
  createdAt: 0,
  updatedAt: 0,
  deletedAt: null,
  syncStatus: SyncStatus.synced,
  type: type,
  amount: amount,
  date: '2026-01-01',
  accountId: account,
  toAccountId: to,
  categoryId: category,
  note: note,
  loanId: null,
  importSource: null,
);

void main() {
  group('category order', () {
    final List<Category> offered = <Category>[
      for (int i = 0; i < 10; i++) cat('c$i', order: i),
    ];
    test('last used first, then uses, last use, sort order; max 6', () {
      final OrderedCategories o = orderCategories(
        offered: offered,
        lastUsedId: 'c7',
        usage: const <CategoryUsage>[
          CategoryUsage(categoryId: 'c1', uses: 5, lastUsed: 10),
          CategoryUsage(categoryId: 'c2', uses: 5, lastUsed: 20),
          CategoryUsage(categoryId: 'c3', uses: 5, lastUsed: 20),
          CategoryUsage(categoryId: 'c7', uses: 1, lastUsed: 99),
          CategoryUsage(categoryId: 'c4', uses: 9, lastUsed: 1),
          CategoryUsage(categoryId: 'c5', uses: 2, lastUsed: 1),
          CategoryUsage(categoryId: 'c6', uses: 2, lastUsed: 1),
          CategoryUsage(categoryId: 'c8', uses: 1, lastUsed: 1),
        ],
      );
      expect(o.suggested.map((Category c) => c.id), <String>[
        'c7', 'c4', 'c2', 'c3', 'c1', 'c5', // c6, c8 cut
      ]);
      expect(o.rest.map((Category c) => c.id), <String>[
        'c0',
        'c6',
        'c8',
        'c9',
      ]);
      expect(o.all, hasLength(10));
    });

    test(
      'unoffered usage and last used are left out; no usage = sort order',
      () {
        final OrderedCategories o = orderCategories(
          offered: <Category>[cat('b', order: 2), cat('a', order: 1)],
          lastUsedId: 'gone',
          usage: const <CategoryUsage>[
            CategoryUsage(categoryId: 'gone', uses: 9, lastUsed: 9),
          ],
        );
        expect(o.suggested, isEmpty);
        expect(o.rest.map((Category c) => c.id), <String>['a', 'b']);
        expect(OrderedCategories.empty.isEmpty, isTrue);
      },
    );

    test('sort order ties break by id', () {
      final OrderedCategories o = orderCategories(
        offered: <Category>[cat('z'), cat('m')],
        usage: const <CategoryUsage>[],
      );
      expect(o.rest.map((Category c) => c.id), <String>['m', 'z']);
    });
  });

  group('offered lists', () {
    test('archived, deleted, other kind and loan categories are left out', () {
      final String loan = loanCategoryIds.first;
      final List<Category> live = <Category>[
        cat('keep', order: 2),
        cat('first', order: 1),
        cat('arch', archived: true),
        cat('del', deletedAt: 5),
        cat('inc', kind: CategoryKind.income),
        cat(loan),
      ];
      expect(
        offeredCategories(live, CategoryKind.expense).map((Category c) => c.id),
        <String>['first', 'keep'],
      );
      expect(
        offeredAccounts(<Account>[acc('a'), acc('b', archived: true)])
            .map((Account a) => a.id),
        <String>['a'],
      );
    });

    test('the loan ids are exactly the 4 seeded loan categories', () {
      final Set<String> byName = <String>{
        for (final DefaultCategory c in defaultCategories)
          if (c.name.startsWith('Loan ')) c.id,
      };
      expect(loanCategoryIds, byName);
      expect(loanCategoryIds, hasLength(4));
    });
  });

  group('defaults', () {
    final List<Account> accounts = <Account>[acc('a1'), acc('a2'), acc('a3')];
    final OrderedCategories exp = OrderedCategories(
      suggested: <Category>[cat('c2')],
      rest: <Category>[cat('c1'), cat('c3')],
    );
    final OrderedCategories inc = OrderedCategories(
      suggested: const <Category>[],
      rest: <Category>[cat('i1', kind: CategoryKind.income)],
    );

    QuickAddDefaults resolve(QuickAddHints h, [List<Account>? a]) =>
        resolveDefaults(
          hints: h,
          accounts: a ?? accounts,
          expenseCategories: exp,
          incomeCategories: inc,
        );

    test('no history: first account, first category', () {
      final QuickAddDefaults d = resolve(QuickAddHints.empty);
      expect(d.expense.accountId, 'a1');
      expect(d.expense.categoryId, 'c2');
      expect(d.income.categoryId, 'i1');
      expect(d.transfer.accountId, 'a1');
      expect(d.transfer.toAccountId, 'a2');
      expect(d.transferAvailable, isTrue);
    });

    test('history is used when still offered', () {
      final QuickAddDefaults d = resolve(
        const QuickAddHints(
          lastUsed: <TransactionType, LastUsedPick>{
            TransactionType.expense: LastUsedPick(
              accountId: 'a3',
              categoryId: 'c3',
            ),
            TransactionType.transfer: LastUsedPick(
              accountId: 'a2',
              toAccountId: 'a3',
            ),
          },
        ),
      );
      expect(d.expense.accountId, 'a3');
      expect(d.expense.categoryId, 'c3');
      expect(d.transfer.accountId, 'a2');
      expect(d.transfer.toAccountId, 'a3');
    });

    test('archived or deleted last-used falls back', () {
      final QuickAddDefaults d = resolve(
        const QuickAddHints(
          lastUsed: <TransactionType, LastUsedPick>{
            TransactionType.expense: LastUsedPick(
              accountId: 'gone',
              categoryId: 'gone',
            ),
            TransactionType.transfer: LastUsedPick(
              accountId: 'gone',
              toAccountId: 'a1',
            ),
          },
        ),
      );
      expect(d.expense.accountId, 'a1');
      expect(d.expense.categoryId, 'c2');
      expect(d.transfer.accountId, 'a1');
      expect(d.transfer.toAccountId, 'a2'); // a1 == From, so next account
    });

    test('To equal to From moves to the next account', () {
      final QuickAddDefaults d = resolve(
        const QuickAddHints(
          lastUsed: <TransactionType, LastUsedPick>{
            TransactionType.transfer: LastUsedPick(
              accountId: 'a1',
              toAccountId: 'a1',
            ),
          },
        ),
      );
      expect(d.transfer.toAccountId, 'a2');
    });

    test('one account: transfer unavailable; none: nothing', () {
      final QuickAddDefaults one = resolve(QuickAddHints.empty, <Account>[
        acc('a1'),
      ]);
      expect(one.transferAvailable, isFalse);
      expect(one.transfer.accountId, isNull);
      expect(one.expense.accountId, 'a1');
      final QuickAddDefaults none = resolve(QuickAddHints.empty, <Account>[]);
      expect(none.expense.accountId, isNull);
    });

    test('no categories: no category default', () {
      final QuickAddDefaults d = resolveDefaults(
        hints: QuickAddHints.empty,
        accounts: accounts,
        expenseCategories: OrderedCategories.empty,
        incomeCategories: OrderedCategories.empty,
      );
      expect(d.expense.categoryId, isNull);
    });
  });

  group('recent entries', () {
    const Set<String> accounts = <String>{'a1', 'a2'};
    const Set<String> cats = <String>{'c1', 'c2'};

    test('identical entries collapse to the newest; max 6', () {
      final List<TransactionEntry> out = pickRecentEntries(
        <TransactionEntry>[
          entry('new'),
          entry('old'),
          entry('n1', note: 'x'),
          entry('n2', amount: 200),
          entry('n3', category: 'c2'),
          entry('n4', account: 'a2'),
          entry('n5', type: TransactionType.transfer, to: 'a2', category: null),
          entry('n6', amount: 300),
          entry('n7', amount: 400),
        ],
        offeredAccountIds: accounts,
        offeredCategoryIds: cats,
      );
      expect(out.map((TransactionEntry e) => e.id), <String>[
        'new',
        'n1',
        'n2',
        'n3',
        'n4',
        'n5',
      ]);
    });

    test('entries with unoffered account, To or category are skipped', () {
      final List<TransactionEntry> out = pickRecentEntries(
        <TransactionEntry>[
          entry('bad-acc', account: 'zz'),
          entry('bad-cat', category: 'zz'),
          entry(
            'bad-to',
            type: TransactionType.transfer,
            to: 'zz',
            category: null,
          ),
          entry('ok', amount: 5),
        ],
        offeredAccountIds: accounts,
        offeredCategoryIds: cats,
      );
      expect(out.map((TransactionEntry e) => e.id), <String>['ok']);
    });

    test('blank and missing notes count as the same', () {
      final List<TransactionEntry> out = pickRecentEntries(
        <TransactionEntry>[entry('a', note: ' '), entry('b')],
        offeredAccountIds: accounts,
        offeredCategoryIds: cats,
      );
      expect(out, hasLength(1));
    });
  });

  group('validator', () {
    QuickAddForm form({
      TransactionType type = TransactionType.expense,
      int? amount = 100,
      String date = '2026-11-12',
      String note = '',
      String? account = 'a1',
      String? to,
      String? category = 'c1',
    }) => QuickAddForm(
      type: type,
      amountPaise: amount,
      date: date,
      today: '2026-11-12',
      note: note,
      accountId: account,
      toAccountId: to,
      categoryId: category,
      offeredAccountIds: const <String>{'a1', 'a2'},
      offeredCategoryIds: type == TransactionType.transfer
          ? const <String>{}
          : const <String>{'c1'},
    );

    test('a good expense passes and builds a clean draft', () {
      expect(validateQuickAdd(form(note: '  tea  ')), isNull);
      final TransactionDraft d = buildQuickAddDraft(form(note: '  tea  '));
      expect(d.note, 'tea');
      expect(d.toAccountId, isNull);
      expect(d.categoryId, 'c1');
      expect(d.amount, 100);
    });

    test('amount', () {
      expect(validateQuickAdd(form(amount: null))!.field, QuickAddField.amount);
    });

    test('category must be offered', () {
      expect(
        validateQuickAdd(form(category: null))!.message,
        'Pick a category.',
      );
      expect(
        validateQuickAdd(form(category: 'other'))!.field,
        QuickAddField.category,
      );
    });

    test('account must be offered', () {
      expect(
        validateQuickAdd(form(account: 'zz'))!.message,
        'Pick an account.',
      );
    });

    test('transfer needs two different offered accounts, no category', () {
      TransactionType t = TransactionType.transfer;
      expect(
        validateQuickAdd(form(type: t, to: 'a1', category: null))!.message,
        'Pick two different accounts.',
      );
      expect(
        validateQuickAdd(form(type: t, to: null, category: null))!.field,
        QuickAddField.toAccount,
      );
      expect(validateQuickAdd(form(type: t, to: 'a2', category: null)), isNull);
      final TransactionDraft d = buildQuickAddDraft(
        form(type: t, to: 'a2', category: 'c1'),
      );
      expect(d.categoryId, isNull);
      expect(d.toAccountId, 'a2');
    });

    test('date: today + 31 ok, + 32 refused, 1900 ok, 1899 refused', () {
      expect(validateQuickAdd(form(date: '2026-12-13')), isNull);
      expect(
        validateQuickAdd(form(date: '2026-12-14'))!.message,
        'Pick a date up to 31 days ahead.',
      );
      expect(validateQuickAdd(form(date: '1900-01-01')), isNull);
      expect(
        validateQuickAdd(form(date: '1899-12-31'))!.field,
        QuickAddField.date,
      );
      expect(
        validateQuickAdd(form(date: '2062-01-01'))!.field,
        QuickAddField.date,
      );
      expect(
        validateQuickAdd(form(date: '2026-02-30'))!.field,
        QuickAddField.date,
      );
      expect(validateQuickAdd(form(date: 'abc'))!.field, QuickAddField.date);
    });

    test(
      'note: 200 ok, 201 refused, control characters and newline refused',
      () {
        expect(validateQuickAdd(form(note: 'a' * 200)), isNull);
        expect(
          validateQuickAdd(form(note: 'a' * 201))!.message,
          'Use 200 characters or fewer.',
        );
        expect(
          validateQuickAdd(form(note: 'a\u0007b'))!.field,
          QuickAddField.note,
        );
        expect(validateQuickAdd(form(note: 'a\nb'))!.field, QuickAddField.note);
        expect(validateQuickAdd(form(note: ' ${'a' * 200} ')), isNull);
        expect(noteIssue(null), isNull);
      },
    );
  });
}
