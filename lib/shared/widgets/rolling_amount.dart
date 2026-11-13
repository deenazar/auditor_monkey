import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money/money.dart';
import '../theme/app_motion.dart';

/// Counts an amount up or down when it changes ("the number rolls").
///
/// The value being animated is an `int` number of paise (no doubles for
/// money): the steps in between are whole paise and the last frame is
/// exactly [paise]. The first build shows [paise] at once (no roll from 0).
/// With reduce motion the new value shows immediately.
///
/// With a [rollKey] the amount rolls from 0 the first time that key is shown
/// in this app launch (in-memory, see [rolledKeysProvider]); the next time
/// it shows at once, and later changes roll from the old value to the new.
///
/// [builder] draws the current value, e.g.
/// `builder: (context, p) => AmountText(paise: p, ...)`. Screen readers get
/// one label with the final amount, never the numbers in between.
class RollingAmount extends StatefulWidget {
  const RollingAmount({
    required this.paise,
    required this.builder,
    this.duration = AppMotion.durationSlow,
    this.rollKey,
    super.key,
  });

  /// Plain text version: formatted as `₹1,23,456.00` in [style].
  RollingAmount.text({
    required int paise,
    required TextStyle style,
    Duration duration = AppMotion.durationSlow,
    TextAlign? textAlign,
    String? rollKey,
    Key? key,
  }) : this(
         paise: paise,
         duration: duration,
         rollKey: rollKey,
         key: key,
         builder: (BuildContext context, int value) =>
             Text(formatPaise(value), style: style, textAlign: textAlign),
       );

  /// The amount to show, in paise. Negative is allowed (card debt).
  final int paise;

  /// Draws one frame of the roll.
  final Widget Function(BuildContext context, int paise) builder;

  /// Length of the roll (`durationSlow`).
  final Duration duration;

  /// Names this amount for the "first show per launch" rule; null = never
  /// rolls from 0.
  final String? rollKey;

  @override
  State<RollingAmount> createState() => _RollingAmountState();
}

class _RollingAmountState extends State<RollingAmount> {
  bool _fromZero = false;
  bool _decided = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    final String? key = widget.rollKey;
    if (key == null) return;
    final Set<String> seen;
    try {
      seen = ProviderScope.containerOf(
        context,
        listen: false,
      ).read(rolledKeysProvider);
    } on Object {
      // No ProviderScope (a plain widget test): behave as already seen.
      return;
    }
    _fromZero = seen.add(key);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: formatPaise(widget.paise),
      excludeSemantics: true,
      child: TweenAnimationBuilder<int>(
        tween: _PaiseTween(begin: _fromZero ? 0 : null, end: widget.paise),
        duration: AppMotion.resolve(context, widget.duration),
        curve: AppMotion.curveEnter,
        builder: (BuildContext context, int value, Widget? _) =>
            widget.builder(context, value),
      ),
    );
  }
}

/// Keys of amounts that already rolled from 0 in this app launch.
final Provider<Set<String>> rolledKeysProvider = Provider<Set<String>>(
  (Ref ref) => <String>{},
);

/// Integer tween: whole paise in between, the exact ends at 0 and 1.
class _PaiseTween extends Tween<int> {
  _PaiseTween({super.begin, super.end});

  @override
  int lerp(double t) {
    final int from = begin ?? end!;
    final int to = end!;
    if (t <= 0) return from;
    if (t >= 1) return to;
    return from + ((to - from) * t).round();
  }
}
