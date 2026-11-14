import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/skeleton_block.dart';

/// Placeholder rows while a page or the first load is read. Static blocks
/// (no shimmer), hidden from screen readers.
class SkeletonRows extends StatelessWidget {
  const SkeletonRows({this.count = 3, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < count; i++) ...<Widget>[
            const SkeletonBlock(height: 60),
            const SizedBox(height: AppSpacing.space2),
          ],
        ],
      ),
    );
  }
}

/// Shown at the end of the list when the next page failed to load.
class LoadMoreRetry extends StatelessWidget {
  const LoadMoreRetry({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: const BoxDecoration(
        color: AppColors.tile,
        borderRadius: AppRadius.card,
        border: Border.fromBorderSide(BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'Could not load more entries.',
              style: AppTextStyles.body.copyWith(color: AppColors.inkMuted),
            ),
          ),
          PrimaryButton(
            label: 'Try again',
            onPressed: onRetry,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}
