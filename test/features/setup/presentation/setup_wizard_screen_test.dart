import 'package:auditor_monkey/features/accounts/presentation/widgets/account_form_sheet.dart';
import 'package:auditor_monkey/features/setup/domain/account_presets.dart';
import 'package:auditor_monkey/features/setup/presentation/setup_wizard_screen.dart';
import 'package:auditor_monkey/shared/theme/app_sizes.dart';
import 'package:auditor_monkey/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/db_screen.dart';
import '../../../support/test_env.dart';

/// Taps by semantics label, then lets the step change finish. (A step that
/// is still fading in has no semantics yet, so it cannot be found.)
Future<void> _tap(WidgetTester tester, String label) async {
  final Finder target = find.bySemanticsLabel(label);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Taps an icon button by its tooltip (back, edit).
Future<void> _tapTooltip(WidgetTester tester, String tooltip) async {
  await tester.tap(find.byTooltip(tooltip));
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final Finder field = find.descendant(
    of: find.bySemanticsLabel(label),
    matching: find.byType(TextField),
  );
  await tester.enterText(field, text);
  await tester.pump();
}

/// Button enabled flag from its semantics.
bool _enabled(WidgetTester tester, String label) =>
    tester.widget<Semantics>(find.bySemanticsLabel(label)).properties.enabled ??
    false;

String _presetId(String name) =>
    accountPresets.firstWhere((p) => p.name == name).id;

Future<void> _pumpWizard(
  WidgetTester tester,
  TestEnv env, {
  double textScale = 1,
}) => pumpWithEnv(tester, env, const SetupWizardScreen(), textScale: textScale);

/// Welcome -> pick -> balances -> review, with the seven presets picked.
Future<void> _toReview(WidgetTester tester) async {
  await _tap(tester, 'Get started');
  await _tap(tester, 'Continue');
  await _tap(tester, 'Continue');
}

void main() {
  testWithEnv('full flow saves all seven presets with their balances', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await _pumpWizard(tester, env);
    expect(find.text('Set up your accounts'), findsOneWidget);
    await _tap(tester, 'Get started');
    expect(find.text('Your accounts'), findsOneWidget);
    await _tap(tester, 'Continue');
    expect(find.text('Opening balances'), findsOneWidget);

    await _enter(tester, 'Balance for SBI', '1,23,456.50');
    await _enter(tester, 'Balance for PF', '50000');
    await _tap(tester, 'Continue');
    expect(find.text('All set?'), findsOneWidget);

    await _tap(tester, 'Create accounts');
    await tester.pumpAndSettle();
    expect(await env.count('accounts', liveOnly: true), 7);
    final Map<String, Object?> sbi = await env.rawRow(
      'accounts',
      _presetId('SBI'),
    );
    expect(sbi['opening_balance'], 12345650);
    final Map<String, Object?> pf = await env.rawRow(
      'accounts',
      _presetId('PF'),
    );
    expect(pf['opening_balance'], 5000000);
  });

  testWithEnv('a double tap on Create accounts saves once', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await _pumpWizard(tester, env);
    await _toReview(tester);
    await tester.tap(find.bySemanticsLabel('Create accounts'));
    await tester.tap(find.bySemanticsLabel('Create accounts'));
    await tester.pumpAndSettle();
    expect(await env.count('accounts', liveOnly: true), 7);
    expect(find.textContaining('already exists'), findsNothing);
  });

  testWithEnv('a failed save keeps the entries and shows why', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await env.account('SBI');
    await _pumpWizard(tester, env);
    await _toReview(tester);
    await _tap(tester, 'Create accounts');
    await tester.pumpAndSettle();

    expect(
      find.text('An account with this name already exists.'),
      findsOneWidget,
    );
    expect(await env.count('accounts', liveOnly: true), 1);
    expect(_enabled(tester, 'Create accounts'), isTrue);
    expect(find.bySemanticsLabel('Create accounts'), findsOneWidget);
  });

  testWithEnv('Continue is off with nothing picked, and says why', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await _pumpWizard(tester, env);
    await _tap(tester, 'Get started');
    for (final AccountPreset p in accountPresets) {
      await _tap(tester, p.name);
    }
    expect(_enabled(tester, 'Continue'), isFalse);
    expect(find.text('Pick at least one account to continue.'), findsOneWidget);
  });

  testWithEnv('back keeps the picked accounts', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await _pumpWizard(tester, env);
    await _tap(tester, 'Get started');
    await _tap(tester, 'Hand');
    await _tap(tester, 'Continue');
    await _tapTooltip(tester, 'Back');
    expect(find.text('Your accounts'), findsOneWidget);
    expect(
      tester
          .widget<Semantics>(find.bySemanticsLabel('Hand'))
          .properties
          .selected,
      isFalse,
    );
  });

  testWithEnv('add another account through the sheet', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await _pumpWizard(tester, env);
    await _tap(tester, 'Get started');
    await _tap(tester, 'Add another account');
    expect(find.byType(AccountFormSheet), findsOneWidget);
    await _enter(tester, 'Name', 'Gift Card');
    await tester.tap(
      find.descendant(
        of: find.byType(AccountFormSheet),
        matching: find.byType(PrimaryButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AccountFormSheet), findsNothing);
    expect(find.bySemanticsLabel('Gift Card'), findsOneWidget);
  });

  testWithEnv('editing to a name another row has shows an inline error', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await _pumpWizard(tester, env);
    await _tap(tester, 'Get started');
    await _tapTooltip(tester, 'Edit Hand');
    await _enter(tester, 'Name', 'sbi');
    expect(
      find.text('You already have an account with this name.'),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AccountFormSheet),
        matching: find.byType(PrimaryButton),
      ),
    );
    await tester.pump();
    expect(find.byType(AccountFormSheet), findsOneWidget);
  });

  testWithEnv('every step has 44pt buttons and works at text scale 2.0', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await _pumpWizard(tester, env, textScale: 2);
    expect(tester.takeException(), isNull);
    final Finder button = find.descendant(
      of: find.byType(PrimaryButton),
      matching: find.byType(AnimatedContainer),
    );
    expect(tester.getSize(button).height, AppSizes.buttonHeight);
    await _tap(tester, 'Get started');
    expect(tester.takeException(), isNull);
    await _tap(tester, 'Continue');
    await _tap(tester, 'Continue');
    await tester.pumpAndSettle();
    expect(find.text('All set?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWithEnv('the step change finishes at once with reduce motion', (
    WidgetTester tester,
    TestEnv env,
  ) async {
    await _pumpWizard(tester, env);
    await _tap(tester, 'Get started');
    await tester.pumpAndSettle();
    expect(find.text('Your accounts'), findsOneWidget);
    expect(find.text('Set up your accounts'), findsNothing);
  });
}
