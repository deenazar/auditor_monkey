import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_illustration.dart';
import 'staggered_entrance.dart';

/// Centred empty state: an optional illustration (or icon), `title`, a
/// `body` message and an optional action (for example a button to add the
/// first item). The illustration replaces the icon when both are set.
///
/// Scrolls when large text does not fit, so nothing is cut off.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    this.icon,
    this.illustration,
    this.iconColour = AppColors.inkMuted,
    this.action,
    this.mascot,
    super.key,
  });

  final String title;
  final String message;

  /// Lucide icon shown above the title. Optional.
  final IconData? icon;

  /// Name of an `assets/illustrations` file (see [AppIllustration]). Used
  /// instead of [icon] when set.
  final String? illustration;

  /// Colour of [icon]. `inkMuted` for empty, `danger` for errors.
  final Color iconColour;

  /// Optional button or link under the message.
  final Widget? action;

  /// An animated mascot moment shown instead of the illustration
  /// (Motion & 3D layer), e.g. a worried monkey for errors.
  final Widget? mascot;

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
                    if (mascot != null) ...<Widget>[
                      mascot!,
                      const SizedBox(height: AppSpacing.space3),
                    ] else if (illustration != null) ...<Widget>[
                      AppIllustration(illustration!),
                      const SizedBox(height: AppSpacing.space3),
                    ] else if (iconData != null) ...<Widget>[
                      Icon(
                        iconData,
                        size: AppSizes.iconLarge,
                        color: iconColour,
                      ),
                      const SizedBox(height: AppSpacing.space3),
                    ],
                    // Title, message and action enter one after another.
                    StaggeredEntrance(
                      index: 1,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.title,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    StaggeredEntrance(
                      index: 2,
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ),
                    if (action != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.space5),
                      StaggeredEntrance(index: 3, child: action!),
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
