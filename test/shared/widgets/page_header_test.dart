import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_text_styles.dart';
import 'package:auditor_monkey/shared/widgets/page_header.dart';
import 'package:auditor_monkey/shared/widgets/placeholder_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_harness.dart';

Finder _headerNodes() => find.byWidgetPredicate(
  (Widget w) => w is Semantics && w.properties.header == true,
);

void main() {
  testWidgets('shows eyebrow in accentText and title in displayTitle', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      const PageHeader(eyebrow: 'Your Wallet', title: 'Accounts'),
    );
    final Text eyebrow = tester.widget<Text>(find.text('Your Wallet'));
    expect(eyebrow.style?.color, AppColors.accentText);
    expect(eyebrow.style?.fontSize, AppTextStyles.pageEyebrow.fontSize);
    final Text title = tester.widget<Text>(find.text('Accounts'));
    expect(title.style?.fontSize, AppTextStyles.displayTitle.fontSize);
    expect(_headerNodes(), findsOneWidget);
  });

  testWidgets('no eyebrow line when none is given', (
    WidgetTester tester,
  ) async {
    await pumpThemed(tester, const PageHeader(title: 'Accounts'));
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('PlaceholderView uses PageHeader and keeps its message', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      const PlaceholderView(
        eyebrow: 'Your Wallet',
        title: 'Accounts',
        message: 'Your accounts will show up here.',
      ),
    );
    expect(find.byType(PageHeader), findsOneWidget);
    expect(find.text('Your accounts will show up here.'), findsOneWidget);
  });

  testWidgets('large text (2.0) wraps the title without overflow', (
    WidgetTester tester,
  ) async {
    await pumpThemed(
      tester,
      const PageHeader(eyebrow: 'Your Wallet', title: 'Accounts and balances'),
      textScale: 2,
      width: 240,
    );
    expect(tester.takeException(), isNull);
  });
}
