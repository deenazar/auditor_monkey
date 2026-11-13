import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_illustration.dart';
import 'page_header.dart';

/// Header (eyebrow + title) with an optional illustration and a short
/// centred message. Used by the placeholder screens.
class PlaceholderView extends StatelessWidget {
  const PlaceholderView({
    required this.eyebrow,
    required this.title,
    required this.message,
    this.illustration,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String message;

  /// Name of an `assets/illustrations` file, shown above [message].
  final String? illustration;

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
            PageHeader(eyebrow: eyebrow, title: title),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (illustration != null) ...<Widget>[
                        AppIllustration(illustration!),
                        const SizedBox(height: AppSpacing.space3),
                      ],
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
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
