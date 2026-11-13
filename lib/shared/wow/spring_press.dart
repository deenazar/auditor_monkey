import 'package:flutter/material.dart';

import '../theme/app_depth.dart';
import '../theme/app_motion.dart';
import 'haptics.dart';

/// Springy press with a haptic: scales to [scale] on touch and springs
/// back with cubic-bezier(.2,1.6,.4,1). No scale with reduce motion (the
/// haptic still plays).
class SpringPress extends StatefulWidget {
  const SpringPress({
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.scale = 0.92,
    this.semanticLabel,
    this.selected,
    this.haptic = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final String? semanticLabel;
  final bool? selected;
  final bool haptic;

  @override
  State<SpringPress> createState() => _SpringPressState();
}

class _SpringPressState extends State<SpringPress> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final bool reduce = AppMotion.reduceMotion(context);
    final bool enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled
            ? (_) {
                if (widget.haptic) AppHaptics.tap();
                _set(true);
              }
            : null,
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _down && !reduce ? widget.scale : 1,
          duration: reduce ? Duration.zero : AppDepth.press,
          curve: AppDepth.springy,
          child: widget.child,
        ),
      ),
    );
  }
}
