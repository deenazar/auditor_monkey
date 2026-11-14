import 'transaction_entry.dart';

/// Longest search text (characters, after trimming).
const int maxSearchLength = 60;

/// Most accounts or categories one filter may hold.
const int maxFilterIds = 50;

/// What the Transactions list shows. Empty sets mean "all".
///
/// Facets combine with AND; values inside one facet combine with OR.
/// - [query]: matches the note (contains, any case), the category name
///   (contains, any case) or, when it reads as rupees ("250", "₹1,250.50"),
///   the exact amount.
/// - [from] / [to]: inclusive `YYYY-MM-DD` dates, either may be null.
/// - [accountIds]: an entry matches when its account OR its To account
///   (transfers) is in the set.
/// - [categoryIds]: transfers have no category, so they never match.
class TransactionFilter {
  const TransactionFilter({
    this.query = '',
    this.from,
    this.to,
    this.types = const <TransactionType>{},
    this.accountIds = const <String>{},
    this.categoryIds = const <String>{},
  });

  static const TransactionFilter none = TransactionFilter();

  final String query;
  final String? from;
  final String? to;
  final Set<TransactionType> types;
  final Set<String> accountIds;
  final Set<String> categoryIds;

  bool get hasQuery => query.trim().isNotEmpty;

  bool get hasDateRange => from != null || to != null;

  /// Number of active facets except the search text (for the filter badge).
  int get facetCount =>
      (hasDateRange ? 1 : 0) +
      (types.isNotEmpty ? 1 : 0) +
      (accountIds.isNotEmpty ? 1 : 0) +
      (categoryIds.isNotEmpty ? 1 : 0);

  bool get isEmpty => !hasQuery && facetCount == 0;

  TransactionFilter copyWith({
    String? query,
    String? from,
    String? to,
    bool clearDates = false,
    Set<TransactionType>? types,
    Set<String>? accountIds,
    Set<String>? categoryIds,
  }) => TransactionFilter(
    query: query ?? this.query,
    from: clearDates ? null : (from ?? this.from),
    to: clearDates ? null : (to ?? this.to),
    types: types ?? this.types,
    accountIds: accountIds ?? this.accountIds,
    categoryIds: categoryIds ?? this.categoryIds,
  );

  /// Same filter without the search text (saved chips keep facets only).
  TransactionFilter withoutQuery() => copyWith(query: '');

  Map<String, Object?> toJson() => <String, Object?>{
    'query': query,
    'from': from,
    'to': to,
    'types': (types.map((TransactionType t) => t.name).toList()..sort()),
    'accountIds': (accountIds.toList()..sort()),
    'categoryIds': (categoryIds.toList()..sort()),
  };

  /// Reads [toJson] output. Unknown or malformed values are dropped (never
  /// throws); the result is still checked by the validator before use.
  factory TransactionFilter.fromJson(Map<String, Object?> json) {
    Set<String> ids(Object? v) => v is List
        ? v.whereType<String>().take(maxFilterIds).toSet()
        : const <String>{};
    final Object? rawTypes = json['types'];
    return TransactionFilter(
      query: json['query'] is String ? json['query']! as String : '',
      from: json['from'] is String ? json['from']! as String : null,
      to: json['to'] is String ? json['to']! as String : null,
      types: rawTypes is List
          ? <TransactionType>{
              for (final TransactionType t in TransactionType.values)
                if (rawTypes.contains(t.name)) t,
            }
          : const <TransactionType>{},
      accountIds: ids(json['accountIds']),
      categoryIds: ids(json['categoryIds']),
    );
  }

  static bool _sameSet<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.query == query &&
      other.from == from &&
      other.to == to &&
      _sameSet(other.types, types) &&
      _sameSet(other.accountIds, accountIds) &&
      _sameSet(other.categoryIds, categoryIds);

  @override
  int get hashCode => Object.hash(
    query,
    from,
    to,
    Object.hashAllUnordered(types),
    Object.hashAllUnordered(accountIds),
    Object.hashAllUnordered(categoryIds),
  );
}

/// A named filter the user saved as a chip.
class SavedFilter {
  const SavedFilter({
    required this.id,
    required this.name,
    required this.filter,
  });

  final String id;

  /// 1 to [maxSavedFilterName] characters.
  final String name;
  final TransactionFilter filter;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'filter': filter.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is SavedFilter &&
      other.id == id &&
      other.name == name &&
      other.filter == filter;

  @override
  int get hashCode => Object.hash(id, name, filter);
}

/// Longest saved-filter name.
const int maxSavedFilterName = 24;

/// Most saved filters.
const int maxSavedFilters = 12;
