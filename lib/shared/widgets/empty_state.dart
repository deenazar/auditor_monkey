import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Centred empty state: optional icon, `title`, a `body` message and an
/// optional action (for example a button to add the first item).
///
/// Scrolls when large text does not fit, so nothing is cut off.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    this.icon,
    this.iconColour = AppColors.inkMuted,
    this.action,
    super.key,
  });

  final String title;
  final String message;

  /// Lucide icon shown above the title. Optional.
  final IconData? icon;

  /// Colour of [icon]. `inkMuted` for empty, `danger` for errors.
  final Color iconColour;

  /// Optional button or link under the message.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final IconData? iconData = icon;
    return Semantics(
      container: true,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.space8,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - AppSpacing.space8 * 2,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (iconData != null) ...<Widget>[
                      Icon(
                        iconData,
                        size: AppSizes.iconLarge,
                        color: iconColour,
                      ),
                      const SizedBox(height: AppSpacing.space3),
                    ],
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.title,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    if (action != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.space5),
                      action!,
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
