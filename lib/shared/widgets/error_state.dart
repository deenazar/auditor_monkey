import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import 'empty_state.dart';
import 'primary_button.dart';

/// Error state in the EmptyState layout: `danger` triangle icon, `title`,
/// a `body` message and a "Try again" button when [onRetry] is given.
///
/// Pass a message a person can act on. Never pass raw exception text.
/// Announced to screen readers as it appears.
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
    super.key,
  });

  final String title;
  final String message;

  /// Called by the retry button. Null hides the button.
  final VoidCallback? onRetry;

  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? retry = onRetry;
    return Semantics(
      liveRegion: true,
      child: EmptyState(
        icon: LucideIcons.triangleAlert,
        iconColour: AppColors.danger,
        title: title,
        message: message,
        action: retry == null
            ? null
            : PrimaryButton(
                label: retryLabel,
                onPressed: retry,
                fullWidth: false,
              ),
      ),
    );
  }
}
