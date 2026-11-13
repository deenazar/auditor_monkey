import 'package:flutter/material.dart';

import '../../features/mascot/domain/mascot_mood.dart';
import '../../features/mascot/presentation/mascot_moment.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../wow/parallax.dart';
import '../wow/scene_activity.dart';
import '../wow/wow_header.dart';
import 'app_illustration.dart';
import 'staggered_entrance.dart';

/// A tab that is not built yet (Insights, Transactions): the living mint
/// header with the page title and a small Auditor Monkey, then an
/// illustration and a short message that enter one after another.
class PlaceholderView extends StatefulWidget {
  const PlaceholderView({
    required this.eyebrow,
    required this.title,
    required this.message,
    this.illustration,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String message;

  /// Name of an `assets/illustrations` file, shown above [message].
  final String? illustration;

  @override
  State<PlaceholderView> createState() => _PlaceholderViewState();
}

class _PlaceholderViewState extends State<PlaceholderView> {
  final ScrollOffset _scroll = ScrollOffset();
  final SceneActivity _activity = SceneActivity();

  @override
  void dispose() {
    _scroll.dispose();
    _activity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _activity.poke(),
      child: NotificationListener<ScrollNotification>(
        onNotification: _scroll.onScroll,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: WowHeader(
                eyebrow: widget.eyebrow,
                title: widget.title,
                scroll: _scroll,
                activity: _activity,
                trailing: const MascotMoment(
                  reaction: MascotReaction.hello,
                  size: 64,
                  halo: false,
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (widget.illustration != null) ...<Widget>[
                        StaggeredEntrance(
                          index: 0,
                          child: AppIllustration(widget.illustration!),
                        ),
                        const SizedBox(height: AppSpacing.space3),
                      ],
                      StaggeredEntrance(
                        index: 1,
                        child: Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
