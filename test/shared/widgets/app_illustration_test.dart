import 'package:auditor_monkey/shared/theme/app_theme.dart';
import 'package:auditor_monkey/shared/widgets/app_illustration.dart';
import 'package:auditor_monkey/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Pumps [child] at a phone size with the given text scale.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size screen = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = screen
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      builder: (BuildContext context, Widget? widget) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: widget!,
      ),
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pump();
}

Size _svgSize(WidgetTester tester) => tester.getSize(find.byType(SvgPicture));

void main() {
  group('AppIllustration.heightFor', () {
    test('empty: 160 on a normal screen, 120 when short or large text', () {
      expect(
        AppIllustration.heightFor(
          size: AppIllustrationSize.empty,
          screenHeight: 844,
          textScale: 1,
        ),
        160,
      );
      expect(
        AppIllustration.heightFor(
          size: AppIllustrationSize.empty,
          screenHeight: 640,
          textScale: 1,
        ),
        120,
      );
      expect(
        AppIllustration.heightFor(
          size: AppIllustrationSize.empty,
          screenHeight: 844,
          textScale: 1.5,
        ),
        120,
      );
    });

    test('wizard: 200 normally, 160 when short or large text', () {
      expect(
        AppIllustration.heightFor(
          size: AppIllustrationSize.wizard,
          screenHeight: 844,
          textScale: 1,
        ),
        200,
      );
      expect(
        AppIllustration.heightFor(
          size: AppIllustrationSize.wizard,
          screenHeight: 699,
          textScale: 1,
        ),
        160,
      );
      expect(
        AppIllustration.heightFor(
          size: AppIllustrationSize.wizard,
          screenHeight: 844,
          textScale: 1.5,
        ),
        160,
      );
    });
  });

  testWidgets('renders at 160pt on a tall phone', (WidgetTester tester) async {
    await _pump(tester, const AppIllustration('empty_accounts'));
    expect(_svgSize(tester).height, 160);
    expect(_svgSize(tester).width, closeTo(160 * 1.2, 0.01));
  });

  testWidgets('renders at 120pt at text scale 1.5', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const AppIllustration('empty_accounts'),
      textScale: 1.5,
    );
    expect(_svgSize(tester).height, 120);
  });

  testWidgets('wizard size renders at 200pt, then 160pt when short', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const AppIllustration('wizard_welcome', size: AppIllustrationSize.wizard),
    );
    expect(_svgSize(tester).height, 200);

    await _pump(
      tester,
      const AppIllustration('wizard_welcome', size: AppIllustrationSize.wizard),
      screen: const Size(390, 640),
    );
    expect(_svgSize(tester).height, 160);
  });

  testWidgets('is excluded from semantics', (WidgetTester tester) async {
    await _pump(tester, const AppIllustration('error_generic'));
    expect(
      find.ancestor(
        of: find.byType(SvgPicture),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
  });

  testWidgets('EmptyState shows the illustration instead of the icon', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const EmptyState(
        illustration: 'empty_accounts',
        icon: LucideIcons.wallet,
        title: 'No accounts yet',
        message: 'Set up your accounts.',
      ),
    );
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byIcon(LucideIcons.wallet), findsNothing);
    expect(find.text('No accounts yet'), findsOneWidget);
  });

  testWidgets('EmptyState keeps the icon when no illustration is set', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const EmptyState(
        icon: LucideIcons.wallet,
        title: 'No accounts yet',
        message: 'Set up your accounts.',
      ),
    );
    expect(find.byType(SvgPicture), findsNothing);
    expect(find.byIcon(LucideIcons.wallet), findsOneWidget);
  });
}
