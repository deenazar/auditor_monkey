import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_depth.dart';
import '../theme/app_motion.dart';
import 'haptics.dart';

/// Perspective tilt under the finger: the card leans towards where it is
/// touched (up to [AppDepth.tiltMax]), presses in a little, shows a soft
/// sheen, and springs back on release. Transform only, so it never
/// re-lays out. With reduce motion it does nothing.
///
/// Taps and long presses still reach [child]; this only listens.
class Tilt3D extends StatefulWidget {
  const Tilt3D({
    required this.child,
    this.maxDegrees = AppDepth.tiltMax,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.sheen = true,
    this.haptic = true,
    super.key,
  });

  final Widget child;
  final double maxDegrees;
  final BorderRadius borderRadius;

  /// Draws a moving highlight while tilted.
  final bool sheen;

  /// Light haptic on touch down.
  final bool haptic;

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppDepth.tiltSettle,
  );
  Offset _target = Offset.zero; // -1..1 in both axes
  Offset _from = Offset.zero;
  bool _down = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Offset get _current {
    final double t = (_down ? Curves.easeOut : AppDepth.springy).transform(
      _c.value,
    );
    return Offset.lerp(_from, _target, t)!;
  }

  void _aim(Offset local, Size size, {required bool down}) {
    _from = _current;
    _target = down
        ? Offset(
            (local.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
            (local.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
          )
        : Offset.zero;
    _down = down;
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) return widget.child;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final Size size = Size(
          box.hasBoundedWidth ? box.maxWidth : 300,
          box.hasBoundedHeight ? box.maxHeight : 200,
        );
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (PointerDownEvent e) {
            if (widget.haptic) AppHaptics.press();
            _aim(e.localPosition, context.size ?? size, down: true);
          },
          onPointerMove: (PointerMoveEvent e) {
            if (_down) _aim(e.localPosition, context.size ?? size, down: true);
          },
          onPointerUp: (_) => _aim(Offset.zero, size, down: false),
          onPointerCancel: (_) => _aim(Offset.zero, size, down: false),
          child: AnimatedBuilder(
            animation: _c,
            child: widget.child,
            builder: (BuildContext context, Widget? child) {
              final Offset p = _current;
              final double rad = widget.maxDegrees * math.pi / 180;
              final double press =
                  1 - (1 - AppDepth.pressScale) * p.distance.clamp(0, 1);
              final Matrix4 m = Matrix4.identity()
                ..setEntry(3, 2, AppDepth.perspective)
                ..rotateX(-p.dy * rad)
                ..rotateY(p.dx * rad)
                ..scaleByDouble(press, press, 1, 1);
              Widget out = Transform(
                alignment: Alignment.center,
                transform: m,
                child: child,
              );
              if (widget.sheen && p != Offset.zero) {
                out = Stack(
                  children: <Widget>[
                    out,
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Transform(
                          alignment: Alignment.center,
                          transform: m,
                          child: ClipRRect(
                            borderRadius: widget.borderRadius,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment(p.dx, p.dy),
                                  radius: 1.1,
                                  colors: <Color>[
                                    AppColors.sheen.withValues(
                                      alpha: 0.35 * p.distance.clamp(0, 1),
                                    ),
                                    const Color(0x00FFFFFF),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return out;
            },
          ),
        );
      },
    );
  }
}
