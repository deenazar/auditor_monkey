import 'package:auditor_monkey/core/money/money.dart';
import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/gold/domain/gold.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_env.dart';

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());
  tearDown(() => env.close());

  Future<int?> valueOf(String holdingId) async {
    final List<GoldHoldingValue> all = await env.gold.getHoldingValues();
    return all
        .firstWhere((GoldHoldingValue v) => v.holding.id == holdingId)
        .currentValue;
  }

  group('rates', () {
    test('create, update, delete, restore', () async {
      final GoldRate r = await env.gold.createRate(goldRateDraft());
      expect(r.purity, GoldPurity.k22);
      expect(r.ratePerGram, 700000);
      env.clock.advance();
      final GoldRate u = await env.gold.updateRate(
        r.id,
        goldRateDraft(rate: 710000, purity: GoldPurity.k24),
      );
      expect(u.purity, GoldPurity.k24);
      expect(u.updatedAt, r.updatedAt + 1000);
      await env.gold.softDeleteRate(r.id);
      expect(await env.gold.watchRates().first, isEmpty);
      expect((await env.gold.restoreRate(r.id)).isDeleted, isFalse);
    });

    test('one live rate per date and purity', () async {
      final GoldRate first = await env.gold.createRate(goldRateDraft());
      await expectLater(
        env.gold.createRate(goldRateDraft(rate: 1)),
        throwsA(isA<DuplicateFailure>()),
      );
      await env.gold.createRate(goldRateDraft(purity: GoldPurity.k24));
      await env.gold.createRate(goldRateDraft(date: '2026-11-13'));
      await env.gold.softDeleteRate(first.id);
      final GoldRate again = await env.gold.createRate(goldRateDraft());
      await expectLater(
        env.gold.restoreRate(first.id),
        throwsA(isA<DuplicateFailure>()),
      );
      await env.gold.softDeleteRate(again.id);
      await env.gold.restoreRate(first.id);
    });

    test('validation: date and rate range', () async {
      for (final GoldRateDraft d in <GoldRateDraft>[
        goldRateDraft(date: '2026-02-30'),
        goldRateDraft(rate: 0),
        goldRateDraft(rate: -1),
        goldRateDraft(rate: maxGoldRatePerGram + 1),
      ]) {
        await expectLater(
          env.gold.createRate(d),
          throwsA(isA<ValidationFailure>()),
        );
      }
      await env.gold.createRate(goldRateDraft(rate: maxGoldRatePerGram));
      await env.gold.createRate(goldRateDraft(date: '2026-11-01', rate: 1));
    });

    test('rates are listed newest first', () async {
      await env.gold.createRate(goldRateDraft(date: '2026-11-01'));
      await env.gold.createRate(goldRateDraft(date: '2026-11-10'));
      await env.gold.createRate(
        goldRateDraft(date: '2026-11-10', purity: GoldPurity.k18),
      );
      final List<GoldRate> list = await env.gold.watchRates().first;
      expect(list.map((GoldRate r) => r.date), <String>[
        '2026-11-10',
        '2026-11-10',
        '2026-11-01',
      ]);
    });
  });

  group('holdings', () {
    test('create, update, delete, restore', () async {
      final GoldHolding h = await env.gold.createHolding(goldHoldingDraft());
      expect(h.purity, GoldPurity.k22);
      expect(h.weightMg, 10000);
      env.clock.advance();
      final GoldHolding u = await env.gold.updateHolding(
        h.id,
        goldHoldingDraft(weightMg: 20000, purity: GoldPurity.k24),
      );
      expect(u.weightMg, 20000);
      expect(u.purity, GoldPurity.k24);
      expect(u.updatedAt, h.updatedAt + 1000);
      await env.gold.softDeleteHolding(h.id);
      expect(await env.gold.getHolding(h.id), isNull);
      expect((await env.gold.restoreHolding(h.id)).isDeleted, isFalse);
    });

    test(
      'an optional account is information only: no transaction made',
      () async {
        final Account a = await env.account('Bank', opening: 1000);
        final GoldHolding h = await env.gold.createHolding(
          goldHoldingDraft(accountId: a.id),
        );
        expect(h.accountId, a.id);
        expect(await env.count('transactions'), 0);
        expect((await env.accounts.getBalances()).single.balance, 1000);
        await expectLater(
          env.gold.createHolding(goldHoldingDraft(accountId: 'nope')),
          throwsA(isA<ValidationFailure>()),
        );
      },
    );

    test('validation: description, weight, date, price', () async {
      GoldHoldingDraft d({
        String description = 'Ring',
        int weightMg = 100,
        String date = '2025-05-01',
        int price = 0,
      }) => GoldHoldingDraft(
        description: description,
        weightMg: weightMg,
        purity: GoldPurity.k18,
        purchaseDate: date,
        purchasePrice: price,
      );
      for (final GoldHoldingDraft bad in <GoldHoldingDraft>[
        d(description: ' '),
        d(description: 'x' * 81),
        d(weightMg: 0),
        d(weightMg: maxGoldWeightMg + 1),
        d(date: '2025-13-01'),
        d(price: -1),
        d(price: maxPaise + 1),
      ]) {
        await expectLater(
          env.gold.createHolding(bad),
          throwsA(isA<ValidationFailure>()),
        );
      }
      // Zero price (a gift) and the exact limits are fine.
      await env.gold.createHolding(d());
      await env.gold.createHolding(
        d(weightMg: maxGoldWeightMg, price: maxPaise),
      );
    });
  });

  group('current value', () {
    test('is weight x latest rate of the same purity', () async {
      final GoldHolding h = await env.gold.createHolding(
        goldHoldingDraft(weightMg: 10000, purity: GoldPurity.k22),
      );
      expect(await valueOf(h.id), isNull);
      await env.gold.createRate(
        goldRateDraft(date: '2026-11-01', rate: 600000),
      );
      await env.gold.createRate(
        goldRateDraft(date: '2026-11-10', rate: 700000),
      );
      await env.gold.createRate(
        goldRateDraft(date: '2026-11-11', rate: 900000, purity: GoldPurity.k24),
      );
      // 10 g x 7000.00 = 70,000.00 rupees.
      expect(await valueOf(h.id), 7000000);
    });

    test('a deleted latest rate falls back to the older one', () async {
      final GoldHolding h = await env.gold.createHolding(goldHoldingDraft());
      await env.gold.createRate(
        goldRateDraft(date: '2026-11-01', rate: 600000),
      );
      final GoldRate latest = await env.gold.createRate(
        goldRateDraft(date: '2026-11-10', rate: 700000),
      );
      await env.gold.softDeleteRate(latest.id);
      expect(await valueOf(h.id), 6000000);
    });

    test('a deleted holding is not listed', () async {
      final GoldHolding h = await env.gold.createHolding(goldHoldingDraft());
      await env.gold.softDeleteHolding(h.id);
      expect(await env.gold.getHoldingValues(), isEmpty);
    });

    test('rounds half up to whole paise (exact integer maths)', () async {
      // value = (mg * rate + 500) / 1000 using whole numbers.
      final Map<(int, int), int> cases = <(int, int), int>{
        (1, 500): 1, // 0.5 -> 1
        (1, 499): 0, // 0.499 -> 0
        (1, 1500): 2, // 1.5 -> 2
        (3, 1666): 5, // 4.998 -> 5
        (1001, 1234): 1235, // 1235.234 -> 1235
        (999, 1): 1, // 0.999 -> 1
        (1000, 1): 1, // exactly 1
        (10000, 700000): 7000000,
        (maxGoldWeightMg, maxGoldRatePerGram): 100000000000000,
      };
      int n = 0;
      for (final MapEntry<(int, int), int> e in cases.entries) {
        n++;
        final String date = '2026-01-${n.toString().padLeft(2, '0')}';
        final GoldHolding h = await env.gold.createHolding(
          goldHoldingDraft(weightMg: e.key.$1, purity: GoldPurity.k18),
        );
        // A newer rate for each case, so the latest rate is this one.
        await env.gold.createRate(
          goldRateDraft(date: date, purity: GoldPurity.k18, rate: e.key.$2),
        );
        expect(await valueOf(h.id), e.value, reason: '${e.key}');
        await env.gold.softDeleteHolding(h.id);
      }
    });
  });
}
