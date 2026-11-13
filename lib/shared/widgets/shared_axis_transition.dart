import 'package:flutter/widgets.dart';

import '../theme/app_motion.dart';

/// Shared-axis horizontal push: fade + slide in from the right by
/// `pageSlideOffset` (`curveEnter` in, `curveExit` out). With reduce motion
/// it only fades. Only opacity and transform animate.
class SharedAxisTransition extends StatefulWidget {
  const SharedAxisTransition({
    required this.animation,
    required this.child,
    super.key,
  });

  final Animation<double> animation;
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
    return RepaintBoundary(
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
                      child: inner,
                    ),
              ),
      ),
    );
  }
}
