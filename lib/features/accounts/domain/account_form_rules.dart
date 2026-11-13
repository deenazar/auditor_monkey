/// Instant (UI) checks for the account name, shared by the wizard and the
/// add / edit account sheet. The data layer repeats the real checks
/// (`validateAccountDraft`); these give friendly messages while typing.
library;

/// Longest account name (same as the database rule).
const int accountNameMaxLength = 40;

final RegExp _controlChars = RegExp(r'[\u0000-\u001F\u007F]');

/// Friendly message when [name] cannot be used, else `null`.
///
/// [otherNames] are the names of the other accounts (not this one). They
/// are compared ignoring case and surrounding spaces.
String? accountNameError(
  String name, {
  Iterable<String> otherNames = const [],
}) {
  final String text = name.trim();
  if (text.isEmpty) return 'Enter a name for this account.';
  if (text.length > accountNameMaxLength) {
    return 'Use $accountNameMaxLength characters or fewer.';
  }
  if (_controlChars.hasMatch(text)) return 'Remove special characters.';
  final String lower = text.toLowerCase();
  for (final String other in otherNames) {
    if (other.trim().toLowerCase() == lower) {
      return 'You already have an account with this name.';
    }
  }
  return null;
}
