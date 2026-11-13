import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_sizes.dart';
import 'press_surface.dart';

/// One key of the Quick Add number pad (DESIGN.md "Number pad key").
///
/// `tile` fill, `radiusField`, `numPadKeyHeight` tall. Pressed: `navIndicator`
/// fill and a `pressScale` press, with `durationFast`. A light haptic
/// (selection click) fires on every tap. [label] is what screen readers say.
class NumPadKey extends StatelessWidget {
  const NumPadKey({
    required this.label,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    super.key,
  });

  /// Spoken name, e.g. "1", "point", "delete".
  final String label;

  /// The key face: a digit in `headline` or an icon of 24 in `ink`.
  final Widget child;

  final VoidCallback? onTap;

  /// Long press (used by backspace to clear everything). Optional.
  final VoidCallback? onLongPress;

  final bool enabled;

  void _tapWithHaptic() {
    HapticFeedback.selectionClick();
    onTap?.call();
  }

  void _longPressWithHaptic() {
    HapticFeedback.selectionClick();
    onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bool active = enabled && onTap != null;
    return Semantics(
      button: true,
      enabled: active,
      label: label,
      excludeSemantics: true,
      onTap: active ? _tapWithHaptic : null,
      onLongPress: enabled && onLongPress != null ? _longPressWithHaptic : null,
      child: PressSurface(
        enabled: enabled,
        onTap: onTap == null ? null : _tapWithHaptic,
        onLongPress: onLongPress == null ? null : _longPressWithHaptic,
        builder: (BuildContext context, bool pressed) {
          return AnimatedContainer(
            duration: AppMotion.resolve(context, AppMotion.durationFast),
            curve: AppMotion.curveEnter,
            height: AppSizes.numPadKeyHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: pressed ? AppColors.navIndicator : AppColors.tile,
              borderRadius: AppRadius.field,
            ),
            child: child,
          );
        },
      ),
    );
  }
}
