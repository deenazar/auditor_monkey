import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../wow/shimmer.dart';

/// A static `tile` block that stands in for content while it loads.
///
/// A soft white shimmer sweeps across it (Motion & 3D layer; at most 10 s,
/// none with reduce motion). Screens fade the whole skeleton in.
/// Hidden from screen readers; the screen should announce loading itself.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    required this.height,
    this.width,
    this.borderRadius = AppRadius.card,
    super.key,
  });

  /// Block height in logical pixels.
  final double height;

  /// Block width. Null fills the available width.
  final double? width;

  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Shimmer(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.tile,
            borderRadius: borderRadius,
          ),
        ),
      ),
    );
  }
}
