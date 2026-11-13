import 'dart:async';

import 'package:auditor_monkey/features/accounts/presentation/widgets/account_carousel.dart';
import 'package:auditor_monkey/shared/theme/app_motion.dart';
import 'package:auditor_monkey/shared/theme/app_sizes.dart';
import 'package:auditor_monkey/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden.dart';

Widget _carousel({
  int count = 10,
  AccountCarouselController? controller,
  ValueChanged<int>? onPage,
  int initialPage = 0,
}) => Scaffold(
  body: Center(
    child: AccountCarousel(
      itemCount: count,
      controller: controller,
      onPageChanged: onPage,
      initialPage: initialPage,
      itemBuilder: (BuildContext context, int i) => ColoredBox(
        color: Colors.primaries[i % Colors.primaries.length],
        child: Center(child: Text('card $i')),
      ),
    ),
  ),
);

void main() {
  testWidgets('first card has the side padding, the next one peeks 24pt', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(goldenApp(_carousel(), reduceMotion: false));
    await tester.pumpAndSettle();
    final Rect card0 = tester.getRect(
      find
          .ancestor(of: find.text('card 0'), matching: find.byType(ColoredBox))
          .first,
    );
    final Rect card1 = tester.getRect(
      find
          .ancestor(of: find.text('card 1'), matching: find.byType(ColoredBox))
          .first,
    );
    expect(card0.left, AppSpacing.screenPadding);
    expect(card0.height, AppSizes.accountCardHeight);
    // The next card is visible for carouselPeek pixels at the right edge.
    expect(goldenWidth - card1.left, AppSizes.carouselPeek);
    // Gap between cards.
    expect(card1.left - card0.right, AppSpacing.space2);
  });

  testWidgets('swiping moves to the next card and reports the page', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    final List<int> pages = <int>[];
    await tester.pumpWidget(
      goldenApp(_carousel(onPage: pages.add), reduceMotion: false),
    );
    await tester.pumpAndSettle();
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(pages, <int>[1]);
    final Rect card1 = tester.getRect(
      find
          .ancestor(of: find.text('card 1'), matching: find.byType(ColoredBox))
          .first,
    );
    expect(card1.left, AppSpacing.screenPadding);
  });

  testWidgets('controller animates to a card (spring) and reads the page', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    final AccountCarouselController controller = AccountCarouselController();
    await tester.pumpWidget(
      goldenApp(_carousel(controller: controller), reduceMotion: false),
    );
    await tester.pumpAndSettle();
    expect(controller.page, 0);
    final Future<void> done = controller.animateTo(4);
    await tester.pump();
    await tester.pump(AppMotion.durationSlow ~/ 3);
    expect(controller.page, lessThan(5));
    await tester.pumpAndSettle();
    await done;
    expect(controller.page, 4);
    expect(find.text('card 4'), findsOneWidget);
  });

  testWidgets('reduce motion: animateTo jumps at once', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    final AccountCarouselController controller = AccountCarouselController();
    await tester.pumpWidget(goldenApp(_carousel(controller: controller)));
    await tester.pumpAndSettle();
    unawaited(controller.animateTo(3));
    await tester.pump();
    await tester.pump();
    expect(controller.page, 3);
  });

  testWidgets('starts on initialPage and clamps a page that is too high', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(
      goldenApp(_carousel(count: 3, initialPage: 2), reduceMotion: false),
    );
    await tester.pumpAndSettle();
    expect(find.text('card 2'), findsOneWidget);
    // Fewer cards: stays on a card that exists.
    await tester.pumpWidget(
      goldenApp(_carousel(count: 2, initialPage: 2), reduceMotion: false),
    );
    await tester.pumpAndSettle();
    expect(find.text('card 1'), findsOneWidget);
  });

  testWidgets('10 cards build lazily (not all at once)', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(goldenApp(_carousel(), reduceMotion: false));
    await tester.pumpAndSettle();
    expect(find.text('card 9'), findsNothing);
  });

  testWidgets('an empty list builds nothing and does not crash', (
    WidgetTester tester,
  ) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(goldenApp(_carousel(count: 0)));
    await tester.pumpAndSettle();
    expect(find.textContaining('card'), findsNothing);
  });
}
