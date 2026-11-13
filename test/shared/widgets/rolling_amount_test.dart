import 'package:auditor_monkey/core/money/money.dart';
import 'package:auditor_monkey/shared/theme/app_motion.dart';
import 'package:auditor_monkey/shared/widgets/rolling_amount.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

class _Host extends StatefulWidget {
  const _Host({required this.first});

  final int first;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late int paise = widget.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          RollingAmount.text(paise: paise, style: const TextStyle()),
          TextButton(
            onPressed: () => setState(() => paise = 999999),
            child: const Text('go'),
          ),
        ],
      ),
    );
  }
}

String _shown(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byType(RollingAmount),
        matching: find.byType(Text),
      ),
    )
    .data!;

void main() {
  testWidgets('the first build shows the value at once (no roll from 0)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      goldenApp(const _Host(first: 12345600), reduceMotion: false),
    );
    expect(_shown(tester), '₹1,23,456.00');
  });

  testWidgets('rolls through whole-paise steps and ends exactly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      goldenApp(const _Host(first: 100), reduceMotion: false),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(AppMotion.durationSlow ~/ 2);
    final String mid = _shown(tester);
    expect(mid, isNot(formatPaise(100)));
    expect(mid, isNot(formatPaise(999999)));
    // Every step is a real amount with 2 decimals (integer paise).
    expect(RegExp(r'^₹[\d,]+\.\d{2}$').hasMatch(mid), isTrue);
    await tester.pump(AppMotion.durationSlow);
    expect(_shown(tester), formatPaise(999999));
  });

  testWidgets('with reduce motion the new value shows immediately', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(goldenApp(const _Host(first: 100)));
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(_shown(tester), formatPaise(999999));
  });

  testWidgets('large values stay exact at the end', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      goldenApp(const _Host(first: maxPaise), reduceMotion: false),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(AppMotion.durationSlow * 2);
    expect(_shown(tester), formatPaise(999999));
  });

  testWidgets('negative amounts (card debt) work', (WidgetTester tester) async {
    await tester.pumpWidget(goldenApp(const _Host(first: -50000)));
    expect(_shown(tester), '-₹500.00');
  });

  testWidgets('screen readers get one label with the final amount', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      goldenApp(const _Host(first: 12345600), reduceMotion: false),
    );
    expect(find.bySemanticsLabel('₹1,23,456.00'), findsOneWidget);
    handle.dispose();
  });

  group('rollKey (first show per launch)', () {
    testWidgets('rolls from 0 the first time, not the second', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      Widget app(Key k) => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: RollingAmount.text(
              key: k,
              paise: 500000,
              rollKey: 'screen-a',
              style: const TextStyle(),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app(const ValueKey('one')));
      await tester.pump();
      expect(_shown(tester), isNot(formatPaise(500000)));
      await tester.pump(AppMotion.durationSlow * 2);
      expect(_shown(tester), formatPaise(500000));

      // Show the same key again (new widget): no roll from 0.
      await tester.pumpWidget(app(const ValueKey('two')));
      await tester.pump();
      expect(_shown(tester), formatPaise(500000));
    });

    testWidgets('reduce motion shows the final value at once', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        goldenApp(
          Scaffold(
            body: RollingAmount.text(
              paise: 500000,
              rollKey: 'screen-b',
              style: const TextStyle(),
            ),
          ),
        ),
      );
      expect(_shown(tester), formatPaise(500000));
    });

    testWidgets('changes after the first show roll from the old value', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      Widget app(int paise) => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: RollingAmount.text(
              paise: paise,
              rollKey: 'screen-c',
              style: const TextStyle(),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app(100000));
      await tester.pump(AppMotion.durationSlow * 2);
      await tester.pumpWidget(app(200000));
      await tester.pump(AppMotion.durationSlow ~/ 2);
      final String mid = _shown(tester);
      expect(mid, isNot(formatPaise(100000)));
      expect(mid, isNot(formatPaise(200000)));
      // Never dips below the old value (did not restart from 0).
      expect(mid.compareTo('₹1,00,000.00'), isNot(lessThan(0)));
    });
  });
}
