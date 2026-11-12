import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_sizes.dart';
import 'package:auditor_monkey/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('shows the label above the field and is a text field', (
    WidgetTester tester,
  ) async {
    await pumpThemed(tester, const AppTextField(label: 'Account name'));
    expect(find.text('Account name'), findsOneWidget);
    expect(find.bySemanticsLabel('Account name'), findsOneWidget);
    final Size field = tester.getSize(find.byType(TextField));
    expect(field.height, greaterThanOrEqualTo(AppSizes.fieldHeight));
  });

  testWidgets('typing calls onChanged', (WidgetTester tester) async {
    final List<String> values = <String>[];
    await pumpThemed(
      tester,
      AppTextField(label: 'Name', onChanged: values.add),
    );
    await tester.enterText(find.byType(TextField), 'Hand');
    expect(values, <String>['Hand']);
  });

  testWidgets('focus is tracked by the field', (WidgetTester tester) async {
    await pumpThemed(tester, const AppTextField(label: 'Name'));
    expect(
      tester.widget<InputDecorator>(find.byType(InputDecorator)).isFocused,
      isFalse,
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(
      tester.widget<InputDecorator>(find.byType(InputDecorator)).isFocused,
      isTrue,
    );
  });

  testWidgets('error text shows in danger below the field', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      const AppTextField(label: 'Name', errorText: 'Name is already used'),
    );
    expect(find.text('Name is already used'), findsOneWidget);
    final Text message = tester.widget<Text>(find.text('Name is already used'));
    expect(message.style?.color, AppColors.danger);
  });

  testWidgets('maxLength stops input and hides the counter', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpThemed(
      tester,
      AppTextField(label: 'Name', controller: controller, maxLength: 5),
    );
    await tester.enterText(find.byType(TextField), '123456789');
    expect(controller.text, '12345');
    expect(find.text('5'), findsNothing);
  });

  testWidgets('large text (2.0) does not overflow', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      const AppTextField(
        label: 'Opening balance',
        errorText: 'Enter a valid amount, for example 1,000.50',
      ),
      textScale: 2,
      width: 200,
    );
    expect(tester.takeException(), isNull);
  });
}
