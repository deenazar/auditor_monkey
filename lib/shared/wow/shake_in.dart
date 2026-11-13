import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/app_motion.dart';
import 'haptics.dart';

/// One-shot "no" shake for errors: [child] shakes sideways a few times as
/// it appears, with a `warning` haptic. Reduce motion: no shake (the
/// haptic still plays).
class ShakeIn extends StatefulWidget {
  const ShakeIn({required this.child, super.key});

  final Widget child;

  static const Duration duration = Duration(milliseconds: 450);

  @override
  State<ShakeIn> createState() => _ShakeInState();
}

class _ShakeInState extends State<ShakeIn> {
  @override
  void initState() {
    super.initState();
    AppHaptics.warning();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) return widget.child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: ShakeIn.duration,
      child: widget.child,
      builder: (BuildContext context, double v, Widget? child) =>
          Transform.translate(
            offset: Offset(math.sin(v * math.pi * 6) * (1 - v) * 8, 0),
            child: child,
          ),
    );
  }
}
