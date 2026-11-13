import 'package:flutter/widgets.dart';

import '../theme/app_motion.dart';

/// Shared-axis horizontal push: fade + slide in from the right by
/// `pageSlideOffset` (`curveEnter` in, `curveExit` out). With reduce motion
/// it only fades. Only opacity and transform animate.
class SharedAxisTransition extends StatelessWidget {
  const SharedAxisTransition({
    required this.animation,
    required this.child,
    super.key,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool reduce = AppMotion.reduceMotion(context);
    final CurvedAnimation curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.curveEnter,
      reverseCurve: AppMotion.curveExit,
    );
    return RepaintBoundary(
      child: FadeTransition(
        opacity: curved,
        child: reduce
            ? child
            : AnimatedBuilder(
                animation: curved,
                child: child,
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
