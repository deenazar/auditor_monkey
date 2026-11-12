import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/widgets/stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('shows the label and the child on a tile background', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      const StatTile(label: 'INCOME VS EXPENSE', child: Text('chart here')),
    );
    expect(find.text('INCOME VS EXPENSE'), findsOneWidget);
    expect(find.text('chart here'), findsOneWidget);
    final DecoratedBox box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(StatTile),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((box.decoration as BoxDecoration).color, AppColors.tile);
  });
}
