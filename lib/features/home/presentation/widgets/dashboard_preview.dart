import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_shadows.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';

/// The card shown by a long-press preview on the Dashboard (see
/// `LongPressPreview.show`). One short line, centred.
class DashboardPreviewCard extends StatelessWidget {
  const DashboardPreviewCard({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.space6),
        padding: const EdgeInsets.all(AppSpacing.space5),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadius.card,
          boxShadow: AppShadows.shadowFloat,
        ),
        child: Text(
          text,
          style: AppTextStyles.bodyStrong,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
