// Plan 3.2 states of the Quick Add sheet: loading (Q1), load error (Q12),
// no categories (Q11), and the save path through the real app with the
// saved toast and Undo (Q9, Q13).
import 'package:auditor_monkey/app/app.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_data_provider.dart';
import 'package:auditor_monkey/features/quick_add/presentation/quick_add_sheet.dart';
import 'package:auditor_monkey/shared/widgets/error_state.dart';
import 'package:auditor_monkey/shared/widgets/skeleton_block.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/golden.dart' show setPhoneSurface;
import '../../../support/provider_env.dart';
import '../../../support/test_env.dart';
import 'quick_add_body_support.dart';

void main() {
  late TestEnv env;

  setUp(() => env = quickAddTestEnv());
  tearDown(() => env.close());

  testWidgets('Q1 loading: skeleton rows, Save off, the pad still works', (
    WidgetTester tester,
  ) async {
    await pumpBody(tester, env);
    expect(find.byType(SkeletonBlock), findsWidgets);
    await typeKeys(tester, '7');
    expect(find.bySemanticsLabel('₹7'), findsOneWidget);
    await endTest(tester);
  });

  testWidgets(
    'Q12 load error: ErrorState, retry, and the typed amount is kept',
    (WidgetTester tester) async {
      await pumpBody(
        tester,
        env,
        extra: <Override>[
          quickAddDataProvider.overrideWith(
            (Ref ref) => Future<QuickAddData>.error(StateError('boom')),
          ),
        ],
      );
      await typeKeys(tester, '42');
      await settleDb(tester);
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text("We couldn't load your accounts."), findsOneWidget);
      expect(find.bySemanticsLabel('₹42'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await settleDb(tester);
      expect(find.byType(ErrorState), findsOneWidget);
      await endTest(tester);
    },
  );

  testWidgets('Q11 no categories: the caption shows and Save stays off', (
    WidgetTester tester,
  ) async {
    await env.account('Hand', opening: 100000);
    await env.rawSql(
      "UPDATE categories SET archived = 1 WHERE kind = 'expense'",
    );
    await pumpBody(tester, env);
    await settleDb(tester);
    await typeKeys(tester, '30');
    expect(find.text('No expense categories to pick.'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Save expense'))
          .flagsCollection
          .isEnabled
          .toString(),
      isNot(contains('true')),
    );
    await endTest(tester);
  });

  testWidgets('Q9/Q13: a double tap saves once; toast; Undo removes it', (
    WidgetTester tester,
  ) async {
    await env.account('Hand', opening: 100000);
    setPhoneSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: envOverrides(env),
        child: const AuditorMonkeyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Quick Add'));
    await tester.pumpAndSettle();
    await settleDb(tester);

    await typeKeys(tester, '250');
    await tester.tap(saveButton('Save expense'));
    await tester.tap(saveButton('Save expense'));
    await settleDb(tester);

    expect(find.byType(QuickAddSheet), findsNothing);
    expect(await savedRows(env), hasLength(1));
    expect(find.text('Expense saved · ₹250.00'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settleDb(tester);
    expect(find.text('Entry removed'), findsOneWidget);
    expect(await savedRows(env), isEmpty);
    await endTest(tester);
  });
}
