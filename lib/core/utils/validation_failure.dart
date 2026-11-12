/// Typed failures thrown by the data layer.
///
/// Repositories never let a raw database error reach the UI. They throw one
/// of these instead. The [message] is short, plain English and safe to show
/// (it never contains amounts, names or notes).
library;

/// What went wrong, in a form code can switch on.
enum FailureCode {
  required,
  tooLong,
  outOfRange,
  invalidFormat,
  invalidDate,
  invalidChoice,
  invalidCharacters,
  rule,
  referenceMissing,
  kindMismatch,
  notFound,
  inUse,
  duplicate,
  overflow,
  storage,
}

sealed class DataFailure implements Exception {
  const DataFailure(this.code, this.message);

  final FailureCode code;
  final String message;

  @override
  String toString() => '$runtimeType(${code.name}): $message';
}

/// An input value is not allowed. [field] names the input, e.g. `amount`.
final class ValidationFailure extends DataFailure {
  const ValidationFailure(this.field, FailureCode code, String message)
    : super(code, message);

  final String field;

  @override
  String toString() => 'ValidationFailure($field, ${code.name}): $message';
}

/// The row asked for does not exist (or is deleted).
final class NotFoundFailure extends DataFailure {
  const NotFoundFailure([String message = 'Item not found.'])
    : super(FailureCode.notFound, message);
}

/// Delete refused because other live rows still use this one.
final class InUseFailure extends DataFailure {
  const InUseFailure(String message) : super(FailureCode.inUse, message);
}

/// A unique rule was broken (same name, same budget month, same rate day).
final class DuplicateFailure extends DataFailure {
  const DuplicateFailure(String message)
    : super(FailureCode.duplicate, message);
}

/// A total went past what the database can hold.
final class OverflowFailure extends DataFailure {
  const OverflowFailure([
    String message = 'The total is too large to calculate.',
  ]) : super(FailureCode.overflow, message);
}

/// Any other database problem, including a DB CHECK that fired because a
/// repository check was bypassed.
final class StorageFailure extends DataFailure {
  const StorageFailure([String message = 'Could not save. Please try again.'])
    : super(FailureCode.storage, message);
}
