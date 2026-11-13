import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_radius.dart';
import 'package:auditor_monkey/shared/theme/app_shadows.dart';
import 'package:auditor_monkey/shared/theme/app_theme.dart';
import 'package:auditor_monkey/shared/widgets/token_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the sheet draws shadowFloat and has no Material elevation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: TextButton(
              onPressed: () => showTokenSheet<void>(
                context: context,
                builder: (BuildContext _) => const SizedBox(
                  height: 120,
                  child: Center(child: Text('sheet body')),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('sheet body'), findsOneWidget);

    final BottomSheet sheet = tester.widget<BottomSheet>(
      find.byType(BottomSheet),
    );
    expect(sheet.elevation, 0);
    expect(sheet.backgroundColor, Colors.transparent);
    expect(sheet.clipBehavior, Clip.none);

    final BoxDecoration decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(SheetSurface),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;
    expect(decoration.boxShadow, AppShadows.shadowFloat);
    expect(decoration.color, AppColors.background);
    expect(decoration.borderRadius, AppRadius.sheet);
  });
}
