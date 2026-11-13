import 'package:flutter/material.dart';

import '../theme/app_depth.dart';
import '../theme/app_motion.dart';
import 'haptics.dart';

/// The sheet motion of the Motion & 3D layer: rises with a slight
/// overshoot ([AppDepth.sheet], [AppDepth.sheetOpen]) and leaves with
/// `curveExit`. With reduce motion it appears and leaves at once.
AnimationStyle wowSheetAnimation(BuildContext context) {
  final bool reduce = AppMotion.reduceMotion(context);
  return AnimationStyle(
    duration: reduce ? Duration.zero : AppDepth.sheetOpen,
    reverseDuration: reduce ? Duration.zero : AppMotion.durationMedium,
    curve: reduce ? Curves.linear : AppDepth.sheet,
    reverseCurve: AppMotion.curveExit,
  );
}

/// [showModalBottomSheet] with the layer's springy rise and a `press`
/// haptic as it opens. Use for every bottom sheet in the app.
Future<T?> showWowSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useSafeArea = true,
  bool showDragHandle = false,
  Color? backgroundColor,
  Color? barrierColor,
  ShapeBorder? shape,
  AnimationStyle? animationStyle,
}) {
  AppHaptics.press();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor,
    barrierColor: barrierColor,
    shape: shape,
    sheetAnimationStyle: animationStyle ?? wowSheetAnimation(context),
    builder: builder,
  );
}
