import 'package:auditor_monkey/app/app.dart';
import 'package:auditor_monkey/app/router.dart';
import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/accounts/presentation/account_statement_screen.dart';
import 'package:auditor_monkey/features/quick_add/presentation/quick_add_sheet.dart';
import 'package:auditor_monkey/features/setup/presentation/setup_wizard_screen.dart';
import 'package:auditor_monkey/shared/theme/app_colors.dart';
import 'package:auditor_monkey/shared/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../support/provider_env.dart';
import '../support/test_env.dart';

/// The app on an in-memory database. [accounts] says how many accounts the
/// database starts with (0 = first launch, the wizard opens).
Future<Widget> _app(
  TestEnv env, {
  bool disableAnimations = false,
  int accounts = 1,
  String initialLocation = AppRoutes.home,
}) async {
  for (int i = 0; i < accounts; i++) {
    await env.account('Account $i');
  }
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: ProviderScope(
      overrides: <Override>[...envOverrides(env)],
      child: AuditorMonkeyApp(initialLocation: initialLocation),
    ),
  );
}

/// A widget test that also removes the app at the end, so database
/// streams close and no timer is left pending.
void testApp(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (WidgetTester tester) async {
    await body(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });
}

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());
  tearDown(() => env.close());

  const List<String> labels = <String>[
    'Home',
    'Insights',
    'Transactions',
    'Accounts',
  ];

  testApp('nav slots and Quick Add are at least 44x44', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(await _app(env));
    await tester.pumpAndSettle();

    for (final String label in <String>[...labels, 'Quick Add']) {
      final Size size = tester.getSize(find.bySemanticsLabel(label));
      expect(size.width, greaterThanOrEqualTo(44), reason: label);
      expect(size.height, greaterThanOrEqualTo(44), reason: label);
    }
    handle.dispose();
  });

  testApp('with reduce motion, tab switch shows the screen at once', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(await _app(env, disableAnimations: true));
    await tester.pumpAndSettle();
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Accounts'));
    await tester.pump();
    expect(find.text('Your Wallet'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Insights'));
    await tester.pump();
    expect(find.text('Your Spending'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Quick Add'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickAddSheet), findsOneWidget);
    handle.dispose();
  });

  testApp('active tab icon is ink and only it shows the pill', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await _app(env));
    await tester.pumpAndSettle();

    double pillOpacity(String id) => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.byKey(ValueKey<String>('nav-indicator-$id')),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;
    Color? iconColor(IconData icon) =>
        tester.widget<Icon>(find.byIcon(icon)).color;

    expect(iconColor(LucideIcons.house), AppColors.ink);
    expect(iconColor(LucideIcons.wallet), AppColors.iconInactive);
    expect(pillOpacity('home'), 1);
    expect(pillOpacity('accounts'), 0);

    await tester.tap(find.byIcon(LucideIcons.wallet));
    await tester.pumpAndSettle();

    expect(iconColor(LucideIcons.wallet), AppColors.ink);
    expect(iconColor(LucideIcons.house), AppColors.iconInactive);
    expect(pillOpacity('accounts'), 1);
    expect(pillOpacity('home'), 0);
  });

  group('first launch and routing', () {
    testApp('no accounts: the wizard opens, never Home', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(await _app(env, accounts: 0));
      await tester.pumpAndSettle();
      expect(find.byType(SetupWizardScreen), findsOneWidget);
      expect(find.text('Home'), findsNothing);
      expect(find.byType(AppBottomNav), findsNothing);
    });

    testApp('accounts exist: Home opens with the bottom bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(await _app(env));
      await tester.pumpAndSettle();
      expect(find.byType(SetupWizardScreen), findsNothing);
      expect(find.byType(AppBottomNav), findsOneWidget);
    });

    testApp('creating the first account leaves the wizard for Accounts', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(await _app(env, accounts: 0));
      await tester.pumpAndSettle();
      expect(find.byType(SetupWizardScreen), findsOneWidget);

      await env.account('SBI');
      await tester.pumpAndSettle();
      expect(find.byType(SetupWizardScreen), findsNothing);
      expect(find.text('Your Wallet'), findsOneWidget);
    });

    testApp('a deep link opens after the data is ready', (
      WidgetTester tester,
    ) async {
      final Account a = await env.account('Deep');
      await tester.pumpWidget(
        await _app(
          env,
          accounts: 0,
          initialLocation: AppRoutes.accountStatement(a.id),
        ),
      );
      await tester.pumpAndSettle();
      final AccountStatementScreen screen = tester.widget(
        find.byType(AccountStatementScreen),
      );
      expect(screen.accountId, a.id);
      expect(find.byType(AppBottomNav), findsOneWidget);
    });

    testApp('a bad id still opens the statement route (screen decides)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        await _app(env, initialLocation: '/accounts/not-a-uuid'),
      );
      await tester.pumpAndSettle();
      final AccountStatementScreen screen = tester.widget(
        find.byType(AccountStatementScreen),
      );
      expect(screen.accountId, 'not-a-uuid');
    });

    testApp('tabs keep their screen when switching back', (
      WidgetTester tester,
    ) async {
      final Account a = await env.account('Keep');
      await tester.pumpWidget(
        await _app(
          env,
          accounts: 0,
          initialLocation: AppRoutes.accountStatement(a.id),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AccountStatementScreen), findsOneWidget);
      await tester.tap(find.byIcon(LucideIcons.house));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(LucideIcons.wallet));
      await tester.pumpAndSettle();
      expect(find.byType(AccountStatementScreen), findsOneWidget);
    });
  });
}
