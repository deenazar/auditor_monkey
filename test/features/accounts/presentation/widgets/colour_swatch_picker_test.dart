import 'package:auditor_monkey/features/accounts/presentation/widgets/colour_swatch_picker.dart';
import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../support/widget_harness.dart';

const List<String> _tokens = <String>[
  'accountAxis',
  'accountSbi',
  'accountScb',
];

void main() {
  testWidgets('shows one named swatch per token', (WidgetTester tester) async {
    await pumpCompact(
      tester,
      ColourSwatchPicker(tokens: _tokens, selected: null, onChanged: (_) {}),
    );
    expect(find.bySemanticsLabel('Yellow'), findsOneWidget);
    expect(find.bySemanticsLabel('Magenta'), findsOneWidget);
    expect(find.bySemanticsLabel('Green'), findsOneWidget);
    expect(find.byIcon(LucideIcons.check), findsNothing);
  });

  testWidgets('tapping a swatch reports its token', (
    WidgetTester tester,
  ) async {
    final List<String> picked = <String>[];
    await pumpCompact(
      tester,
      ColourSwatchPicker(
        tokens: _tokens,
        selected: 'accountAxis',
        onChanged: picked.add,
      ),
    );
    await tester.tap(find.bySemanticsLabel('Magenta'));
    await tester.pump();
    expect(picked, <String>['accountSbi']);
  });

  testWidgets('selected swatch shows a check and is marked selected', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      ColourSwatchPicker(
        tokens: _tokens,
        selected: 'accountSbi',
        onChanged: (_) {},
      ),
    );
    expect(find.byIcon(LucideIcons.check), findsOneWidget);
    final Semantics semantics = tester.widget<Semantics>(
      find.bySemanticsLabel('Magenta'),
    );
    expect(semantics.properties.selected, isTrue);
    expect(semantics.properties.button, isTrue);
    final Icon check = tester.widget<Icon>(find.byIcon(LucideIcons.check));
    expect(check.color, AppColors.onDark);
  });

  testWidgets('each swatch target is at least 44pt', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      ColourSwatchPicker(tokens: _tokens, selected: null, onChanged: (_) {}),
    );
    final Size size = tester.getSize(
      find
          .descendant(
            of: find.bySemanticsLabel('Green'),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });
}
