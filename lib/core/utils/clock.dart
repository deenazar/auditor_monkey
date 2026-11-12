import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source of "now". Tests replace it so time is predictable.
abstract interface class Clock {
  /// Current time as UTC epoch milliseconds.
  int nowMs();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  int nowMs() => DateTime.now().toUtc().millisecondsSinceEpoch;
}

final Provider<Clock> clockProvider = Provider<Clock>(
  (Ref ref) => const SystemClock(),
);
