import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/app_depth.dart';
import '../theme/app_motion.dart';

/// Turns [child] in 3D (around the X axis, like a flip-board) each time
/// [turnKey] changes. One child, no duplicate while turning. Off with
/// reduce motion.
class DepthTurn extends StatefulWidget {
  const DepthTurn({
    required this.turnKey,
    required this.child,
    this.degrees = 70,
    super.key,
  });

  final Object turnKey;
  final Widget child;
  final double degrees;

  @override
  State<DepthTurn> createState() => _DepthTurnState();
}

class _DepthTurnState extends State<DepthTurn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppDepth.flip,
    value: 1,
  );

  @override
  void didUpdateWidget(DepthTurn old) {
    super.didUpdateWidget(old);
    if (old.turnKey != widget.turnKey && !AppMotion.reduceMotion(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        if (_c.value >= 1) return child!;
        final double v = AppDepth.bouncy.transform(_c.value);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, AppDepth.perspective)
            ..rotateX((1 - v) * widget.degrees * math.pi / 180),
          child: child,
        );
      },
    );
  }
}
