import 'package:auditor_monkey/features/quick_add/presentation/widgets/note_sheet.dart';
import 'package:auditor_monkey/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/widget_harness.dart';

void main() {
  group('NotePill', () {
    testWidgets('empty note reads "Add note"; a note shows its first words', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpCompact(tester, NotePill(note: null, onTap: () => taps++));
      expect(find.text('Add note'), findsOneWidget);
      await tester.tap(find.text('Add note'));
      expect(taps, 1);

      expect(
        NotePill.previewOf('Pick up the rent cheque from the office'),
        'Pick up the…',
      );
      expect(NotePill.previewOf('  rent   cheque  '), 'rent cheque');
      await pumpCompact(tester, NotePill(note: 'Rent cheque', onTap: () {}));
      expect(find.text('Rent cheque'), findsOneWidget);
      expect(find.bySemanticsLabel('Note: Rent cheque'), findsOneWidget);
    });
  });

  group('NoteSheet', () {
    Future<void> pumpSheet(
      WidgetTester tester, {
      String initial = '',
      required ValueChanged<String> onDone,
    }) => pumpThemed(
      tester,
      NoteSheet(initialNote: initial, onDone: onDone),
      height: null,
    );

    testWidgets('Done returns the trimmed note', (WidgetTester tester) async {
      final List<String> done = <String>[];
      await pumpSheet(tester, onDone: done.add);
      await tester.enterText(find.byType(TextField), '  Lunch with Asha  ');
      await tester.tap(find.text('Done'));
      await tester.pump();
      expect(done, <String>['Lunch with Asha']);
    });

    testWidgets('keyboard done also returns the note', (
      WidgetTester tester,
    ) async {
      final List<String> done = <String>[];
      await pumpSheet(tester, initial: 'Taxi', onDone: done.add);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(done, <String>['Taxi']);
    });

    testWidgets('control characters are dropped as typed', (
      WidgetTester tester,
    ) async {
      final List<String> done = <String>[];
      await pumpSheet(tester, onDone: done.add);
      await tester.enterText(find.byType(TextField), 'a\tb\nc');
      await tester.tap(find.text('Done'));
      await tester.pump();
      expect(done, <String>['abc']);
    });

    testWidgets('counter shows from 180 and the text stops at 200', (
      WidgetTester tester,
    ) async {
      await pumpSheet(tester, onDone: (String _) {});
      await tester.enterText(find.byType(TextField), 'x' * 179);
      await tester.pump();
      expect(find.text('179/200'), findsNothing);

      await tester.enterText(find.byType(TextField), 'x' * 180);
      await tester.pump();
      expect(find.text('180/200'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'y' * 250);
      await tester.pump();
      final TextField field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text.length, 200);
      expect(find.text('200/200'), findsOneWidget);
    });

    testWidgets('text scale 2.0 keeps the sheet whole', (
      WidgetTester tester,
    ) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: NoteSheet(initialNote: 'Note', onDone: (String _) {}),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
