import '../../../core/sync/synced_entity.dart';

enum CategoryKind { expense, income }

/// Colour group names from DESIGN.md. Income categories use `income`.
enum CategoryColourGroup {
  essentials,
  food,
  transport,
  home,
  lifestyle,
  health,
  family,
  finance,
  other,
  income,
}

final class Category extends SyncedEntity {
  const Category({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.deletedAt,
    required super.syncStatus,
    required this.name,
    required this.kind,
    required this.colourGroup,
    required this.icon,
    required this.sortOrder,
    required this.archived,
  });

  final String name;
  final CategoryKind kind;
  final CategoryColourGroup colourGroup;

  /// Lucide icon name in kebab case, e.g. `shopping-cart`.
  final String icon;
  final int sortOrder;
  final bool archived;
}

class CategoryDraft {
  const CategoryDraft({
    required this.name,
    required this.kind,
    required this.colourGroup,
    required this.icon,
    this.sortOrder = 0,
    this.archived = false,
  });

  final String name;
  final CategoryKind kind;
  final CategoryColourGroup colourGroup;
  final String icon;
  final int sortOrder;
  final bool archived;
}

/// Total spent in one category (paise), for top-categories and budgets.
class CategoryTotal {
  const CategoryTotal({required this.categoryId, required this.total});

  final String categoryId;
  final int total;
}
