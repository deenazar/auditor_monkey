import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_shadows.dart';
import '../theme/app_sizes.dart';

/// The centre Quick Add button: 56pt primary circle, ink plus icon,
/// `shadowFloat`. Shrinks slightly while pressed.
class QuickAddButton extends StatefulWidget {
  const QuickAddButton({required this.onPressed, super.key});

  static const double size = AppSizes.quickAddSize;

  final VoidCallback onPressed;

  @override
  State<QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends State<QuickAddButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool reduce = AppMotion.reduceMotion(context);
    return Semantics(
      label: 'Quick Add',
      button: true,
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed && !reduce ? AppSizes.pressScale : 1,
          duration: AppMotion.resolve(context, AppMotion.durationFast),
          curve: AppMotion.curveEnter,
          child: Container(
            width: QuickAddButton.size,
            height: QuickAddButton.size,
            decoration: BoxDecoration(
              color: _pressed ? AppColors.primaryDeep : AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: AppShadows.shadowFloat,
            ),
            child: Icon(
              LucideIcons.plus,
              size: AppSizes.iconNav,
              color: _pressed ? AppColors.onDark : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
