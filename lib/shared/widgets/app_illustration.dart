import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../wow/depth_pop_in.dart';

/// Size class of an [AppIllustration] (DESIGN.md "Illustrations").
enum AppIllustrationSize {
  /// Empty and error states: 160pt tall, 120pt on short screens or with
  /// large text.
  empty,

  /// Setup wizard steps: 200pt tall, 160pt on short screens or with large
  /// text.
  wizard,
}

/// A flat original illustration from `assets/illustrations/<name>.svg`.
///
/// Decorative, so it is hidden from screen readers. The text next to it
/// says what the state means. It pops in with a small 3D tilt
/// ([DepthPopIn], Motion & 3D layer).
class AppIllustration extends StatelessWidget {
  const AppIllustration(
    this.name, {
    this.size = AppIllustrationSize.empty,
    super.key,
  });

  /// File name without the `.svg` extension, for example `empty_accounts`.
  final String name;

  final AppIllustrationSize size;

  /// The SVG viewBox is 240 x 200.
  static const double aspectRatio = 240 / 200;

  /// Screens shorter than this use the smaller size.
  static const double shortScreenHeight = 700;

  /// Text scale from which the smaller size is used.
  static const double largeTextScale = 1.5;

  /// Height in pt for [size] on a screen of [screenHeight] with a text
  /// scale of [textScale].
  static double heightFor({
    required AppIllustrationSize size,
    required double screenHeight,
    required double textScale,
  }) {
    final bool compact =
        screenHeight < shortScreenHeight || textScale >= largeTextScale;
    return switch (size) {
      AppIllustrationSize.empty => compact ? 120 : 160,
      AppIllustrationSize.wizard => compact ? 160 : 200,
    };
  }

  /// Asset path for [name].
  static String assetPath(String name) => 'assets/illustrations/$name.svg';

  @override
  Widget build(BuildContext context) {
    final double height = heightFor(
      size: size,
      screenHeight: MediaQuery.sizeOf(context).height,
      textScale: MediaQuery.textScalerOf(context).scale(1),
    );
    return ExcludeSemantics(
      child: DepthPopIn(
        child: SvgPicture.asset(
          assetPath(name),
          width: height * aspectRatio,
          height: height,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
