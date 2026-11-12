/// Removes personal data and amounts from log text.
///
/// Last line of defence: callers should not pass such data in the first
/// place. Masks rupee amounts, emails, long alphanumeric tokens (JWT-like,
/// 24+ chars) and long digit runs (phone, card).
///
/// Tags passed to `AppLogger` must be constant strings; they are not
/// cleaned. Never build a tag from user data.
abstract final class LogRedactor {
  static final RegExp _rupee = RegExp(r'(₹|Rs\.?|INR)\s*-?[\d,]+(\.\d+)?');
  static final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+');
  static final RegExp _token = RegExp(r'[A-Za-z0-9_\-.+/=]{24,}');
  static final RegExp _longDigits = RegExp(r'\d[\d\s-]{6,}\d');

  static String clean(String input) => input
      .replaceAll(_email, '[email]')
      .replaceAll(_rupee, '[amount]')
      .replaceAll(_token, '[token]')
      .replaceAll(_longDigits, '[number]');
}
