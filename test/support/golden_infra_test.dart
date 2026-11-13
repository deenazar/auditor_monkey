@Tags(<String>['golden'])
library;

import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_shadows.dart';
import 'package:auditor_monkey/shared/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'golden.dart';

/// Proves the golden setup: app-font text and Lucide icons are real glyphs
/// (not boxes), the surface is 780x1688, and shadows are drawn.
void main() {
  testWidgets('fonts, icons, surface and shadow look right', (
    WidgetTester tester,
  ) async {
    await pumpGolden(
      tester,
      Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Accounts', style: AppTextStyles.displayTitle),
                const SizedBox(height: 8),
                const Text('₹1,23,456.00', style: AppTextStyles.displayAmount),
                const Text(
                  'Light 300 / Regular 400',
                  style: AppTextStyles.body,
                ),
                const Text('Medium 500 title', style: AppTextStyles.title),
                const Text(
                  'SemiBold 600 name',
                  style: AppTextStyles.bodyStrong,
                ),
                const SizedBox(height: 24),
                const Row(
                  children: <Widget>[
                    Icon(LucideIcons.house, color: AppColors.ink),
                    SizedBox(width: 16),
                    Icon(LucideIcons.wallet, color: AppColors.ink),
                    SizedBox(width: 16),
                    Icon(LucideIcons.arrowLeftRight, color: AppColors.ink),
                    SizedBox(width: 16),
                    Icon(LucideIcons.triangleAlert, color: AppColors.danger),
                  ],
                ),
                const SizedBox(height: 32),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.shadowFloat,
                  ),
                  child: const SizedBox(width: 160, height: 80),
                ),
              ],
            ),
          ),
        ),
      ),
      'golden_infra',
    );
  });
}
