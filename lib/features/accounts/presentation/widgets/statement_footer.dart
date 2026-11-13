import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';

/// The end of a statement list while older lines load: a small ring while
/// the next page loads, a "Try again" line when it failed, nothing otherwise.
class StatementFooter extends StatelessWidget {
  const StatementFooter({
    required this.loading,
    required this.failed,
    required this.onRetry,
    super.key,
  });

  final bool loading;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.space4),
        child: Center(
          child: SizedBox(
            width: AppSizes.progressRing,
            height: AppSizes.progressRing,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.progressStroke,
              color: AppColors.primaryDeep,
              semanticsLabel: 'Loading more',
            ),
          ),
        ),
      );
    }
    if (failed) {
      return Semantics(
        button: true,
        label: "Couldn't load more. Try again",
        onTap: onRetry,
        excludeSemantics: true,
        child: InkWell(
          onTap: onRetry,
          child: SizedBox(
            height: AppSpacing.minTapTarget,
            child: Center(
              child: Text(
                "Couldn't load more. Try again",
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.accentText,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
