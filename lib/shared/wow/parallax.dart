import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_motion.dart';

/// Moves [child] by [factor] of the scroll [offset] (negative = up), for
/// depth: background layers move slower than the content in front. Pass
/// the scroll position as a [ValueListenable]. Off with reduce motion.
class Parallax extends StatelessWidget {
  const Parallax({
    required this.offset,
    required this.factor,
    required this.child,
    this.fadeOver,
    super.key,
  });

  final ValueListenable<double> offset;
  final double factor;
  final Widget child;

  /// When set, the layer also fades out over this much scroll.
  final double? fadeOver;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) return child;
    return ValueListenableBuilder<double>(
      valueListenable: offset,
      child: child,
      builder: (BuildContext context, double y, Widget? child) {
        Widget out = Transform.translate(
          offset: Offset(0, y * factor),
          child: child,
        );
        final double? fade = fadeOver;
        if (fade != null && y > 0) {
          out = Opacity(opacity: (1 - y / fade).clamp(0.0, 1.0), child: out);
        }
        return out;
      },
    );
  }
}

/// A [ValueNotifier] of a scroll position, fed by a [ScrollController].
class ScrollOffset extends ValueNotifier<double> {
  ScrollOffset() : super(0);

  /// Use as `NotificationListener<ScrollNotification>(onNotification: ...)`.
  bool onScroll(ScrollNotification n) {
    if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
      value = n.metrics.pixels;
    }
    return false;
  }
}
