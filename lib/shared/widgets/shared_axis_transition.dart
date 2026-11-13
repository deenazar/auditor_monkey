import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/app_depth.dart';
import '../theme/app_motion.dart';

/// Shared-axis horizontal push with depth: fade + slide in from the right
/// by `pageSlideOffset` while the page swings in on the Y axis (around its
/// centre, `pageTurnDegrees`); the page underneath ([secondaryAnimation])
/// recedes to `pageRecedeScale` and tilts away. `curveEnter` in,
/// `curveExit` out. With reduce motion it only fades. Only opacity and
/// transform animate.
class SharedAxisTransition extends StatefulWidget {
  const SharedAxisTransition({
    required this.animation,
    required this.child,
    this.secondaryAnimation,
    super.key,
  });

  final Animation<double> animation;

  /// The page being covered by a newer page (it recedes).
  final Animation<double>? secondaryAnimation;
  final Widget child;

  @override
  State<SharedAxisTransition> createState() => _SharedAxisTransitionState();
}

class _SharedAxisTransitionState extends State<SharedAxisTransition> {
  // Kept in state (not made per build) so its listener is removed once.
  late CurvedAnimation _curved = _curve(widget.animation);

  static CurvedAnimation _curve(Animation<double> parent) => CurvedAnimation(
    parent: parent,
    curve: AppMotion.curveEnter,
    reverseCurve: AppMotion.curveExit,
  );

  @override
  void didUpdateWidget(SharedAxisTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _curved.dispose();
      _curved = _curve(widget.animation);
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduce = AppMotion.reduceMotion(context);
    final CurvedAnimation curved = _curved;
    final Widget page = RepaintBoundary(
      child: FadeTransition(
        opacity: curved,
        child: reduce
            ? widget.child
            : AnimatedBuilder(
                animation: curved,
                child: widget.child,
                builder: (BuildContext context, Widget? inner) =>
                    Transform.translate(
                      offset: Offset(
                        AppMotion.pageSlideOffset * (1 - curved.value),
                        0,
                      ),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, AppDepth.perspective)
                          ..rotateY(
                            -(1 - curved.value) *
                                AppDepth.pageTurnDegrees *
                                math.pi /
                                180,
                          ),
                        child: inner,
                      ),
                    ),
              ),
      ),
    );
    final Animation<double>? under = widget.secondaryAnimation;
    if (reduce || under == null) return page;
    return AnimatedBuilder(
      animation: under,
      child: page,
      builder: (BuildContext context, Widget? inner) {
        final double v = AppMotion.curveEnter.transform(under.value);
        if (v == 0) return inner!;
        final double s = 1 - (1 - AppDepth.pageRecedeScale) * v;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, AppDepth.perspective)
            ..rotateY(v * 6 * math.pi / 180)
            ..scaleByDouble(s, s, 1, 1),
          child: inner,
        );
      },
    );
  }
}
