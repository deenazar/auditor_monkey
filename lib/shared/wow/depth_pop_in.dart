import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/app_depth.dart';
import '../theme/app_motion.dart';

/// One-shot 3D entrance: tips forward from [degrees] around the X axis and
/// grows from 0.9 with a soft bounce. Used for illustrations in empty,
/// error, success and wizard states. Shown at once with reduce motion.
class DepthPopIn extends StatelessWidget {
  const DepthPopIn({required this.child, this.degrees = 22, super.key});

  final Widget child;
  final double degrees;

  static const Duration duration = Duration(milliseconds: 650);

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: AppDepth.bouncy,
      child: child,
      builder: (BuildContext context, double v, Widget? c) {
        final double s = 0.9 + 0.1 * v;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, AppDepth.perspective)
              ..rotateX((1 - v) * degrees * math.pi / 180)
              ..scaleByDouble(s, s, 1, 1),
            child: c,
          ),
        );
      },
    );
  }
}
