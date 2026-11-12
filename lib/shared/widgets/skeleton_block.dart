import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// A static `tile` block that stands in for content while it loads.
///
/// No shimmer: it does not move, so it never distracts and needs no reduce
/// motion path. Screens fade the whole skeleton in with an AnimatedOpacity.
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
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.tile,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
