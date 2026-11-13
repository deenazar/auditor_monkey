import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_shadows.dart';
import '../theme/app_sizes.dart';

/// The centre Quick Add button: 56pt coral circle, white plus icon, coral
/// glow. Springs smaller while pressed (mini_checklist `.addbtn`).
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
          duration: AppMotion.resolve(context, AppMotion.durationPress),
          curve: AppMotion.springy,
          child: Container(
            width: QuickAddButton.size,
            height: QuickAddButton.size,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: AppShadows.shadowCoral,
            ),
            child: const Icon(
              LucideIcons.plus,
              size: AppSizes.iconNav,
              color: AppColors.onDark,
            ),
          ),
        ),
      ),
    );
  }
}
