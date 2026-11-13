import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Frosted glass (mini_checklist `.g` / `.chip`): blur 14 + saturate 1.4
/// over what is behind, a translucent [tint] and a 1px white inner border.
///
/// Inside a [BackdropGroup] the blur shares one backdrop with the other
/// glass on screen (one pass instead of one per button), which keeps the
/// moving sky at 60 fps.
class Glass extends StatelessWidget {
  const Glass({
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(17)),
    this.tint = AppColors.glass,
    this.edge = AppColors.glassEdge,
    this.padding,
    this.shadows,
    super.key,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Color tint;
  final Color edge;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? shadows;

  /// blur(14px) saturate(1.4), as one filter.
  static final ui.ImageFilter filter = ui.ImageFilter.compose(
    outer: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
    inner: const ColorFilter.matrix(_saturate14),
  );

  // Saturation matrix for s = 1.4 (Rec. 709 luma weights).
  static const List<double> _saturate14 = <double>[
    1.2851, -0.2861, -0.0290, 0, 0, //
    -0.0851, 1.0139, -0.0290, 0, 0, //
    -0.0851, -0.2861, 1.3710, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  @override
  Widget build(BuildContext context) {
    final Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: borderRadius,
        border: Border.all(color: edge),
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
    final Widget blurred = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropGroup.of(context) == null
          ? BackdropFilter(filter: filter, child: surface)
          : BackdropFilter.grouped(filter: filter, child: surface),
    );
    if (shadows == null) return blurred;
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
      child: blurred,
    );
  }
}

/// Springy press feedback (`:active{transform:scale(.9)}` with
/// cubic-bezier(.2,1.6,.4,1)). No scale with reduce motion.
class PressScale extends StatefulWidget {
  const PressScale({
    required this.child,
    required this.onTap,
    this.scale = 0.9,
    this.semanticLabel,
    this.selected,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? semanticLabel;
  final bool? selected;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final bool reduce = MediaQuery.disableAnimationsOf(context);
    final bool enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down && !reduce ? widget.scale : 1,
          duration: reduce ? Duration.zero : const Duration(milliseconds: 200),
          curve: const Cubic(0.2, 1.6, 0.4, 1),
          child: widget.child,
        ),
      ),
    );
  }
}
