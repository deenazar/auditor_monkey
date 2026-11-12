// The sheet frame (plan S4): opens from the + button, hardware keys work,
// one save closes the sheet and shows the toast, Undo removes the entry,
// Android back closes without saving. These tests only need the pad keys
// and the Save button, so they keep working when the body is replaced.
import 'package:auditor_monkey/app/app.dart';
import 'package:auditor_monkey/features/quick_add/presentation/quick_add_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/golden.dart' show setPhoneSurface;
import '../../../support/provider_env.dart';
import '../../../support/quick_add_env.dart';
import '../../../support/test_env.dart';

void main() {
  late TestEnv env;

  setUp(() async {
    env = quickAddTestEnv();
    await env.account('Hand', opening: 100000);
  });
  tearDown(() => env.close());

  Future<void> openSheet(
    WidgetTester tester, {
    bool reduceMotion = false,
  }) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: ProviderScope(
          overrides: envOverrides(env),
          child: const AuditorMonkeyApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Quick Add'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickAddSheet), findsOneWidget);
  }

  Future<void> keys(WidgetTester tester, List<LogicalKeyboardKey> list) async {
    for (final LogicalKeyboardKey k in list) {
      await tester.sendKeyEvent(k);
    }
    await tester.pump();
  }

  Future<void> end(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  }

  const List<LogicalKeyboardKey> two50 = <LogicalKeyboardKey>[
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit0,
  ];

  testWidgets('hardware keys + Enter save, close the sheet, show the toast', (
    WidgetTester tester,
  ) async {
    await openSheet(tester);
    await keys(tester, two50);
    await keys(tester, <LogicalKeyboardKey>[LogicalKeyboardKey.enter]);
    await tester.pumpAndSettle();

    expect(find.byType(QuickAddSheet), findsNothing);
    expect(find.text('Expense saved · ₹250.00'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(await env.count('transactions', liveOnly: true), 1);
    await end(tester);
  });

  testWidgets('Undo removes the entry and balances return', (
    WidgetTester tester,
  ) async {
    await openSheet(tester);
    await keys(tester, two50);
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();
    expect((await env.accounts.getBalances()).single.balance, 100000 - 25000);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Entry removed'), findsOneWidget);
    expect(await env.count('transactions', liveOnly: true), 0);
    expect((await env.accounts.getBalances()).single.balance, 100000);
    await end(tester);
  });

  testWidgets('a double Enter saves exactly one entry', (
    WidgetTester tester,
  ) async {
    await openSheet(tester);
    await keys(tester, two50);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(await env.count('transactions'), 1);
    await end(tester);
  });

  testWidgets('Save stays off for an empty or zero amount', (
    WidgetTester tester,
  ) async {
    await openSheet(tester);
    await keys(tester, <LogicalKeyboardKey>[LogicalKeyboardKey.enter]);
    await keys(tester, <LogicalKeyboardKey>[
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.period,
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.enter,
    ]);
    await tester.pumpAndSettle();
    expect(find.byType(QuickAddSheet), findsOneWidget);
    expect(await env.count('transactions'), 0);
    await end(tester);
  });

  testWidgets('Android back closes the sheet and drops the draft', (
    WidgetTester tester,
  ) async {
    await openSheet(tester);
    await keys(tester, two50);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(QuickAddSheet), findsNothing);
    expect(find.textContaining('saved'), findsNothing);
    expect(await env.count('transactions'), 0);
    await end(tester);
  });

  testWidgets('reduce motion: opens and closes with no animation time', (
    WidgetTester tester,
  ) async {
    await openSheet(tester, reduceMotion: true);
    await keys(tester, two50);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.byType(QuickAddSheet), findsNothing);
    await tester.pumpAndSettle();
    await end(tester);
  });
}
