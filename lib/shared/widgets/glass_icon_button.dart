import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'glass.dart';

/// mini_checklist `.g`: a 34pt glass pill with an icon and/or a label,
/// white ink, springy press. Use on the sky only.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    required this.semanticLabel,
    required this.onTap,
    this.icon,
    this.label,
    this.selected = false,
    super.key,
  });

  final IconData? icon;
  final String? label;
  final String semanticLabel;
  final VoidCallback? onTap;

  /// `.g.on`: white fill, ink content.
  final bool selected;

  static const double height = 34;

  @override
  Widget build(BuildContext context) {
    final Color ink = selected ? AppColors.ink : AppColors.glassInk;
    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) Icon(icon, size: 16, color: ink),
        if (icon != null && label != null) const SizedBox(width: 6),
        if (label != null)
          Text(
            label!,
            style: AppTextStyles.bodyStrong.copyWith(fontSize: 12, color: ink),
          ),
      ],
    );
    return Tooltip(
      message: semanticLabel,
      excludeFromSemantics: true,
      child: PressScale(
        onTap: onTap,
        semanticLabel: semanticLabel,
        selected: selected,
        child: ExcludeSemantics(
          child: Glass(
            tint: selected ? const Color(0xE6FFFFFF) : AppColors.glass,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: height,
                minHeight: height,
                maxHeight: height,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: label == null ? 9 : 12,
                ),
                child: Center(widthFactor: 1, child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
