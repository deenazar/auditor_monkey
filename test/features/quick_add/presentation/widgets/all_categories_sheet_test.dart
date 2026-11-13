import 'package:auditor_monkey/features/quick_add/presentation/widgets/all_categories_sheet.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/quick_add_view_models.dart';
import 'package:auditor_monkey/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const List<CategoryChipData> _all = <CategoryChipData>[
  CategoryChipData(
    id: 'inc',
    name: 'Salary',
    icon: 'banknote',
    colourGroup: 'income',
  ),
  CategoryChipData(
    id: 'ent',
    name: 'Movies',
    icon: 'tv',
    colourGroup: 'lifestyle',
  ),
  CategoryChipData(
    id: 'gro',
    name: 'Groceries',
    icon: 'shopping-cart',
    colourGroup: 'food',
  ),
  CategoryChipData(
    id: 'odd',
    name: 'Mystery',
    icon: 'x',
    colourGroup: 'not-a-group',
  ),
  CategoryChipData(
    id: 'ele',
    name: 'Electricity',
    icon: 'zap',
    colourGroup: 'essentials',
  ),
];

/// Opens the sheet from a button and records the returned id.
Future<void> _pumpOpener(WidgetTester tester, List<String?> results) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              results.add(
                await AllCategoriesSheet.show(
                  context,
                  categories: _all,
                  selectedId: 'gro',
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('sections follow group order, each with an overline heading', (
    WidgetTester tester,
  ) async {
    final List<String?> results = <String?>[];
    await _pumpOpener(tester, results);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('ESSENTIALS'), findsOneWidget);
    expect(find.text('FOOD'), findsOneWidget);
    expect(find.text('LIFESTYLE'), findsOneWidget);
    expect(find.text('OTHER'), findsOneWidget);
    expect(find.text('INCOME'), findsOneWidget);
    // Empty groups are left out.
    expect(find.text('HOME'), findsNothing);
    expect(find.text('TRANSPORT'), findsNothing);

    final double essentials = tester.getTopLeft(find.text('ESSENTIALS')).dy;
    final double food = tester.getTopLeft(find.text('FOOD')).dy;
    final double income = tester.getTopLeft(find.text('INCOME')).dy;
    expect(essentials, lessThan(food));
    expect(food, lessThan(income));
  });

  testWidgets('an unknown group shows under OTHER', (
    WidgetTester tester,
  ) async {
    final List<String?> results = <String?>[];
    await _pumpOpener(tester, results);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final double other = tester.getTopLeft(find.text('OTHER')).dy;
    final double mystery = tester.getTopLeft(find.text('Mystery')).dy;
    expect(mystery, greaterThan(other));
  });

  testWidgets('tapping a chip closes the sheet and returns its id', (
    WidgetTester tester,
  ) async {
    final List<String?> results = <String?>[];
    await _pumpOpener(tester, results);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Movies'));
    await tester.pumpAndSettle();
    expect(results, <String?>['ent']);
    expect(find.text('Categories'), findsNothing);
  });

  testWidgets('closing without a pick returns null', (
    WidgetTester tester,
  ) async {
    final List<String?> results = <String?>[];
    await _pumpOpener(tester, results);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 20));
    await tester.pumpAndSettle();
    expect(results, <String?>[null]);
  });
}
