@Tags(<String>['golden'])
library;

import 'package:auditor_monkey/features/quick_add/presentation/widgets/category_chip.dart';
import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/golden.dart';

/// One chip per colour group, with a fitting icon and label.
const List<({String group, String label, String icon})> _groups =
    <({String group, String label, String icon})>[
      (group: 'essentials', label: 'Essentials', icon: 'zap'),
      (group: 'food', label: 'Food', icon: 'utensils'),
      (group: 'transport', label: 'Transport', icon: 'bus'),
      (group: 'home', label: 'Home', icon: 'house'),
      (group: 'lifestyle', label: 'Lifestyle', icon: 'shirt'),
      (group: 'health', label: 'Health', icon: 'heart-pulse'),
      (group: 'family', label: 'Family', icon: 'users'),
      (group: 'finance', label: 'Finance', icon: 'landmark'),
      (group: 'other', label: 'Other', icon: 'ellipsis'),
      (group: 'income', label: 'Income', icon: 'banknote'),
    ];

/// Left column: not selected. Right column: selected. Same ten groups.
Widget _column({required bool selected}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (final ({String group, String label, String icon}) g in _groups)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space2),
          child: CategoryChip(
            name: g.label,
            iconName: g.icon,
            colourGroup: g.group,
            selected: selected,
            onTap: () {},
          ),
        ),
    ],
  );
}

void main() {
  testWidgets('category chips for all 10 colour groups, selected and not', (
    WidgetTester tester,
  ) async {
    await pumpGolden(
      tester,
      Scaffold(
        backgroundColor: AppColors.background,
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _column(selected: false),
              const SizedBox(width: AppSpacing.space6),
              _column(selected: true),
            ],
          ),
        ),
      ),
      'category_chips_all_groups',
    );
  });
}
