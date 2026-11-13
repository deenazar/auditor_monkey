import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

/// White sheet surface with `radiusCard` top corners and the DESIGN.md
/// `shadowFloat` token. Material's own sheet shadow (`elevation`) is a raw
/// value and cannot take a token, so the surface draws the shadow itself.
class SheetSurface extends StatelessWidget {
  const SheetSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.sheet,
        boxShadow: AppShadows.shadowFloat,
      ),
      child: ClipRRect(borderRadius: AppRadius.sheet, child: child),
    );
  }
}

/// Opens a modal bottom sheet whose surface uses [SheetSurface]: the Material
/// sheet is transparent and has no elevation of its own, so the only shadow
/// is the `shadowFloat` token.
Future<T?> showTokenSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  AnimationStyle? sheetAnimationStyle,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    clipBehavior: Clip.none,
    sheetAnimationStyle: sheetAnimationStyle,
    builder: (BuildContext sheetContext) =>
        SheetSurface(child: builder(sheetContext)),
  );
}
