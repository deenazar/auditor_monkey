import '../../../core/sync/synced_entity.dart';

/// A monthly limit for one expense category.
final class Budget extends SyncedEntity {
  const Budget({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.deletedAt,
    required super.syncStatus,
    required this.categoryId,
    required this.month,
    required this.amount,
  });

  final String categoryId;

  /// `YYYY-MM`.
  final String month;

  /// Paise, above zero.
  final int amount;
}

class BudgetDraft {
  const BudgetDraft({
    required this.categoryId,
    required this.month,
    required this.amount,
  });

  final String categoryId;
  final String month;
  final int amount;
}
