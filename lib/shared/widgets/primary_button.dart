import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// The main pill button (mini_checklist `.addbtn`): `coral` fill, white
/// Unbounded label, coral glow, `buttonHeight` tall.
///
/// - Pressed: springs to `pressScale` (no scale with reduce motion).
/// - Disabled (`onPressed` is null): `divider` fill, `inkMuted` label.
/// - Loading: a small ring replaces the label and taps are ignored. The
///   button keeps its colour so it does not look disabled.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    required this.label,
    this.onPressed,
    this.loading = false,
    this.fullWidth = true,
    super.key,
  });

  final String label;

  /// Called on tap. Null disables the button.
  final VoidCallback? onPressed;

  /// Shows a ring instead of the label. Taps are ignored while loading.
  final bool loading;

  /// Fills the available width. When false, the button is only as wide as
  /// its label.
  final bool fullWidth;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  bool get _tappable => widget.onPressed != null && !widget.loading;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  void _handleTap() {
    if (_tappable) widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduce = AppMotion.reduceMotion(context);
    final bool disabled = widget.onPressed == null;
    final bool pressed = _pressed && _tappable;

    final Color fill = disabled ? AppColors.divider : AppColors.primary;
    final Color labelColour = disabled ? AppColors.inkMuted : AppColors.onDark;

    final Widget content = widget.loading
        ? const SizedBox(
            width: AppSizes.progressRing,
            height: AppSizes.progressRing,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.progressStroke,
              color: AppColors.onDark,
              semanticsLabel: 'Loading',
            ),
          )
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.label,
              maxLines: 1,
              style: AppTextStyles.button.copyWith(
                fontSize: 14,
                color: labelColour,
              ),
            ),
          );

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.label,
      value: widget.loading ? 'Loading' : null,
      onTap: _tappable ? _handleTap : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _tappable ? (_) => _setPressed(true) : null,
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _handleTap,
        child: AnimatedScale(
          scale: pressed && !reduce ? AppSizes.pressScale : 1,
          duration: AppMotion.resolve(context, AppMotion.durationPress),
          curve: AppMotion.springy,
          child: AnimatedContainer(
            duration: AppMotion.resolve(context, AppMotion.durationFast),
            curve: AppMotion.curveEnter,
            height: AppSizes.buttonHeight,
            width: widget.fullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: AppRadius.pill,
              boxShadow: disabled
                  ? AppShadows.elevationNone
                  : AppShadows.shadowCoral,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
