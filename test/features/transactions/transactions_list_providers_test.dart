import 'dart:io';

import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/transactions/application/transactions_list_providers.dart';
import 'package:auditor_monkey/features/transactions/application/transactions_list_state.dart';
import 'package:auditor_monkey/features/transactions/data/saved_filters_store.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_filter.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_list_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/provider_env.dart';
import '../../support/test_env.dart';

class _FailingStore implements SavedFiltersStore {
  _FailingStore({this.failRead = false, this.failWrite = false});
  final bool failRead;
  final bool failWrite;
  @override
  Future<String?> read() async => failRead ? throw StateError('boom') : null;
  @override
  Future<void> write(String text) async =>
      failWrite ? throw StateError('boom') : null;
}

void main() {
  fileStoreTests();
  late TestEnv env;
  late Account a;
  late Account b;
  late String groceries;
  late List<TransactionEntry> rows;
  late MemorySavedFiltersStore store;
  late ProviderContainer container;

  setUp(() async {
    env = TestEnv();
    a = await env.account('A', opening: 1000000);
    b = await env.account('B', opening: 1000000);
    groceries = await env.seededCategoryId('Groceries', 'expense');
    rows = <TransactionEntry>[];
    store = MemorySavedFiltersStore();
    container = containerFor(
      env,
      extra: [savedFiltersStoreProvider.overrideWithValue(store)],
    );
  });
  tearDown(() async {
    container.dispose();
    await env.close();
  });

  Future<void> seed(int n) async {
    for (int i = 0; i < n; i++) {
      env.clock.advance();
      rows.add(
        await env.transactions.create(
          expenseDraft(
            accountId: i.isEven ? a.id : b.id,
            categoryId: groceries,
            amount: 100 + i,
            // Several rows per day, oldest i first.
            date: '2026-10-${(1 + i ~/ 4).toString().padLeft(2, '0')}',
          ),
        ),
      );
    }
  }

  Future<TransactionsListState> loaded() async {
    container.listen(transactionsListProvider, (_, _) {});
    return container.read(transactionsListProvider.future);
  }

  Future<void> until(bool Function() ok) async {
    for (int i = 0; i < 200 && !ok(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(ok(), isTrue, reason: 'condition not reached in time');
  }

  TransactionsListState? current() =>
      container.read(transactionsListProvider).value;

  group('filter notifier', () {
    test('setQuery trims, cuts and removes control characters', () {
      final n = container.read(transactionFilterProvider.notifier);
      n.setQuery('  hello\u0000 world  ');
      expect(container.read(transactionFilterProvider).query, 'hello world');
      n.setQuery('x' * 100);
      expect(
        container.read(transactionFilterProvider).query.length,
        maxSearchLength,
      );
    });

    test('setFacets keeps the search, clear resets, saved keeps search', () {
      final n = container.read(transactionFilterProvider.notifier);
      n.setQuery('milk');
      n.setFacets(
        TransactionFilter(
          query: 'ignored',
          from: '2026-11-01',
          accountIds: <String>{a.id},
        ),
      );
      TransactionFilter f = container.read(transactionFilterProvider);
      expect(f.query, 'milk');
      expect(f.from, '2026-11-01');
      n.setFacets(const TransactionFilter(types: {TransactionType.income}));
      f = container.read(transactionFilterProvider);
      expect(f.from, isNull);
      expect(f.accountIds, isEmpty);
      n.applySaved(
        SavedFilter(
          id: 'x',
          name: 'Cash',
          filter: TransactionFilter(accountIds: <String>{a.id}),
        ),
      );
      f = container.read(transactionFilterProvider);
      expect(f.query, 'milk');
      expect(f.accountIds, <String>{a.id});
      n.clear();
      expect(container.read(transactionFilterProvider), TransactionFilter.none);
    });
  });

  group('list notifier', () {
    test('first page, loadMore, no duplicates, day totals', () async {
      await seed(120);
      final TransactionsListState first = await loaded();
      expect(first.items, hasLength(50));
      expect(first.hasMore, isTrue);
      await container.read(transactionsListProvider.notifier).loadMore();
      expect(current()!.items, hasLength(100));
      await container.read(transactionsListProvider.notifier).loadMore();
      final TransactionsListState all = current()!;
      expect(all.items, hasLength(120));
      expect(all.hasMore, isFalse);
      expect(
        all.items.map((TransactionListItem i) => i.entry.id).toSet(),
        hasLength(120),
      );
      for (final DayGroup g in all.groups) {
        expect(
          g.total.expense,
          g.items.fold<int>(
            0,
            (int s, TransactionListItem i) => s + i.entry.amount,
          ),
        );
      }
    });

    test('loadMore called many times reads one page', () async {
      await seed(120);
      await loaded();
      final n = container.read(transactionsListProvider.notifier);
      await Future.wait(<Future<void>>[
        n.loadMore(),
        n.loadMore(),
        n.loadMore(),
      ]);
      expect(current()!.items, hasLength(100));
      expect(current()!.loadingMore, isFalse);
    });

    test('loadMore does nothing without more rows', () async {
      await seed(3);
      await loaded();
      await container.read(transactionsListProvider.notifier).loadMore();
      expect(current()!.items, hasLength(3));
    });

    test('edit keeps the loaded count and shows the change', () async {
      await seed(120);
      await loaded();
      await container.read(transactionsListProvider.notifier).loadMore();
      final TransactionEntry target = rows[100];
      env.clock.advance();
      await env.transactions.update(
        target.id,
        expenseDraft(
          accountId: a.id,
          categoryId: groceries,
          amount: 999999,
          date: target.date,
        ),
      );
      await until(
        () => current()!.items.any(
          (TransactionListItem i) =>
              i.entry.id == target.id && i.entry.amount == 999999,
        ),
      );
      expect(current()!.items, hasLength(100));
    });

    test('a reload keeps the instance of unchanged rows', () async {
      await seed(60);
      await loaded();
      final List<TransactionListItem> before = current()!.items;
      env.clock.advance();
      await env.transactions.update(
        rows[30].id,
        expenseDraft(
          accountId: a.id,
          categoryId: groceries,
          amount: 424242,
          date: rows[30].date,
        ),
      );
      await until(
        () => current()!.items.any(
          (TransactionListItem i) => i.entry.amount == 424242,
        ),
      );
      final List<TransactionListItem> after = current()!.items;
      expect(after, hasLength(before.length));
      int same = 0;
      for (int i = 0; i < after.length; i++) {
        if (identical(after[i], before[i])) same++;
      }
      expect(same, before.length - 1, reason: 'only the edited row is new');
    });

    test('delete and undo keep the loaded count', () async {
      await seed(120);
      await loaded();
      await container.read(transactionsListProvider.notifier).loadMore();
      final String newest = current()!.items.first.entry.id;
      final TransactionActions actions = container.read(
        transactionActionsProvider,
      );
      expect(await actions.delete(newest), isTrue);
      await until(
        () => current()!.items.every(
          (TransactionListItem i) => i.entry.id != newest,
        ),
      );
      expect(current()!.items, hasLength(100));
      expect(await actions.undoDelete(newest), isTrue);
      await until(() => current()!.items.first.entry.id == newest);
      expect(current()!.items, hasLength(100));
    });

    test('keeps old rows while a new filter loads, then swaps', () async {
      await seed(60);
      await loaded();
      container
          .read(transactionFilterProvider.notifier)
          .setFacets(TransactionFilter(accountIds: <String>{b.id}));
      final AsyncValue<TransactionsListState> mid = container.read(
        transactionsListProvider,
      );
      expect(mid.isLoading, isTrue);
      expect(mid.value, isNotNull, reason: 'previous data kept');
      await container.read(transactionsListProvider.future);
      expect(
        current()!.items.every(
          (TransactionListItem i) => i.entry.accountId == b.id,
        ),
        isTrue,
      );
      expect(current()!.items, hasLength(30));
    });

    test('a failed page sets loadMoreFailed and can retry', () async {
      await seed(60);
      await loaded();
      final TransactionsListState s = current()!;
      // Break the next read: close nothing, force a bad cursor via the db.
      await env.rawSql('ALTER TABLE transactions RENAME TO tx_gone');
      await container.read(transactionsListProvider.notifier).loadMore();
      expect(current()!.loadMoreFailed, isTrue);
      expect(current()!.loadingMore, isFalse);
      expect(current()!.items, hasLength(s.items.length));
      await env.rawSql('ALTER TABLE tx_gone RENAME TO transactions');
      await container.read(transactionsListProvider.notifier).loadMore();
      expect(current()!.loadMoreFailed, isFalse);
      expect(current()!.items, hasLength(60));
    });
  });

  group('month summary and detail providers', () {
    test('follow the filter and the data', () async {
      await seed(8);
      container.listen(monthSummaryProvider('2026-10'), (_, _) {});
      final MonthSummary all = await container.read(
        monthSummaryProvider('2026-10').future,
      );
      expect(
        all.spent,
        rows.fold<int>(0, (int s, TransactionEntry e) => s + e.amount),
      );
      container
          .read(transactionFilterProvider.notifier)
          .setFacets(TransactionFilter(accountIds: <String>{a.id}));
      await until(
        () =>
            container.read(monthSummaryProvider('2026-10')).value?.spent ==
            rows
                .where((TransactionEntry e) => e.accountId == a.id)
                .fold<int>(0, (int s, TransactionEntry e) => s + e.amount),
      );
    });

    test('detail follows edits and becomes null on delete', () async {
      await seed(1);
      final String id = rows.first.id;
      container.listen(transactionDetailProvider(id), (_, _) {});
      final TransactionListItem? item = await container.read(
        transactionDetailProvider(id).future,
      );
      expect(item!.accountName, 'A');
      await env.transactions.softDelete(id);
      await until(
        () => container.read(transactionDetailProvider(id)).value == null,
      );
    });
  });

  group('actions', () {
    test('never throw and log id only', () async {
      await seed(1);
      final TransactionActions actions = container.read(
        transactionActionsProvider,
      );
      env.sink.records.clear();
      expect(await actions.delete(rows.first.id), isTrue);
      expect(await actions.delete(rows.first.id), isFalse); // already gone
      expect(await actions.delete('nope'), isFalse);
      expect(await actions.undoDelete('nope'), isFalse);
      expect(await actions.undoDelete(rows.first.id), isTrue);
      expect(await actions.undoDelete(rows.first.id), isTrue); // idempotent
      final String text = env.sink.allText;
      expect(text, contains(rows.first.id.substring(0, 8)));
      expect(text, isNot(contains(rows.first.id)));
      expect(text, isNot(contains('Groceries')));
    });

    test('undo is false when the account was removed meanwhile', () async {
      await seed(1);
      final TransactionActions actions = container.read(
        transactionActionsProvider,
      );
      await actions.delete(rows.first.id);
      await env.accounts.softDelete(a.id);
      expect(await actions.undoDelete(rows.first.id), isFalse);
    });
  });

  group('saved filters file limits', () {
    test('names are checked on read like on add', () {
      const String id = '00000000-0000-4000-8000-0000000000f1';
      String doc(String name) =>
          '{"filters":[{"id":"$id","name":"$name","filter":'
          '{"accountIds":["00000000-0000-4000-8000-0000000000a1"]}}]}';
      expect(decodeSavedFilters(doc('Cash')), hasLength(1));
      expect(decodeSavedFilters(doc(r'a\u0007b')), isEmpty);
      expect(decodeSavedFilters(doc('x' * 25)), isEmpty);
      expect(decodeSavedFilters(doc('   ')), isEmpty);
    });

    test('a file over 64 KB is not read', () async {
      expect(decodeSavedFilters('x' * (maxSavedFiltersBytes + 1)), isNull);
      final Directory dir = await Directory.systemTemp.createTemp('sf_');
      addTearDown(() => dir.delete(recursive: true));
      File('${dir.path}/$savedFiltersFileName')
          .writeAsStringSync(' ' * (maxSavedFiltersBytes + 1));
      final ProviderContainer c = containerFor(
        env,
        extra: [
          savedFiltersStoreProvider.overrideWithValue(
            FileSavedFiltersStore(() async => dir),
          ),
        ],
      );
      addTearDown(c.dispose);
      c.listen(savedFiltersProvider, (_, _) {});
      env.sink.records.clear();
      expect(await c.read(savedFiltersProvider.future), isEmpty);
      expect(env.sink.allText, contains('could not be read'));
    });
  });

  group('saved filters', () {
    const TransactionFilter facets = TransactionFilter(
      accountIds: <String>{'00000000-0000-4000-8000-0000000000a1'},
    );

    Future<SavedFiltersNotifier> notifier() async {
      container.listen(savedFiltersProvider, (_, _) {});
      await container.read(savedFiltersProvider.future);
      return container.read(savedFiltersProvider.notifier);
    }

    Future<void> rejects(Future<Object?> f, FailureCode code) => expectLater(
      f,
      throwsA(
        isA<ValidationFailure>().having(
          (ValidationFailure v) => v.code,
          'code',
          code,
        ),
      ),
    );

    test('add, persist, reload from the store, remove', () async {
      final SavedFiltersNotifier n = await notifier();
      final SavedFilter s = await n.add(
        '  Cash  ',
        facets.copyWith(query: 'milk'),
      );
      expect(s.name, 'Cash');
      expect(s.filter.query, isEmpty, reason: 'facets only');
      expect(container.read(savedFiltersProvider).value, hasLength(1));

      final ProviderContainer second = containerFor(
        env,
        extra: [savedFiltersStoreProvider.overrideWithValue(store)],
      );
      addTearDown(second.dispose);
      second.listen(savedFiltersProvider, (_, _) {});
      final List<SavedFilter> back = await second.read(
        savedFiltersProvider.future,
      );
      expect(back, <SavedFilter>[s]);

      await n.remove(s.id);
      expect(container.read(savedFiltersProvider).value, isEmpty);
      await n.remove('missing'); // no error
    });

    test('name rules', () async {
      final SavedFiltersNotifier n = await notifier();
      await rejects(n.add('   ', facets), FailureCode.required);
      await rejects(
        n.add('x' * (maxSavedFilterName + 1), facets),
        FailureCode.tooLong,
      );
      await rejects(n.add('a\u0007b', facets), FailureCode.invalidCharacters);
      await n.add('x' * maxSavedFilterName, facets);
      await n.add('Cash', facets);
      await rejects(n.add('cASH', facets), FailureCode.duplicate);
      expect(container.read(savedFiltersProvider).value, hasLength(2));
    });

    test('facets are required and checked', () async {
      final SavedFiltersNotifier n = await notifier();
      await rejects(
        n.add('A', const TransactionFilter(query: 'milk')),
        FailureCode.required,
      );
      await rejects(
        n.add(
          'B',
          const TransactionFilter(from: '2026-12-01', to: '2026-11-01'),
        ),
        FailureCode.rule,
      );
    });

    test('at most maxSavedFilters', () async {
      final SavedFiltersNotifier n = await notifier();
      for (int i = 0; i < maxSavedFilters; i++) {
        await n.add('F$i', facets);
      }
      await rejects(n.add('One more', facets), FailureCode.rule);
    });

    test('two quick adds are both kept', () async {
      final SavedFiltersNotifier n = await notifier();
      await Future.wait(<Future<SavedFilter>>[
        n.add('One', facets),
        n.add('Two', facets),
      ]);
      expect(container.read(savedFiltersProvider).value, hasLength(2));
      expect(decodeSavedFilters(store.text), hasLength(2));
    });

    test('corrupt file gives an empty list and a warning', () async {
      for (final String bad in <String>[
        'not json',
        '[1,2]',
        '{"filters": 5}',
        '\u0000\u0000',
      ]) {
        store.text = bad;
        final ProviderContainer c = containerFor(
          env,
          extra: [savedFiltersStoreProvider.overrideWithValue(store)],
        );
        addTearDown(c.dispose);
        c.listen(savedFiltersProvider, (_, _) {});
        env.sink.records.clear();
        expect(await c.read(savedFiltersProvider.future), isEmpty);
        expect(env.sink.allText, contains('corrupt'));
      }
    });

    test('bad single entries are dropped, good ones kept', () async {
      const SavedFilter good = SavedFilter(
        id: '00000000-0000-4000-8000-0000000000f1',
        name: 'Good',
        filter: facets,
      );
      store.text =
          '{"filters":[${_json(good)},{"id":"x"},5,'
          '{"id":"00000000-0000-4000-8000-0000000000f2","name":"Bad",'
          '"filter":{"from":"nope","accountIds":[]}}]}';
      final List<SavedFilter>? read = decodeSavedFilters(store.text);
      expect(read, <SavedFilter>[good]);
    });

    test(
      'a failing store never crashes: read gives empty, write throws',
      () async {
        final ProviderContainer c = containerFor(
          env,
          extra: [
            savedFiltersStoreProvider.overrideWithValue(
              _FailingStore(failRead: true, failWrite: true),
            ),
          ],
        );
        addTearDown(c.dispose);
        c.listen(savedFiltersProvider, (_, _) {});
        expect(await c.read(savedFiltersProvider.future), isEmpty);
        await expectLater(
          c.read(savedFiltersProvider.notifier).add('A', facets),
          throwsA(isA<StorageFailure>()),
        );
        expect(c.read(savedFiltersProvider).value, isEmpty);
      },
    );
  });
}

String _json(SavedFilter f) =>
    encodeSavedFilters(<SavedFilter>[f])
        .replaceAll(RegExp(r'^\{"version":1,"filters":\[|\]\}$'), '');

void fileStoreTests() {
  test('file store: missing file, round trip, no temp file left', () async {
    final Directory dir = await Directory.systemTemp.createTemp('sf_');
    addTearDown(() => dir.delete(recursive: true));
    final FileSavedFiltersStore s = FileSavedFiltersStore(() async => dir);
    expect(await s.read(), isNull);
    await s.write('{"filters":[]}');
    expect(await s.read(), '{"filters":[]}');
    await s.write('{"filters":[],"x":1}');
    expect(await s.read(), '{"filters":[],"x":1}');
    expect(File('${dir.path}/$savedFiltersFileName.tmp').existsSync(), isFalse);
  });
}
