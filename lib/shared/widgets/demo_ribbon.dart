import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/demo_data/application/demo_mode.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Slim bar pinned at the top of the app while demo data is loaded. Full
/// width, `warning` fill, `ink` text (DESIGN.md "Demo data"). Shows nothing
/// when demo mode is off, so real data is never mistaken for demo data.
class DemoRibbon extends ConsumerWidget {
  const DemoRibbon({super.key});

  static const String message = 'Demo data — not your real money';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool active = ref.watch(demoModeActiveProvider);
    final Widget ribbon = active
        ? Semantics(
            container: true,
            child: DecoratedBox(
              decoration: const BoxDecoration(color: AppColors.warning),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: AppSpacing.space2,
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          )
        : const SizedBox.shrink();
    return ribbon;
  }
}
