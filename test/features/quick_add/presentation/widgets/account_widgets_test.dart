import 'package:auditor_monkey/features/quick_add/presentation/widgets/account_picker_sheet.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/account_pill.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/quick_add_view_models.dart';
import 'package:auditor_monkey/features/quick_add/presentation/widgets/transfer_accounts_row.dart';
import 'package:auditor_monkey/shared/theme/app_motion.dart';
import 'package:auditor_monkey/shared/theme/app_sizes.dart';
import 'package:auditor_monkey/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../support/widget_harness.dart';

const AccountOption _sbi = AccountOption(
  id: 'sbi',
  name: 'SBI',
  colourToken: 'accountSbi',
  balancePaise: 12345600,
);
const AccountOption _axis = AccountOption(
  id: 'axis',
  name: 'Axis',
  colourToken: 'accountAxis',
  balancePaise: 100000,
);

/// Opens [AccountPickerSheet] from a button and records the result.
Future<void> _pumpPicker(
  WidgetTester tester,
  List<String?> results, {
  String? disabledId,
}) async {
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
                await AccountPickerSheet.show(
                  context,
                  title: 'To',
                  accounts: const <AccountOption>[_sbi, _axis],
                  selectedId: 'sbi',
                  disabledId: disabledId,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('AccountPill', () {
    testWidgets('shows the name with a chevron and reports taps', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpCompact(
        tester,
        AccountPill(account: _sbi, onTap: () => taps++),
      );
      expect(find.text('SBI'), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronDown), findsOneWidget);
      expect(find.bySemanticsLabel('SBI'), findsOneWidget);
      await tester.tap(find.text('SBI'));
      expect(taps, 1);
      expect(
        tester.getSize(find.bySemanticsLabel('SBI')).height,
        greaterThanOrEqualTo(AppSizes.chipHeight),
      );
    });

    testWidgets('no account shows the placeholder', (
      WidgetTester tester,
    ) async {
      await pumpCompact(
        tester,
        AccountPill(account: null, onTap: () {}, placeholder: 'Pick account'),
      );
      expect(find.text('Pick account'), findsOneWidget);
      expect(find.bySemanticsLabel('Pick account'), findsOneWidget);
    });

    testWidgets('transfer pill shows the balance and reads it out', (
      WidgetTester tester,
    ) async {
      await pumpCompact(
        tester,
        AccountPill(
          account: _sbi,
          onTap: () {},
          showBalance: true,
          showChevron: false,
        ),
      );
      expect(
        find.bySemanticsLabel('SBI, balance ₹1,23,456.00'),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.chevronDown), findsNothing);
    });

    testWidgets('text scale 2.0: long names are cut, nothing overflows', (
      WidgetTester tester,
    ) async {
      await pumpCompact(
        tester,
        AccountPill(
          account: const AccountOption(
            id: 'long',
            name: 'A very long bank account name indeed',
            colourToken: 'accountPf',
            balancePaise: 0,
          ),
          onTap: () {},
          showBalance: true,
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('unknown balance', () {
    const AccountOption unknown = AccountOption(
      id: 'u',
      name: 'Loading',
      colourToken: 'accountPf',
    );

    testWidgets('the pill shows no balance text', (WidgetTester tester) async {
      await pumpCompact(
        tester,
        AccountPill(account: unknown, onTap: () {}, showBalance: true),
      );
      expect(find.text('Loading'), findsOneWidget);
      expect(find.textContaining('₹'), findsNothing);
    });
  });

  group('AccountPickerSheet', () {
    testWidgets('rows show name, balance and a check on the selected one', (
      WidgetTester tester,
    ) async {
      final List<String?> results = <String?>[];
      await _pumpPicker(tester, results);
      expect(find.text('SBI'), findsOneWidget);
      expect(find.text('Axis'), findsOneWidget);
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      expect(find.bySemanticsLabel('Axis, balance ₹1,000.00'), findsOneWidget);
    });

    testWidgets('picking a row returns its id', (WidgetTester tester) async {
      final List<String?> results = <String?>[];
      await _pumpPicker(tester, results);
      await tester.tap(find.bySemanticsLabel('Axis, balance ₹1,000.00'));
      await tester.pumpAndSettle();
      expect(results, <String?>['axis']);
    });

    testWidgets('a disabled row cannot be picked and reads as disabled', (
      WidgetTester tester,
    ) async {
      final List<String?> results = <String?>[];
      await _pumpPicker(tester, results, disabledId: 'sbi');
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('SBI, balance ₹1,23,456.00'),
      );
      expect(
        node.flagsCollection.isEnabled.toString(),
        isNot(contains('true')),
      );
      await tester.tap(find.bySemanticsLabel('SBI, balance ₹1,23,456.00'));
      await tester.pumpAndSettle();
      expect(results, isEmpty);
      expect(find.text('Axis'), findsOneWidget);
    });
  });

  group('TransferAccountsRow', () {
    Future<void> build(
      WidgetTester tester, {
      required VoidCallback onSwap,
      VoidCallback? onPickFrom,
      VoidCallback? onPickTo,
      bool swapEnabled = true,
      bool reduceMotion = false,
    }) => pumpCompact(
      tester,
      TransferAccountsRow(
        from: _sbi,
        to: _axis,
        onPickFrom: onPickFrom ?? () {},
        onPickTo: onPickTo ?? () {},
        onSwap: onSwap,
        swapEnabled: swapEnabled,
      ),
      reduceMotion: reduceMotion,
    );

    testWidgets('From, swap and To in one row; pills report their taps', (
      WidgetTester tester,
    ) async {
      int from = 0;
      int to = 0;
      await build(
        tester,
        onSwap: () {},
        onPickFrom: () => from++,
        onPickTo: () => to++,
      );
      expect(find.text('FROM'), findsOneWidget);
      expect(find.text('TO'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('SBI, balance ₹1,23,456.00'));
      await tester.tap(find.bySemanticsLabel('Axis, balance ₹1,000.00'));
      expect(from, 1);
      expect(to, 1);
    });

    testWidgets('swap calls back and turns half a turn each time', (
      WidgetTester tester,
    ) async {
      int swaps = 0;
      await build(tester, onSwap: () => swaps++);
      await tester.tap(find.bySemanticsLabel('Swap from and to accounts'));
      await tester.pumpAndSettle();
      expect(swaps, 1);
      expect(
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns,
        0.5,
      );
      await tester.tap(find.bySemanticsLabel('Swap from and to accounts'));
      await tester.pumpAndSettle();
      expect(swaps, 2);
      expect(
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns,
        1,
      );
    });

    testWidgets('swap is inert when disabled', (WidgetTester tester) async {
      int swaps = 0;
      await build(tester, onSwap: () => swaps++, swapEnabled: false);
      await tester.tap(find.bySemanticsLabel('Swap from and to accounts'));
      await tester.pumpAndSettle();
      expect(swaps, 0);
    });

    testWidgets('reduce motion: the swap turn has zero duration', (
      WidgetTester tester,
    ) async {
      await build(tester, onSwap: () {}, reduceMotion: true);
      expect(
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).duration,
        Duration.zero,
      );
      await build(tester, onSwap: () {});
      expect(
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).duration,
        AppMotion.durationMedium,
      );
    });

    testWidgets('text scale 2.0 keeps the row whole', (
      WidgetTester tester,
    ) async {
      await pumpCompact(
        tester,
        TransferAccountsRow(
          from: _sbi,
          to: _axis,
          onPickFrom: () {},
          onPickTo: () {},
          onSwap: () {},
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
