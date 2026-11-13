import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_depth.dart';
import '../theme/app_motion.dart';

/// A white sheen sweeping across loading placeholders. Runs at most
/// [AppDepth.shimmerMax] (then holds still, to save battery); none with
/// reduce motion.
class Shimmer extends StatefulWidget {
  const Shimmer({required this.child, super.key});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppDepth.shimmer,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      final int loops =
          AppDepth.shimmerMax.inMilliseconds ~/ AppDepth.shimmer.inMilliseconds;
      _c.repeat(count: loops);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        if (!_c.isAnimating) return child!;
        final double x = -1.5 + 3 * _c.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect r) => LinearGradient(
            begin: Alignment(x - 0.6, -0.3),
            end: Alignment(x + 0.6, 0.3),
            colors: const <Color>[
              Color(0x00FFFFFF),
              AppColors.sheen,
              Color(0x00FFFFFF),
            ],
          ).createShader(r),
          child: child,
        );
      },
    );
  }
}
