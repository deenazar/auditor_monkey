import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/categories/domain/category.dart';
import 'package:auditor_monkey/features/home/domain/top_categories.dart';
import 'package:flutter_test/flutter_test.dart';

CategoryTotal _c(String id, int paise) =>
    CategoryTotal(categoryId: id, total: paise);

void main() {
  test('hand-checked October 2026: Rent 48, Groceries 17, Food 11', () {
    final List<TopCategoryShare> top = topCategoryShares(<CategoryTotal>[
      _c('shopping', 320000),
      _c('rent', 1500000),
      _c('groceries', 545050),
      _c('food', 335000),
      _c('fuel', 185075),
    ], 3130050);
    expect(top.map((TopCategoryShare t) => t.categoryId), <String>[
      'rent',
      'groceries',
      'food',
    ]);
    expect(top.map((TopCategoryShare t) => t.percent), <int>[48, 17, 11]);
    expect(top.first.total, 1500000);
    expect(top.first.percentLabel, '48%');
  });

  test('ties: same total, smaller category id first', () {
    final List<TopCategoryShare> top = topCategoryShares(<CategoryTotal>[
      _c('b', 100),
      _c('a', 100),
      _c('c', 100),
      _c('d', 100),
    ], 400);
    expect(top.map((TopCategoryShare t) => t.categoryId), <String>[
      'a',
      'b',
      'c',
    ]);
    expect(top.first.percent, 25);
  });

  test('half-up rounding in integer maths', () {
    expect(percentHalfUp(1, 2), 50);
    expect(percentHalfUp(1, 8), 13); // 12.5 -> 13
    expect(percentHalfUp(3, 8), 38); // 37.5 -> 38
    expect(percentHalfUp(1, 3), 33);
    expect(percentHalfUp(2, 3), 67);
    expect(percentHalfUp(499, 1000), 50); // 49.9
    expect(percentHalfUp(494, 1000), 49); // 49.4
    expect(percentHalfUp(495, 1000), 50); // 49.5
    expect(percentHalfUp(1, 1000), 0); // 0.1
    expect(percentHalfUp(5, 1000), 1); // 0.5
  });

  test('zero spent or zero part gives 0, never a crash', () {
    expect(percentHalfUp(0, 100), 0);
    expect(percentHalfUp(100, 0), 0);
    expect(topCategoryShares(const <CategoryTotal>[], 0), isEmpty);
    expect(topCategoryShares(<CategoryTotal>[_c('a', 5)], 0).single.percent, 0);
  });

  test('fewer than 3 categories, and the limit is respected', () {
    expect(topCategoryShares(<CategoryTotal>[_c('a', 5)], 5), hasLength(1));
    expect(
      topCategoryShares(<CategoryTotal>[_c('a', 5), _c('b', 4)], 9, limit: 1),
      hasLength(1),
    );
  });

  test('zero totals are skipped; percent never goes above 100', () {
    final List<TopCategoryShare> top = topCategoryShares(<CategoryTotal>[
      _c('a', 0),
      _c('b', 10),
    ], 5);
    expect(top.single.categoryId, 'b');
    expect(top.single.percent, 100);
  });

  test('limit must be 1 to 500; huge totals overflow safely', () {
    expect(
      () => topCategoryShares(const <CategoryTotal>[], 0, limit: 0),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      () => topCategoryShares(const <CategoryTotal>[], 0, limit: 501),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      () => percentHalfUp(9000000000000000000, 9000000000000000000),
      throwsA(isA<OverflowFailure>()),
    );
  });
}
