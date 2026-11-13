import 'package:flutter/material.dart';

import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_sizes.dart';

/// Builds a tappable surface that reports its pressed state.
///
/// While pressed, the child builder gets `pressed: true` (used for fill and
/// scale). The surface is never smaller than [minSize] (44 tap target).
/// With reduce motion on, the press still changes colour but never scales.
/// Taps are ignored when [enabled] is false.
class PressSurface extends StatefulWidget {
  const PressSurface({
    required this.builder,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.pressScale = AppSizes.pressScale,
    super.key,
  });

  /// Draws the surface. [pressed] is true while the finger is down.
  final Widget Function(BuildContext context, bool pressed) builder;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;

  /// Scale while pressed (`pressScale` for keys and chips).
  final double pressScale;

  @override
  State<PressSurface> createState() => _PressSurfaceState();
}

class _PressSurfaceState extends State<PressSurface> {
  bool _pressed = false;

  bool get _active =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool reduce = AppMotion.reduceMotion(context);
    final bool pressed = _pressed && _active;
    final Widget surface = widget.builder(context, pressed);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _active ? (_) => _setPressed(true) : null,
      onTapUp: _active ? (_) => _setPressed(false) : null,
      onTapCancel: _active ? () => _setPressed(false) : null,
      onTap: _active ? widget.onTap : null,
      onLongPress: _active ? widget.onLongPress : null,
      child: AnimatedScale(
        scale: pressed && !reduce ? widget.pressScale : 1,
        duration: AppMotion.resolve(context, AppMotion.durationFast),
        curve: AppMotion.curveEnter,
        child: surface,
      ),
    );
  }
}
