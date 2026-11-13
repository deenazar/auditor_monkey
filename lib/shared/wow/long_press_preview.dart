import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_depth.dart';
import '../theme/app_motion.dart';
import '../theme/app_shadows.dart';
import 'haptics.dart';

/// Long-press "peek": holding [child] blurs the screen behind and springs
/// a larger preview ([preview]) into the centre. Lifting the finger (or a
/// tap on the backdrop) closes it. Taps on [child] still work.
class LongPressPreview extends StatelessWidget {
  const LongPressPreview({
    required this.child,
    required this.preview,
    this.semanticHint = 'Long press to preview',
    super.key,
  });

  final Widget child;
  final WidgetBuilder preview;
  final String semanticHint;

  static Future<void> show(BuildContext context, WidgetBuilder preview) {
    AppHaptics.success();
    final bool reduce = AppMotion.reduceMotion(context);
    return Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierLabel: 'Close preview',
        barrierColor: const Color(0x00000000),
        transitionDuration: reduce ? AppMotion.durationFast : AppDepth.preview,
        reverseTransitionDuration: AppMotion.durationFast,
        pageBuilder: (BuildContext ctx, Animation<double> a, _) =>
            _PreviewPage(animation: a, reduce: reduce, builder: preview),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      onLongPressHint: semanticHint,
      child: GestureDetector(
        onLongPress: () => show(context, preview),
        child: child,
      ),
    );
  }
}

class _PreviewPage extends StatelessWidget {
  const _PreviewPage({
    required this.animation,
    required this.reduce,
    required this.builder,
  });

  final Animation<double> animation;
  final bool reduce;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double v = animation.value;
        final double s = reduce
            ? 1
            : AppDepth.previewFrom +
                  (1 - AppDepth.previewFrom) *
                      AppDepth.bouncy.transform(v.clamp(0, 1));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).maybePop(),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10 * v, sigmaY: 10 * v),
            child: ColoredBox(
              color: AppColors.previewScrim.withValues(
                alpha: AppColors.previewScrim.a * v,
              ),
              child: SafeArea(
                child: Center(
                  child: Opacity(
                    opacity: v.clamp(0, 1),
                    child: Transform.scale(scale: s, child: child),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            boxShadow: AppShadows.shadowLifted,
          ),
          child: Material(
            color: AppColors.background,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: builder(context),
          ),
        ),
      ),
    );
  }
}
