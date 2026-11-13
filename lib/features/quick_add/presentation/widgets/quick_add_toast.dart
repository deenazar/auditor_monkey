import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_shadows.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import 'press_surface.dart';
import 'success_check.dart';

/// The saved toast (DESIGN.md "Toast"): `primaryDeep` fill, `onDark` text,
/// `radiusCard`, `shadowFloat`. The optional [onUndo] is a `bodyStrong`
/// `onDark` action with a 44 tap target.
class QuickAddToastContent extends StatelessWidget {
  const QuickAddToastContent({
    required this.message,
    this.onUndo,
    this.showCheck = false,
    super.key,
  });

  final String message;

  /// Shows an "Undo" action when set.
  final VoidCallback? onUndo;

  /// Shows the animated check mark before the text (saved toast).
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? undo = onUndo;
    return Semantics(
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.primaryDeep,
          borderRadius: AppRadius.card,
          boxShadow: AppShadows.shadowFloat,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.space4,
            end: AppSpacing.space2,
            top: AppSpacing.space2,
            bottom: AppSpacing.space2,
          ),
          child: Row(
            children: <Widget>[
              if (showCheck) ...<Widget>[
                const SuccessCheck(color: AppColors.onDark),
                const SizedBox(width: AppSpacing.space2),
              ],
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(color: AppColors.onDark),
                ),
              ),
              if (undo != null) ...<Widget>[
                const SizedBox(width: AppSpacing.space2),
                _UndoButton(onTap: undo),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UndoButton extends StatelessWidget {
  const _UndoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Undo',
      excludeSemantics: true,
      onTap: onTap,
      child: PressSurface(
        onTap: onTap,
        builder: (BuildContext context, bool pressed) {
          // Fixed 44 height; the width shrinks to the label. (A plain Center
          // would stretch to the full row height inside the toast.)
          return SizedBox(
            height: AppSizes.chipHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
              ),
              child: Center(
                widthFactor: 1,
                child: Text(
                  'Undo',
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.onDark,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A [SnackBar] that shows [QuickAddToastContent] for `toastDuration`.
///
/// The host must be a Scaffold with the bottom nav bar, so a floating
/// SnackBar sits above the bar. Its slide and fade come from the SnackBar
/// theme (`SnackBarThemeData` in `app_theme.dart`).
SnackBar buildQuickAddToast({
  required String message,
  VoidCallback? onUndo,
  bool showCheck = false,
}) {
  return SnackBar(
    content: QuickAddToastContent(
      message: message,
      onUndo: onUndo,
      showCheck: showCheck,
    ),
    duration: AppMotion.toastDuration,
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    elevation: 0,
    padding: EdgeInsets.zero,
    margin: const EdgeInsets.all(AppSpacing.space6),
  );
}
