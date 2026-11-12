import 'package:flutter/widgets.dart';

import '../../core/money/money.dart';
import '../theme/app_motion.dart';

/// Counts an amount up or down when it changes ("the number rolls").
///
/// The value being animated is an `int` number of paise (no doubles for
/// money): the steps in between are whole paise and the last frame is
/// exactly [paise]. The first build shows [paise] at once (no roll from 0).
/// With reduce motion the new value shows immediately.
///
/// [builder] draws the current value, e.g.
/// `builder: (context, p) => AmountText(paise: p, ...)`. Screen readers get
/// one label with the final amount, never the numbers in between.
class RollingAmount extends StatelessWidget {
  const RollingAmount({
    required this.paise,
    required this.builder,
    this.duration = AppMotion.durationSlow,
    super.key,
  });

  /// Plain text version: formatted as `₹1,23,456.00` in [style].
  RollingAmount.text({
    required int paise,
    required TextStyle style,
    Duration duration = AppMotion.durationSlow,
    TextAlign? textAlign,
    Key? key,
  }) : this(
         paise: paise,
         duration: duration,
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

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: formatPaise(paise),
      excludeSemantics: true,
      child: TweenAnimationBuilder<int>(
        tween: _PaiseTween(end: paise),
        duration: AppMotion.resolve(context, duration),
        curve: AppMotion.curveEnter,
        builder: (BuildContext context, int value, Widget? _) =>
            builder(context, value),
      ),
    );
  }
}

/// Integer tween: whole paise in between, the exact ends at 0 and 1.
class _PaiseTween extends Tween<int> {
  _PaiseTween({super.end});

  @override
  int lerp(double t) {
    final int from = begin ?? end!;
    final int to = end!;
    if (t <= 0) return from;
    if (t >= 1) return to;
    return from + ((to - from) * t).round();
  }
}
