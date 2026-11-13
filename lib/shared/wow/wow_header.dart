import 'package:flutter/material.dart';

import '../theme/app_depth.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/page_header.dart';
import 'animated_blobs.dart';
import 'parallax.dart';
import 'scene_activity.dart';

/// A living page header like Home's hero, smaller: the mint blob gradient
/// with rounded bottom corners and the centred [PageHeader] (ink on mint).
/// Optional [trailing] (a mascot) sits in the bottom-right corner,
/// [leading] (a back or demo button) top-left, [bottom] under the title.
/// The title moves at `parallaxMid` and fades as the page scrolls.
class WowHeader extends StatelessWidget {
  const WowHeader({
    required this.title,
    this.eyebrow,
    this.trailing,
    this.leading,
    this.bottom,
    this.scroll,
    this.activity,
    super.key,
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;
  final Widget? leading;
  final Widget? bottom;
  final ScrollOffset? scroll;
  final SceneActivity? activity;

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.paddingOf(context).top;
    Widget text = PageHeader(title: title, eyebrow: eyebrow, onMint: true);
    final ScrollOffset? s = scroll;
    if (s != null) {
      text = Parallax(
        offset: s,
        factor: AppDepth.parallaxMid,
        fadeOver: 160,
        child: text,
      );
    }
    return AnimatedBlobs(
      activity: activity,
      borderRadius: AppRadius.hero,
      child: Stack(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              top + AppSpacing.space6,
              AppSpacing.screenPadding,
              AppSpacing.space6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                text,
                if (bottom != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.space4),
                  bottom!,
                ],
              ],
            ),
          ),
          if (leading != null)
            PositionedDirectional(
              start: AppSpacing.space2,
              top: top + AppSpacing.space2,
              child: leading!,
            ),
          if (trailing != null)
            PositionedDirectional(
              end: AppSpacing.space3,
              bottom: AppSpacing.space2,
              child: trailing!,
            ),
        ],
      ),
    );
  }
}
