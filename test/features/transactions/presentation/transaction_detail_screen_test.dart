import 'package:auditor_monkey/core/utils/clock.dart';
import 'package:auditor_monkey/core/utils/validation_failure.dart';
import 'package:auditor_monkey/features/transactions/application/transactions_list_providers.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_list_item.dart';
import 'package:auditor_monkey/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:auditor_monkey/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/golden.dart';
import '../../../support/screen_pump.dart';
import 'transactions_fixtures.dart';

Override _detail(Stream<TransactionListItem?> Function() stream) =>
    transactionDetailProvider.overrideWith((Ref ref, String id) => stream());

Future<void> _pumpDetail(WidgetTester tester, List<Override> overrides) {
  return pumpScreen(
    tester,
    const Scaffold(body: TransactionDetailScreen(transactionId: 'x')),
    overrides: overrides,
  );
}

void main() {
  final TransactionListItem expense = txSampleItems().first;
  final TransactionListItem transfer = txSampleItems()[2];

  testWidgets('loading shows skeleton blocks, no content', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(tester, <Override>[
      _detail(() => const Stream<TransactionListItem?>.empty()),
    ]);
    await tester.pump();
    expect(find.text('This entry is gone'), findsNothing);
    expect(find.text('Edit entry'), findsNothing);
  });

  testWidgets('expense shows the amount, sign, category and note', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(tester, <Override>[
      _detail(() => Stream<TransactionListItem?>.value(expense)),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('-₹250.00'), findsOneWidget);
    expect(find.text('Groceries'), findsWidgets);
    expect(find.bySemanticsLabel('Note: Milk and bread'), findsOneWidget);
    expect(find.text('Edit entry'), findsOneWidget);
    expect(find.text('Delete entry'), findsOneWidget);
  });

  testWidgets('transfer shows From and To accounts with no sign', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(tester, <Override>[
      _detail(() => Stream<TransactionListItem?>.value(transfer)),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('₹5,000.00'), findsOneWidget);
    expect(find.text('Moved between accounts'), findsOneWidget);
    expect(find.bySemanticsLabel('From: SBI'), findsOneWidget);
    expect(find.bySemanticsLabel('To: Axis'), findsOneWidget);
  });

  testWidgets('a removed entry shows a friendly not-found state', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(tester, <Override>[
      _detail(() => Stream<TransactionListItem?>.value(null)),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('This entry is gone'), findsOneWidget);
    expect(find.text('Back to Transactions'), findsOneWidget);
  });

  testWidgets('a read error shows the error state with retry', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(tester, <Override>[
      _detail(
        () => Stream<TransactionListItem?>.error(
          const StorageFailure('Could not read.'),
        ),
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Could not open this entry'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('delete asks first, then goes back with an Undo toast', (
    WidgetTester tester,
  ) async {
    final FakeActions actions = FakeActions();
    final GoRouter router = GoRouter(
      initialLocation: '/transactions/${expense.entry.id}',
      routes: <RouteBase>[
        GoRoute(
          path: '/transactions',
          builder: (BuildContext context, GoRouterState state) =>
              const Scaffold(body: Text('LIST')),
        ),
        GoRoute(
          path: '/transactions/:transactionId',
          builder: (BuildContext context, GoRouterState state) =>
              TransactionDetailScreen(
                transactionId: state.pathParameters['transactionId'] ?? '',
              ),
        ),
      ],
    );
    setPhoneSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          clockProvider.overrideWithValue(goldenClock()),
          ...txOverrides(actions: actions),
          _detail(() => Stream<TransactionListItem?>.value(expense)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete entry'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this entry?'), findsOneWidget);
    expect(actions.deleted, isEmpty);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(actions.deleted, <String>[expense.entry.id]);
    expect(find.text('LIST'), findsOneWidget);
    expect(find.text('Entry deleted'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(actions.undone, <String>[expense.entry.id]);
  });
}
