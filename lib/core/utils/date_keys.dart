/// First and last possible date text of a `YYYY-MM` month.
///
/// Dates are `YYYY-MM-DD` text, so plain text comparison orders them
/// correctly. `-31` is safe as an upper bound for any month.
({String start, String end}) monthRange(String month) =>
    (start: '$month-01', end: '$month-31');
