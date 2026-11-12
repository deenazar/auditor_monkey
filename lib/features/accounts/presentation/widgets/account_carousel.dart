import 'package:flutter/material.dart';

import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';

/// Lets a screen move the carousel (for example when a row is tapped) and
/// read the current page.
class AccountCarouselController {
  _AccountCarouselState? _state;

  /// Current card index (0 when not attached yet).
  int get page => _state?._page ?? 0;

  /// Scrolls to card [index] with the spring snap (jumps with reduce
  /// motion).
  Future<void> animateTo(int index) async => _state?._animateTo(index);
}

/// Horizontal carousel of account cards.
///
/// The current card fills the content width (side padding
/// `screenPadding`); the next card peeks in `carouselPeek` from the right
/// edge. Pages snap with a soft spring (damping ratio about 0.8), settling
/// in about `durationSlow`. With reduce motion the snap does not bounce and
/// programmatic moves jump.
///
/// Give the carousel the full screen width (no outer side padding). Its
/// height is `accountCardHeight`; [itemBuilder] draws one card that fills
/// the space it gets.
class AccountCarousel extends StatefulWidget {
  const AccountCarousel({
    required this.itemCount,
    required this.itemBuilder,
    this.initialPage = 0,
    this.onPageChanged,
    this.controller,
    super.key,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int initialPage;

  /// Called when a different card becomes the current one.
  final ValueChanged<int>? onPageChanged;
  final AccountCarouselController? controller;

  @override
  State<AccountCarousel> createState() => _AccountCarouselState();
}

class _AccountCarouselState extends State<AccountCarousel> {
  PageController? _pages;
  double _fraction = 0;
  late int _page = _clamp(widget.initialPage);

  int _clamp(int i) =>
      widget.itemCount <= 0 ? 0 : i.clamp(0, widget.itemCount - 1);

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(AccountCarousel old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?._state = null;
      widget.controller?._state = this;
    }
    // Fewer cards than before: stay on a card that exists.
    final int fixed = _clamp(_page);
    if (fixed != _page) {
      _page = fixed;
      final PageController? c = _pages;
      if (c != null && c.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && c.hasClients) c.jumpToPage(fixed);
        });
      }
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller?._state = null;
    _pages?.dispose();
    super.dispose();
  }

  /// The pager is as wide as the screen minus the left padding. A page is
  /// one card plus its gap, so the next card starts `carouselPeek` before
  /// the right edge.
  PageController _controllerFor(double width) {
    final double viewport = width - AppSpacing.screenPadding;
    final double extent =
        width - AppSpacing.screenPadding - AppSizes.carouselPeek;
    final double fraction = extent / viewport;
    if (_pages == null || fraction != _fraction) {
      _pages?.dispose();
      _fraction = fraction;
      _pages = PageController(initialPage: _page, viewportFraction: fraction);
    }
    return _pages!;
  }

  Future<void> _animateTo(int index) async {
    final PageController? c = _pages;
    if (c == null || !c.hasClients) return;
    final int target = _clamp(index);
    if (AppMotion.reduceMotion(context)) {
      c.jumpToPage(target);
      return;
    }
    await c.animateToPage(
      target,
      duration: AppMotion.durationSlow,
      curve: AppMotion.curveSpring,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool reduce = AppMotion.reduceMotion(context);
    return SizedBox(
      height: AppSizes.accountCardHeight,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          final PageController controller = _controllerFor(box.maxWidth);
          return Padding(
            padding: const EdgeInsets.only(left: AppSpacing.screenPadding),
            child: PageView.builder(
              controller: controller,
              padEnds: false,
              clipBehavior: Clip.none,
              physics: _SpringPagePhysics(reduceMotion: reduce),
              itemCount: widget.itemCount,
              onPageChanged: (int index) {
                _page = index;
                widget.onPageChanged?.call(index);
              },
              itemBuilder: (BuildContext context, int index) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.space2),
                child: widget.itemBuilder(context, index),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Page snapping with a soft spring: damping ratio 0.8, stiffness 200 (a
/// little overshoot). With reduce motion the spring is critically damped,
/// so the card settles without bouncing.
class _SpringPagePhysics extends PageScrollPhysics {
  const _SpringPagePhysics({required this.reduceMotion, super.parent});

  final bool reduceMotion;

  @override
  _SpringPagePhysics applyTo(ScrollPhysics? ancestor) => _SpringPagePhysics(
    reduceMotion: reduceMotion,
    parent: buildParent(ancestor),
  );

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: AppMotion.springStiffness,
    ratio: reduceMotion ? 1 : AppMotion.springDampingRatio,
  );
}
