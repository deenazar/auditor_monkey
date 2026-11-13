/// Removes personal data and amounts from log text.
///
/// Last line of defence: callers should not pass such data in the first
/// place. Masks rupee amounts, emails, long alphanumeric tokens (JWT-like,
/// 24+ chars) and long digit runs (phone, card).
///
/// Short row ids written as `id=` plus exactly 8 hex characters (see
/// `shortId`) are kept as they are, even when all 8 are digits, so logs
/// stay traceable. A longer digit run after `id=` is still masked.
///
/// Tags passed to `AppLogger` must be constant strings; they are not
/// cleaned. Never build a tag from user data.
abstract final class LogRedactor {
  static final RegExp _rupee = RegExp(r'(₹|Rs\.?|INR)\s*-?[\d,]+(\.\d+)?');
  static final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+');
  static final RegExp _token = RegExp(r'[A-Za-z0-9_\-.+/=]{24,}');
  // Left branch: our short id marker, kept. Right branch: phone / card.
  // Matched in one pass, so a digit run can never start inside a marker.
  static final RegExp _longDigits = RegExp(
    r'id=[0-9a-f]{8}(?![0-9A-Za-z])|\d[\d\s-]{6,}\d',
  );

  static String clean(String input) => input
      .replaceAll(_email, '[email]')
      .replaceAll(_rupee, '[amount]')
      .replaceAll(_token, '[token]')
      .replaceAllMapped(
        _longDigits,
        (Match m) => m[0]!.startsWith('id=') ? m[0]! : '[number]',
      );
}
