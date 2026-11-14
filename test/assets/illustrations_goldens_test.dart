@Tags(<String>['golden'])
library;

import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_spacing.dart';
import 'package:auditor_monkey/shared/widgets/app_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/golden.dart';
import '../support/rupee_golden.dart';

const List<String> _names = <String>[
  'empty_accounts',
  'empty_transactions',
  'empty_statement',
  'empty_insights',
  'empty_home',
  'empty_top_spending',
  'error_generic',
  'wizard_welcome',
  'wizard_pick',
  'wizard_balances',
  'wizard_done',
  'mascot_poster',
  'success_goal',
];

void main() {
  testWidgets('golden: illustrations_all', (WidgetTester tester) async {
    setGoldenSurface(tester);
    // A taller surface, so all thirteen fit on one image (7 rows of 2).
    tester.view.physicalSize = const Size(390 * 2, 1900 * 2);
    await tester.pumpWidget(
      rupeeGoldenApp(
        Scaffold(
          backgroundColor: AppColors.background,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Wrap(
              spacing: AppSpacing.space3,
              runSpacing: AppSpacing.space3,
              children: <Widget>[
                for (final String name in _names)
                  Container(
                    width: 170,
                    padding: const EdgeInsets.all(AppSpacing.space2),
                    decoration: BoxDecoration(
                      color: AppColors.tile,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AppIllustration(
                      name,
                      size: AppIllustrationSize.wizard,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectGolden(tester, 'illustrations_all');
  });
}
