import '../../../core/utils/validation_failure.dart';
import '../../categories/domain/category.dart';

/// How many categories the Dashboard "Top spending" card shows.
const int topCategoryCount = 3;

/// One row of the Top spending card.
class TopCategoryShare {
  const TopCategoryShare({
    required this.categoryId,
    required this.total,
    required this.percent,
  });

  final String categoryId;

  /// Spending in the category this month (paise).
  final int total;

  /// Share of the month's spending, whole percent, rounded half up
  /// (integer maths). 0 to 100.
  final int percent;

  /// The text for the UI, e.g. `48%`.
  String get percentLabel => '$percent%';
}

/// Half-up whole percent of [part] in [whole]: `floor((200*part + whole) /
/// (2*whole))`. Integer maths only. [whole] <= 0 or [part] <= 0 gives 0.
/// The result is kept between 0 and 100.
///
/// Throws [OverflowFailure] when the numbers are too big to multiply.
int percentHalfUp(int part, int whole) {
  if (whole <= 0 || part <= 0) return 0;
  if (whole > _maxMultiplicand) throw const OverflowFailure();
  return ((200 * part + whole) ~/ (2 * whole)).clamp(0, 100);
}

/// Biggest int that can be multiplied by 200 without overflow.
const int _maxMultiplicand = 46116860184273879; // (2^63 - 1) ~/ 200

/// The first [limit] (default 3) categories by spending, each with its share
/// of [monthSpent].
///
/// [totals] are the month's expense totals per category (loan rows already
/// left out by SQL). They are sorted here as well, so the result never
/// depends on the input order: biggest total first, ties by category id.
/// Zero or negative totals are skipped. [limit] must be 1 to 500.
List<TopCategoryShare> topCategoryShares(
  List<CategoryTotal> totals,
  int monthSpent, {
  int limit = topCategoryCount,
}) {
  if (limit < 1 || limit > 500) {
    throw const ValidationFailure(
      'limit',
      FailureCode.outOfRange,
      'Limit is not allowed.',
    );
  }
  final List<CategoryTotal> sorted =
      totals.where((CategoryTotal c) => c.total > 0).toList()..sort(
        (CategoryTotal a, CategoryTotal b) => a.total != b.total
            ? b.total.compareTo(a.total)
            : a.categoryId.compareTo(b.categoryId),
      );
  return List<TopCategoryShare>.unmodifiable(
    sorted
        .take(limit)
        .map(
          (CategoryTotal c) => TopCategoryShare(
            categoryId: c.categoryId,
            total: c.total,
            percent: percentHalfUp(c.total, monthSpent),
          ),
        ),
  );
}
