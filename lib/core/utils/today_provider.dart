import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clock.dart';
import 'date_keys.dart';

/// Today's local calendar date as `YYYY-MM-DD`, from [clockProvider].
///
/// Read once when first used. A screen that stays open past midnight keeps
/// the old date until it is rebuilt (fine for a personal money app).
final Provider<String> todayProvider = Provider<String>((Ref ref) {
  final int ms = ref.watch(clockProvider).nowMs();
  return dateKey(DateTime.fromMillisecondsSinceEpoch(ms));
});

/// The current local month as `YYYY-MM`.
final Provider<String> currentMonthProvider = Provider<String>(
  (Ref ref) => ref.watch(todayProvider).substring(0, 7),
);
