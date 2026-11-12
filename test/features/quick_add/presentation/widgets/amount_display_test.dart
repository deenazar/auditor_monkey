import 'package:auditor_monkey/features/quick_add/presentation/widgets/amount_display.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../support/widget_harness.dart';

AmountDisplay _display({
  String text = '',
  TransactionType type = TransactionType.expense,
  String? hint,
  bool isError = false,
  int refuseTick = 0,
  ValueChanged<String>? onPaste,
}) => AmountDisplay(
  text: text,
  type: type,
  hint: hint,
  isError: isError,
  refuseTick: refuseTick,
  onPaste: onPaste,
);

/// Horizontal offset of the refused nudge (0 when at rest).
double _nudgeX(WidgetTester tester) {
  final Transform transform = tester.widget<Transform>(
    find.descendant(
      of: find.byType(AmountDisplay),
      matching: find.byType(Transform),
    ),
  );
  return transform.transform.getTranslation().x;
}

void main() {
  group('groupTypedAmount (pure text grouping, no double)', () {
    test('Indian grouping keeps the typed decimals as they are', () {
      expect(groupTypedAmount('1250.5'), '1,250.5');
      expect(groupTypedAmount('12345678'), '1,23,45,678');
      expect(groupTypedAmount('12345678.25'), '1,23,45,678.25');
      expect(groupTypedAmount('999'), '999');
      expect(groupTypedAmount('12.'), '12.');
      expect(groupTypedAmount('.5'), '0.5');
      expect(groupTypedAmount(''), '0');
    });
  });

  testWidgets('empty shows ₹0 in inkMuted', (WidgetTester tester) async {
    await pumpCompact(tester, _display());
    expect(find.bySemanticsLabel('₹0'), findsOneWidget);
    final RichText rich = tester.widget<RichText>(
      find.byWidgetPredicate(
        (Widget w) => w is RichText && w.text.toPlainText() == '₹0',
      ),
    );
    expect(rich.text.style?.color, AppColors.inkMuted);
  });

  testWidgets('typed text is grouped with the rupee sign in front', (
    WidgetTester tester,
  ) async {
    await pumpCompact(tester, _display(text: '1250.5'));
    expect(find.bySemanticsLabel('₹1,250.5'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (Widget w) => w is RichText && w.text.toPlainText() == '₹1,250.5',
      ),
      findsOneWidget,
    );
  });

  testWidgets('income gets a plus in front; transfer shows the arrow', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      _display(text: '500', type: TransactionType.income),
    );
    expect(find.bySemanticsLabel('+₹500'), findsOneWidget);

    await pumpCompact(
      tester,
      _display(text: '500', type: TransactionType.transfer),
    );
    expect(find.byIcon(LucideIcons.arrowLeftRight), findsOneWidget);
    expect(find.bySemanticsLabel('₹500'), findsOneWidget);
  });

  testWidgets('hint shows under the amount; errors use danger', (
    WidgetTester tester,
  ) async {
    await pumpCompact(
      tester,
      _display(text: '1.234', hint: 'Use at most two decimals.', isError: true),
    );
    final Text hint = tester.widget<Text>(
      find.text('Use at most two decimals.'),
    );
    expect(hint.style?.color, AppColors.danger);

    await pumpCompact(tester, _display(text: '5', hint: 'Note on the amount'));
    expect(
      tester.widget<Text>(find.text('Note on the amount')).style?.color,
      AppColors.inkMuted,
    );
  });

  testWidgets('refuseTick change plays the nudge; it ends at rest', (
    WidgetTester tester,
  ) async {
    Future<void> build(int tick) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 390,
              child: _display(text: '12.34', refuseTick: tick),
            ),
          ),
        ),
      ),
    );

    await build(0);
    await tester.pump();
    expect(_nudgeX(tester), 0);

    await build(1);
    await tester.pump(const Duration(milliseconds: 100));
    expect(_nudgeX(tester).abs(), greaterThan(0));
    expect(_nudgeX(tester).abs(), lessThanOrEqualTo(AppSpacing.space2));

    await tester.pumpAndSettle();
    expect(_nudgeX(tester), closeTo(0, 0.001));
  });

  testWidgets('reduce motion: the refused nudge does not move the amount', (
    WidgetTester tester,
  ) async {
    Future<void> build(int tick) => tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 390,
              child: _display(text: '12.34', refuseTick: tick),
            ),
          ),
        ),
      ),
    );

    await build(0);
    await build(1);
    await tester.pump();
    expect(_nudgeX(tester), 0);
    expect(find.bySemanticsLabel('₹12.34'), findsOneWidget);
  });

  testWidgets('long press offers Paste and passes the clipboard text on', (
    WidgetTester tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.getData') {
          return <String, dynamic>{'text': '1,23,456.50'};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final List<String> pasted = <String>[];
    await pumpCompact(
      tester,
      Builder(
        builder: (BuildContext context) =>
            _display(text: '', onPaste: pasted.add),
      ),
    );
    await tester.longPress(find.bySemanticsLabel('₹0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paste'));
    await tester.pumpAndSettle();
    expect(pasted, <String>['1,23,456.50']);
  });

  testWidgets('no paste menu without onPaste', (WidgetTester tester) async {
    await pumpCompact(tester, _display(text: '4'));
    await tester.longPress(find.bySemanticsLabel('₹4'));
    await tester.pumpAndSettle();
    expect(find.text('Paste'), findsNothing);
  });

  testWidgets('text scale 2.0 shrinks a long amount instead of clipping', (
    WidgetTester tester,
  ) async {
    await pumpCompact(tester, _display(text: '1000000000000.99'), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('₹10,00,00,00,00,000.99'), findsOneWidget);
  });
}
