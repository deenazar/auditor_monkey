import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/app_motion.dart';

/// Fades and slides [child] up once, on first build.
///
/// Items wait `index * durationStagger` (index capped at
/// `staggerMaxItems - 1`). One controller holds delay and motion, so no
/// timers are left pending. Reduce motion shows the child at once.
class StaggeredEntrance extends StatefulWidget {
  /// Creates an entrance for the item at [index].
  const StaggeredEntrance({
    required this.index,
    required this.child,
    super.key,
  });

  /// Position in the list or group (0 based).
  final int index;

  /// The content.
  final Widget child;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _curve;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduceMotion(context)) return;
    final delayMs =
        math.min(widget.index, AppMotion.staggerMaxItems - 1) *
        AppMotion.durationStagger.inMilliseconds;
    final moveMs = AppMotion.durationMedium.inMilliseconds;
    final c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: delayMs + moveMs),
    );
    _controller = c;
    _curve = CurvedAnimation(
      parent: c,
      curve: Interval(
        delayMs / (delayMs + moveMs),
        1,
        curve: AppMotion.curveEnter,
      ),
    );
    c.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anim = _curve;
    if (anim == null) return widget.child;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: anim,
        child: widget.child,
        // Screen readers get the content at once, even while it fades in.
        builder: (context, child) => Opacity(
          opacity: anim.value,
          alwaysIncludeSemantics: true,
          child: Transform.translate(
            offset: Offset(0, (1 - anim.value) * AppMotion.cardEnterOffset),
            child: child,
          ),
        ),
      ),
    );
  }
}
