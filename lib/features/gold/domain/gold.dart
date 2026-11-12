import '../../../core/sync/synced_entity.dart';

/// Gold purity. Stored as `24k`, `22k`, `18k`.
enum GoldPurity {
  k24('24k'),
  k22('22k'),
  k18('18k');

  const GoldPurity(this.dbValue);

  final String dbValue;

  static GoldPurity parse(String value) =>
      GoldPurity.values.firstWhere((GoldPurity p) => p.dbValue == value);
}

final class GoldHolding extends SyncedEntity {
  const GoldHolding({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.deletedAt,
    required super.syncStatus,
    required this.description,
    required this.weightMg,
    required this.purity,
    required this.purchaseDate,
    required this.purchasePrice,
    required this.accountId,
  });

  final String description;

  /// Milligrams (whole number).
  final int weightMg;
  final GoldPurity purity;
  final String purchaseDate;

  /// Paise, zero allowed (gifts).
  final int purchasePrice;

  /// Information only. Creates no transaction.
  final String? accountId;
}

class GoldHoldingDraft {
  const GoldHoldingDraft({
    required this.description,
    required this.weightMg,
    required this.purity,
    required this.purchaseDate,
    required this.purchasePrice,
    this.accountId,
  });

  final String description;
  final int weightMg;
  final GoldPurity purity;
  final String purchaseDate;
  final int purchasePrice;
  final String? accountId;
}

/// Price of 1 gram of gold of one purity on one day.
final class GoldRate extends SyncedEntity {
  const GoldRate({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.deletedAt,
    required super.syncStatus,
    required this.date,
    required this.purity,
    required this.ratePerGram,
  });

  final String date;
  final GoldPurity purity;

  /// Paise per gram.
  final int ratePerGram;
}

class GoldRateDraft {
  const GoldRateDraft({
    required this.date,
    required this.purity,
    required this.ratePerGram,
  });

  final String date;
  final GoldPurity purity;
  final int ratePerGram;
}

/// A holding with its current value (paise), or `null` when no rate exists
/// for its purity yet.
class GoldHoldingValue {
  const GoldHoldingValue({required this.holding, required this.currentValue});

  final GoldHolding holding;
  final int? currentValue;
}

/// Largest weight: 100 kg in milligrams.
const int maxGoldWeightMg = 100000000;

/// Largest rate: Rs 1 crore per gram, in paise.
const int maxGoldRatePerGram = 1000000000;
