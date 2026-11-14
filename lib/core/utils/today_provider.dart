import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clock.dart';
import 'date_keys.dart';

/// Today's local calendar date as `YYYY-MM-DD`, from [clockProvider].
///
/// Read again every time the app comes back to the foreground, so a screen
/// left open overnight (or past the 1st of the month) rolls over to the new
/// day. Listeners are only told when the date text really changed.
final Provider<String> todayProvider = Provider<String>((Ref ref) {
  final _ResumeObserver observer = _ResumeObserver(ref.invalidateSelf);
  try {
    WidgetsBinding.instance.addObserver(observer);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));
  } on Object {
    // No widgets binding (plain unit test): nothing to observe.
  }
  final int ms = ref.watch(clockProvider).nowMs();
  return dateKey(DateTime.fromMillisecondsSinceEpoch(ms));
});

/// Calls [_onResume] when the app returns to the foreground.
class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver(this._onResume);

  final void Function() _onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onResume();
  }
}

/// The current local month as `YYYY-MM`.
final Provider<String> currentMonthProvider = Provider<String>(
  (Ref ref) => ref.watch(todayProvider).substring(0, 7),
);
