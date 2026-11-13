import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Centred page header: optional `pageEyebrow` in `accentText`, then the
/// `displayTitle`. Exposed to screen readers as a header.
class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    this.eyebrow,
    this.onMint = false,
    super.key,
  });

  /// On the mint hero the eyebrow is `ink` (green text on mint fails
  /// contrast).
  final bool onMint;

  /// Small green line above the title, e.g. "Your Wallet". Optional.
  final String? eyebrow;

  /// Main page title, e.g. "Accounts".
  final String title;

  @override
  Widget build(BuildContext context) {
    final String? eyebrowText = eyebrow;
    return Semantics(
      header: true,
      container: true,
      child: Column(
        children: <Widget>[
          if (eyebrowText != null) ...<Widget>[
            Text(
              eyebrowText,
              textAlign: TextAlign.center,
              style: onMint
                  ? AppTextStyles.pageEyebrow.copyWith(color: AppColors.ink)
                  : AppTextStyles.pageEyebrow,
            ),
            const SizedBox(height: AppSpacing.space1),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayTitle,
          ),
        ],
      ),
    );
  }
}
