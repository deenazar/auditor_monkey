import '../../../core/utils/validation_failure.dart';
import '../../../core/utils/validators.dart';
import 'transaction_filter.dart';

final RegExp _controlChars = RegExp(r'[\u0000-\u001F\u007F]');

/// Checks a list filter (no database needed) and returns a cleaned copy:
/// the search text is trimmed. Throws [ValidationFailure] with a plain
/// message. Ids only need the shape of a UUID; unknown ids simply match
/// nothing.
TransactionFilter validateTransactionFilter(TransactionFilter filter) {
  final String query = filter.query.trim();
  ensure(
    query.length <= maxSearchLength,
    'query',
    FailureCode.tooLong,
    'Use $maxSearchLength characters or fewer to search.',
  );
  ensure(
    !_controlChars.hasMatch(query),
    'query',
    FailureCode.invalidCharacters,
    'Remove special characters from the search.',
  );
  if (filter.from != null) validateDate('from', filter.from);
  if (filter.to != null) validateDate('to', filter.to);
  if (filter.from != null && filter.to != null) {
    ensure(
      filter.from!.compareTo(filter.to!) <= 0,
      'to',
      FailureCode.rule,
      'End date cannot be before the start date.',
    );
  }
  _checkIds('accountIds', filter.accountIds);
  _checkIds('categoryIds', filter.categoryIds);
  return filter.copyWith(query: query);
}

void _checkIds(String field, Set<String> ids) {
  ensure(
    ids.length <= maxFilterIds,
    field,
    FailureCode.outOfRange,
    'Pick at most $maxFilterIds items.',
  );
  ensure(
    ids.every(isUuidShape),
    field,
    FailureCode.invalidFormat,
    'One of the picked items is not available.',
  );
}
