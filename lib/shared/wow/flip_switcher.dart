import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/app_depth.dart';
import '../theme/app_motion.dart';

/// Switches between children with a 3D page flip around the Y axis: the
/// old child turns away, the new one turns in from the side it comes from
/// ([forward] = from the right). Give each child a distinct key.
/// Reduce motion: a plain short fade.
class FlipSwitcher extends StatelessWidget {
  const FlipSwitcher({required this.child, this.forward = true, super.key});

  final Widget child;
  final bool forward;

  @override
  Widget build(BuildContext context) {
    final bool reduce = AppMotion.reduceMotion(context);
    return AnimatedSwitcher(
      duration: reduce ? AppMotion.durationFast : AppDepth.flip,
      switchInCurve: AppMotion.curveEnter,
      switchOutCurve: AppMotion.curveExit,
      layoutBuilder: (Widget? current, List<Widget> previous) => Stack(
        fit: StackFit.expand,
        children: <Widget>[...previous, ?current],
      ),
      transitionBuilder: (Widget c, Animation<double> a) {
        final bool entering = c.key == child.key;
        final Widget faded = FadeTransition(opacity: a, child: c);
        if (reduce) return entering ? faded : IgnorePointer(child: faded);
        final double dir = (forward ? 1 : -1) * (entering ? 1 : -1);
        final Widget turned = AnimatedBuilder(
          animation: a,
          child: faded,
          builder: (BuildContext context, Widget? w) {
            final double angle =
                (1 - a.value) * AppDepth.flipDegrees * math.pi / 180 * dir;
            return Transform(
              alignment: dir > 0 ? Alignment.centerLeft : Alignment.centerRight,
              transform: Matrix4.identity()
                ..setEntry(3, 2, AppDepth.perspective)
                ..rotateY(-angle),
              child: w,
            );
          },
        );
        return entering ? turned : IgnorePointer(child: turned);
      },
      child: child,
    );
  }
}
