import 'package:flutter/widgets.dart';

import '../theme/app_motion.dart';

/// Shows one child at a time (all kept alive) with a fade-through when
/// [index] changes: the old tab fades out (`durationFast`, `curveExit`),
/// then the new tab fades in and scales `tabFadeScaleFrom` to 1
/// (`durationMedium`, `curveEnter`). With reduce motion the swap is
/// instant. Only opacity and scale animate.
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({
    required this.index,
    required this.children,
    super.key,
  });

  final int index;
  final List<Widget> children;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  static final int _outMs = AppMotion.durationFast.inMilliseconds;
  static final int _inMs = AppMotion.durationMedium.inMilliseconds;
  static final double _split = _outMs / (_outMs + _inMs);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _outMs + _inMs),
    value: 1,
  );

  /// The tab on screen now (the old one while it fades out).
  late int _shown = widget.index;

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    if (AppMotion.reduceMotion(context)) {
      _controller.value = 1;
      _shown = widget.index;
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? _) {
          final double t = _controller.value;
          double opacity = 1;
          double scale = 1;
          if (t >= 1) {
            _shown = widget.index;
          } else if (t < _split) {
            opacity = 1 - AppMotion.curveExit.transform(t / _split);
          } else {
            _shown = widget.index;
            final double p = AppMotion.curveEnter.transform(
              (t - _split) / (1 - _split),
            );
            opacity = p;
            scale =
                AppMotion.tabFadeScaleFrom +
                (1 - AppMotion.tabFadeScaleFrom) * p;
          }
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: IndexedStack(
                index: _shown,
                sizing: StackFit.expand,
                children: <Widget>[
                  for (int i = 0; i < widget.children.length; i++)
                    TickerMode(enabled: i == _shown, child: widget.children[i]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
