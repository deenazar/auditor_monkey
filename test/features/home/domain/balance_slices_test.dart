import 'package:auditor_monkey/core/sync/sync_status.dart';
import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/home/domain/balance_slices.dart';
import 'package:flutter_test/flutter_test.dart';

AccountBalance _b(
  String name,
  int rupees, {
  int sort = 0,
  bool archived = false,
  String id = '',
  int paise = 0,
}) => AccountBalance(
  account: Account(
    id: id.isEmpty ? 'id-$name' : id,
    createdAt: 1,
    updatedAt: 1,
    deletedAt: null,
    syncStatus: SyncStatus.pending,
    name: name,
    type: AccountType.bank,
    colour: 'accountSbi',
    openingBalance: 0,
    sortOrder: sort,
    archived: archived,
  ),
  balance: rupees * 100 + paise,
);

int _sum(BalanceSlices s) =>
    s.slices.fold<int>(0, (int a, BalanceSlice x) => a + x.percent);

void main() {
  group('hand-checked October 2026 doughnut (plan 5.5)', () {
    final BalanceSlices s = buildBalanceSlices(<AccountBalance>[
      _b('Hand', 2349, paise: 50),
      _b('SBI', 80000),
      _b('Axis', 17900),
      _b('Food Card', 850),
      _b('PF', 100000),
      _b('Outside', 0),
      _b('HDFC Card', -1800),
      _b('Old Wallet', 300, archived: true),
    ]);

    test('4 biggest + Other, biggest first, Other last', () {
      expect(s.slices.map((BalanceSlice x) => x.label), <String>[
        'PF',
        'SBI',
        'Axis',
        'Hand',
        'Other',
      ]);
      expect(s.slices.last.isOther, isTrue);
      expect(s.slices.last.amount, 115000);
      expect(s.slices.last.memberIds, hasLength(2));
      expect(s.slices.last.colourToken, isNull);
    });

    test('assets and owed', () {
      expect(s.assets, 20139950);
      expect(s.owed, -180000);
      expect(s.hasOwed, isTrue);
    });

    test('percents 50, 40, 9, 1, <1 and add to 100', () {
      expect(s.slices.map((BalanceSlice x) => x.percentLabel), <String>[
        '50%',
        '40%',
        '9%',
        '1%',
        '<1%',
      ]);
      expect(_sum(s), 100);
      expect(s.slices.last.lessThanOnePercent, isTrue);
      expect(s.slices.last.percent, 0);
    });
  });

  test('no accounts: empty', () {
    final BalanceSlices s = buildBalanceSlices(const <AccountBalance>[]);
    expect(s.hasSlices, isFalse);
    expect(s.assets, 0);
    expect(s.owed, 0);
    expect(s.hasOwed, isFalse);
  });

  test('all negative or zero: no slices, owed is the sum', () {
    final BalanceSlices s = buildBalanceSlices(<AccountBalance>[
      _b('A', -500),
      _b('B', -250),
      _b('C', 0),
    ]);
    expect(s.hasSlices, isFalse);
    expect(s.assets, 0);
    expect(s.owed, -75000);
  });

  test('exactly 5 positive accounts: no Other', () {
    final BalanceSlices s = buildBalanceSlices(<AccountBalance>[
      for (int i = 1; i <= 5; i++) _b('A$i', i * 100),
    ]);
    expect(s.slices, hasLength(5));
    expect(s.slices.any((BalanceSlice x) => x.isOther), isFalse);
    expect(s.slices.first.label, 'A5');
    expect(_sum(s), 100);
  });

  test('6 positive accounts: 4 biggest + Other of the 2 smallest', () {
    final BalanceSlices s = buildBalanceSlices(<AccountBalance>[
      for (int i = 1; i <= 6; i++) _b('A$i', i * 100),
    ]);
    expect(s.slices, hasLength(5));
    expect(s.slices.last.isOther, isTrue);
    expect(s.slices.last.amount, (100 + 200) * 100);
    expect(s.slices.last.memberIds, <String>['id-A2', 'id-A1']);
    expect(s.assets, 2100 * 100);
    expect(_sum(s), 100);
  });

  test('Other stays last even when it is bigger than the 4th slice', () {
    final BalanceSlices s = buildBalanceSlices(<AccountBalance>[
      _b('A', 1000),
      _b('B', 900),
      _b('C', 800),
      _b('D', 700),
      _b('E', 600),
      _b('F', 600),
    ]);
    expect(s.slices.last.isOther, isTrue);
    expect(s.slices.last.amount, 1200 * 100);
    expect(s.slices[3].label, 'D');
  });

  test('ties: same balance by sort order, then name', () {
    final BalanceSlices s = buildBalanceSlices(<AccountBalance>[
      _b('Zed', 100, sort: 1),
      _b('Bob', 100, sort: 2),
      _b('Amy', 100, sort: 2),
    ]);
    expect(s.slices.map((BalanceSlice x) => x.label), <String>[
      'Zed',
      'Amy',
      'Bob',
    ]);
    // 33.33 each: floors 33,33,33, one point goes to the first on a tie.
    expect(s.slices.map((BalanceSlice x) => x.percent), <int>[34, 33, 33]);
    expect(_sum(s), 100);
  });

  test('a single account is 100%', () {
    final BalanceSlices s = buildBalanceSlices(<AccountBalance>[_b('A', 5)]);
    expect(s.slices.single.percent, 100);
    expect(s.slices.single.lessThanOnePercent, isFalse);
  });

  test('archived accounts count', () {
    final BalanceSlices s = buildBalanceSlices(<AccountBalance>[
      _b('A', 100),
      _b('Old', 100, archived: true),
    ]);
    expect(s.slices, hasLength(2));
    expect(s.assets, 20000);
  });

  test('a tiny share is "<1%" and never takes a remainder point', () {
    // 99.5 / 0.25 / 0.25: floors 99,0,0 (sum 99), one point left.
    final BalanceSlices s = buildBalanceSlices(<AccountBalance>[
      _b('Big', 0, paise: 9950),
      _b('T1', 0, paise: 25),
      _b('T2', 0, paise: 25),
    ]);
    expect(s.slices.map((BalanceSlice x) => x.percentLabel), <String>[
      '100%',
      '<1%',
      '<1%',
    ]);
    expect(_sum(s), 100);
  });

  test('more points than big slices: they go round again', () {
    // One big slice and 3 tiny ones of 0.85% each (+ Other not needed).
    final BalanceSlices s = buildBalanceSlices(<AccountBalance>[
      _b('Big', 0, paise: 9660),
      _b('T1', 0, paise: 85),
      _b('T2', 0, paise: 85),
      _b('T3', 0, paise: 85),
      _b('T4', 0, paise: 85),
    ]);
    expect(_sum(s), 100);
    expect(s.slices.skip(1).every((BalanceSlice x) => x.percent == 0), isTrue);
  });

  test('percents always add to 100 over many shapes', () {
    for (int n = 1; n <= 9; n++) {
      for (int seed = 1; seed <= 40; seed++) {
        final BalanceSlices s = buildBalanceSlices(<AccountBalance>[
          for (int i = 0; i < n; i++)
            _b('A$i', 0, paise: 1 + (seed * 7919 * (i + 3)) % 100003),
        ]);
        expect(_sum(s), 100, reason: 'n=$n seed=$seed');
      }
    }
  });

  test('a total too large for percent maths is an OverflowFailure', () {
    expect(
      () => buildBalanceSlices(<AccountBalance>[
        _b('A', 0, paise: 9000000000000000000 % 1000),
      ]),
      returnsNormally,
    );
    final AccountBalance huge = AccountBalance(
      account: _b('H', 0).account,
      balance: 9000000000000000000,
    );
    expect(
      () => buildBalanceSlices(<AccountBalance>[huge, huge]),
      throwsA(isA<OverflowFailure>()),
    );
    expect(
      () => buildBalanceSlices(<AccountBalance>[huge]),
      throwsA(isA<OverflowFailure>()),
    );
  });
}
