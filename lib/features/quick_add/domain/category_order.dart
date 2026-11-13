import '../../categories/domain/category.dart';
import 'quick_add_hints.dart';

/// Most suggested categories shown first.
const int maxSuggestedCategories = 6;

/// Categories of one kind in display order: [suggested] first, then [rest].
class OrderedCategories {
  const OrderedCategories({required this.suggested, required this.rest});

  static const OrderedCategories empty = OrderedCategories(
    suggested: <Category>[],
    rest: <Category>[],
  );

  /// Up to 6: the last-used category, then the most used, newest use first.
  final List<Category> suggested;

  /// Every other offered category, by sort order.
  final List<Category> rest;

  /// Suggested first, then the rest.
  List<Category> get all => <Category>[...suggested, ...rest];

  bool get isEmpty => suggested.isEmpty && rest.isEmpty;
}

int _bySortOrder(Category a, Category b) {
  final int c = a.sortOrder.compareTo(b.sortOrder);
  return c != 0 ? c : a.id.compareTo(b.id);
}

/// Orders [offered] (live, not archived, right kind): suggested first (max
/// [maxSuggestedCategories]): [lastUsedId], then by uses (more first), last
/// use (newer first), sort order, id. Then everything else by sort order.
/// Ties are fixed, so the result is the same every time.
OrderedCategories orderCategories({
  required List<Category> offered,
  required List<CategoryUsage> usage,
  String? lastUsedId,
}) {
  final Map<String, Category> byId = <String, Category>{
    for (final Category c in offered) c.id: c,
  };
  final Map<String, CategoryUsage> usageById = <String, CategoryUsage>{
    for (final CategoryUsage u in usage) u.categoryId: u,
  };
  final List<Category> used = <Category>[
    for (final CategoryUsage u in usage)
      if (byId.containsKey(u.categoryId) && u.categoryId != lastUsedId)
        byId[u.categoryId]!,
  ];
  used.sort((Category a, Category b) {
    final CategoryUsage ua = usageById[a.id]!;
    final CategoryUsage ub = usageById[b.id]!;
    int c = ub.uses.compareTo(ua.uses);
    if (c == 0) c = ub.lastUsed.compareTo(ua.lastUsed);
    return c != 0 ? c : _bySortOrder(a, b);
  });
  final List<Category> suggested = <Category>[
    if (lastUsedId != null && byId.containsKey(lastUsedId)) byId[lastUsedId]!,
    ...used,
  ].take(maxSuggestedCategories).toList(growable: false);
  final Set<String> suggestedIds = <String>{
    for (final Category c in suggested) c.id,
  };
  final List<Category> rest = <Category>[
    for (final Category c in offered)
      if (!suggestedIds.contains(c.id)) c,
  ]..sort(_bySortOrder);
  return OrderedCategories(
    suggested: List<Category>.unmodifiable(suggested),
    rest: List<Category>.unmodifiable(rest),
  );
}
