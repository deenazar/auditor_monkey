import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../shared/theme/app_depth.dart';

import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_spacing.dart';

/// Animates between wizard steps: the new step turns in 3D (around its
/// centre, up to `stepTurnDegrees`) and slides in 24pt from the
/// side it comes from while it fades in (`durationMedium`, `curveEnter`);
/// the old step fades out and slides the other way (`curveExit`). Going
/// forward comes from the right, going back from the left.
///
/// With reduce motion there is no movement, only a short fade
/// (`durationFast`). The old step ignores taps while it leaves.
///
/// Give it the current [step] index and the [child] for that step; change
/// both together. Steps are told apart by [step], not by the child type.
class WizardStepTransition extends StatefulWidget {
  const WizardStepTransition({
    required this.step,
    required this.child,
    super.key,
  });

  final int step;
  final Widget child;

  @override
  State<WizardStepTransition> createState() => _WizardStepTransitionState();
}

class _WizardStepTransitionState extends State<WizardStepTransition> {
  bool _forward = true;

  @override
  void didUpdateWidget(WizardStepTransition old) {
    super.didUpdateWidget(old);
    if (old.step != widget.step) _forward = widget.step > old.step;
  }

  @override
  Widget build(BuildContext context) {
    final bool reduce = AppMotion.reduceMotion(context);
    final Duration duration = reduce
        ? AppMotion.durationFast
        : AppMotion.durationMedium;
    final double direction = _forward ? 1 : -1;
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: duration,
      switchInCurve: AppMotion.curveEnter,
      switchOutCurve: AppMotion.curveExit,
      layoutBuilder: (Widget? current, List<Widget> previous) => Stack(
        fit: StackFit.expand,
        children: <Widget>[...previous, ?current],
      ),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final bool entering = child.key == ValueKey<int>(widget.step);
        final Widget faded = FadeTransition(opacity: animation, child: child);
        if (reduce) {
          return entering ? faded : IgnorePointer(child: faded);
        }
        // animation runs 0 -> 1 when entering and 1 -> 0 when leaving.
        return AnimatedBuilder(
          animation: animation,
          child: faded,
          builder: (BuildContext context, Widget? inner) {
            final double travel = AppSpacing.space6 * (1 - animation.value);
            final double dx = entering
                ? direction * travel
                : -direction * travel;
            final double turn =
                (1 - animation.value) *
                AppDepth.stepTurnDegrees *
                math.pi /
                180 *
                (entering ? direction : -direction);
            final Widget moved = Transform.translate(
              offset: Offset(dx, 0),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, AppDepth.perspective)
                  ..rotateY(-turn),
                child: inner,
              ),
            );
            return entering ? moved : IgnorePointer(child: moved);
          },
        );
      },
      child: KeyedSubtree(key: ValueKey<int>(widget.step), child: widget.child),
    );
  }
}
