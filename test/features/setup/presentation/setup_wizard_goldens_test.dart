@Tags(<String>['golden'])
library;

import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/accounts/presentation/widgets/account_form_sheet.dart';
import 'package:auditor_monkey/features/setup/application/setup_wizard_state.dart';
import 'package:auditor_monkey/features/setup/domain/account_presets.dart';
import 'package:auditor_monkey/features/setup/presentation/setup_wizard_screen.dart';
import 'package:auditor_monkey/features/setup/presentation/start_screen.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/account_fixtures.dart';
import '../../../support/golden.dart';
import '../../../support/rupee_golden.dart';

String _presetId(String name) =>
    accountPresets.firstWhere((AccountPreset p) => p.name == name).id;

/// Wizard state with the seven presets, a custom card with a debt and
/// (optionally) a bad amount, for the balances step.
List<WizardAccount> _balanceAccounts({bool badAmount = false}) {
  final List<WizardAccount> list = presetWizardAccounts(
    amounts: <String, String>{
      _presetId('Hand'): '12.5',
      _presetId('SBI'): '1,23,456.50',
      _presetId('Axis'): '4,500',
      _presetId('SCB'): badAmount ? 'abc' : '38,210',
      _presetId('Food Card'): '640',
      _presetId('Outside'): '12,000',
      _presetId('PF'): '4,80,000',
    },
  );
  return <WizardAccount>[
    ...list,
    const WizardAccount(
      key: 'custom-1',
      name: 'Visa Card',
      type: AccountType.card,
      colour: 'accountOutside',
      balanceText: '4,500',
      owes: true,
    ),
  ];
}

SetupWizardState _state(
  WizardStep step, {
  List<WizardAccount>? accounts,
  WizardSaveStatus saveStatus = WizardSaveStatus.idle,
  String? saveError,
}) => SetupWizardState(
  step: step,
  accounts: accounts ?? presetWizardAccounts(),
  saveStatus: saveStatus,
  saveError: saveError,
);

void main() {
  testWidgets('golden: wizard_welcome', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      const SetupWizardScreen(),
      'wizard_welcome',
      overrides: <Override>[wizardStateOverride(_state(WizardStep.welcome))],
    );
  });

  testWidgets('golden: wizard_done', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      const SetupWizardScreen(),
      'wizard_done',
      overrides: <Override>[wizardStateOverride(_state(WizardStep.review))],
    );
  });

  testWidgets('golden: wizard_pick', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      const SetupWizardScreen(),
      'wizard_pick',
      overrides: <Override>[wizardStateOverride(_state(WizardStep.pick))],
    );
  });

  testWidgets('golden: wizard_pick_add_sheet', (WidgetTester tester) async {
    setGoldenSurface(tester);
    await tester.pumpWidget(
      rupeeGoldenApp(
        const SetupWizardScreen(),
        overrides: <Override>[wizardStateOverride(_state(WizardStep.pick))],
      ),
    );
    await tester.pumpAndSettle();
    final Finder add = find.bySemanticsLabel('Add another account');
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.byType(AccountFormSheet), findsOneWidget);
    await expectGolden(tester, 'wizard_pick_add_sheet');
  });

  testWidgets('golden: wizard_balances', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      const SetupWizardScreen(),
      'wizard_balances',
      overrides: <Override>[
        wizardStateOverride(
          _state(
            WizardStep.balances,
            accounts: _balanceAccounts(badAmount: true),
          ),
        ),
      ],
    );
  });

  testWidgets('golden: wizard_balances_owes', (WidgetTester tester) async {
    // The card is first so its "I owe" toggle is on screen without scrolling.
    final List<WizardAccount> all = _balanceAccounts();
    final WizardAccount card = all.last;
    await pumpRupeeGolden(
      tester,
      const SetupWizardScreen(),
      'wizard_balances_owes',
      overrides: <Override>[
        wizardStateOverride(
          _state(
            WizardStep.balances,
            accounts: <WizardAccount>[card, ...all.sublist(0, all.length - 1)],
          ),
        ),
      ],
    );
  });

  testWidgets('golden: wizard_review', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      const SetupWizardScreen(),
      'wizard_review',
      overrides: <Override>[
        wizardStateOverride(
          _state(WizardStep.review, accounts: _balanceAccounts()),
        ),
      ],
    );
  });

  testWidgets('golden: wizard_review_error', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      const SetupWizardScreen(),
      'wizard_review_error',
      overrides: <Override>[
        wizardStateOverride(
          _state(
            WizardStep.review,
            accounts: _balanceAccounts(),
            saveStatus: WizardSaveStatus.failed,
            saveError: 'An account with this name already exists.',
          ),
        ),
      ],
    );
  });

  testWidgets('golden: start_error', (WidgetTester tester) async {
    await pumpRupeeGolden(
      tester,
      StartScreen(error: Object(), onRetry: () {}),
      'start_error',
    );
  });
}
