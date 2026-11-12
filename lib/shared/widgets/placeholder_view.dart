import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Centred page header (eyebrow + title) with a short empty state.
/// Used by the Session 1 placeholder screens.
class PlaceholderView extends StatelessWidget {
  const PlaceholderView({
    required this.eyebrow,
    required this.title,
    required this.message,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.space6,
        ),
        child: Column(
          children: <Widget>[
            Semantics(
              header: true,
              container: true,
              child: Column(
                children: <Widget>[
                  Text(
                    eyebrow,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.pageEyebrow,
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displayTitle,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space10),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
