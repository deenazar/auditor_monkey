import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_motion.dart';
import '../../../shared/theme/app_radius.dart';
import '../../../shared/theme/app_sizes.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/staggered_entrance.dart';
import '../../../shared/wow/confetti.dart';
import '../../../shared/wow/haptics.dart';
import '../../../shared/wow/long_press_preview.dart';
import '../../../shared/wow/parallax.dart';
import '../../../shared/wow/scene_activity.dart';
import '../../../shared/wow/spring_press.dart';
import '../../../shared/wow/swipe_action_row.dart';
import '../../../shared/wow/tilt_3d.dart';
import '../../../shared/wow/wow_header.dart';
import '../../../shared/wow/wow_sheet.dart';
import '../../demo_data/presentation/demo_data_menu_button.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/mascot_controller.dart';
import '../../mascot/presentation/mascot_moment.dart';

/// Settings (opened from the gear on Home): the living mint header with
/// the Auditor Monkey, then rows for demo data (debug and profile builds),
/// saying hi to the monkey, the motion setting the app follows, open
/// source licences and about. Rows tilt, spring, have haptics, a
/// long-press preview and a swipe-right shortcut.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final MascotController _monkey = MascotController();
  final ScrollOffset _scroll = ScrollOffset();
  final SceneActivity _activity = SceneActivity();

  @override
  void dispose() {
    _monkey.dispose();
    _scroll.dispose();
    _activity.dispose();
    super.dispose();
  }

  void _sayHi() {
    _monkey.react(MascotReaction.win, text: 'Hi! Books look good 📋');
    Confetti.burst(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool reduce = AppMotion.reduceMotion(context);
    final List<_Item> items = <_Item>[
      if (!kReleaseMode)
        _Item(
          icon: LucideIcons.flaskConical,
          title: 'Demo data',
          subtitle: 'Try the app with sample entries',
          detail:
              'Fills a separate demo copy with three months of sample '
              'entries. Your real data is never changed.',
          onTap: () {
            _monkey.react(MascotReaction.hello);
            showWowSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (_) => const DemoDataSheet(),
            );
          },
        ),
      _Item(
        icon: LucideIcons.smile,
        title: 'Say hi to the monkey',
        subtitle: 'It is always happy to see you',
        detail: 'The Auditor Monkey dances and throws confetti.',
        onTap: _sayHi,
      ),
      _Item(
        icon: LucideIcons.sparkles,
        title: 'Motion',
        subtitle: reduce
            ? 'Reduced, as set on your phone'
            : 'Full motion, as set on your phone',
        detail:
            'Auditor Monkey follows the Reduce Motion setting of your '
            'phone. With it on, nothing moves; haptics stay.',
        onTap: () =>
            _monkey.react(reduce ? MascotReaction.sad : MascotReaction.spin),
      ),
      _Item(
        icon: LucideIcons.scrollText,
        title: 'Open-source licences',
        subtitle: 'Fonts and packages we use',
        detail: 'The licences of the fonts and packages in this app.',
        onTap: () => showLicensePage(
          context: context,
          applicationName: 'Auditor Monkey',
        ),
      ),
      _Item(
        icon: LucideIcons.info,
        title: 'About',
        subtitle: 'Auditor Monkey, your personal money tracker',
        detail:
            'Records expenses, income and transfers across your accounts, '
            'works offline and keeps the books in Indian rupees.',
        onTap: () => LongPressPreview.show(context, (_) => const _AboutCard()),
      ),
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Listener(
        onPointerDown: (PointerDownEvent e) {
          _activity.poke();
          _monkey.follow(e.position);
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: _scroll.onScroll,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: WowHeader(
                  eyebrow: 'Auditor Monkey',
                  title: 'Settings',
                  scroll: _scroll,
                  activity: _activity,
                  leading: IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      size: AppSizes.iconNav,
                      color: AppColors.ink,
                    ),
                  ),
                  trailing: MascotMoment(
                    controller: _monkey,
                    reaction: MascotReaction.hello,
                    size: 64,
                    halo: false,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.space3),
                  itemBuilder: (BuildContext context, int i) =>
                      StaggeredEntrance(
                        index: i,
                        child: _Row(item: items[i]),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item {
  const _Item({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String detail;
  final VoidCallback onTap;
}

class _Row extends StatelessWidget {
  const _Row({required this.item});

  final _Item item;

  @override
  Widget build(BuildContext context) {
    return SwipeActionRow(
      id: 'settings-${item.title}',
      start: SwipeAction(
        icon: item.icon,
        label: item.title,
        colour: AppColors.primary,
        onTrigger: item.onTap,
      ),
      child: LongPressPreview(
        preview: (_) => Padding(
          padding: const EdgeInsets.all(AppSpacing.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                item.icon,
                size: AppSizes.iconLarge,
                color: AppColors.primaryDeep,
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(item.title, style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.space2),
              Text(
                item.detail,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
        child: Tilt3D(
          maxDegrees: 5,
          child: SpringPress(
            scale: 0.97,
            semanticLabel: '${item.title}. ${item.subtitle}',
            onTap: () {
              AppHaptics.press();
              item.onTap();
            },
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.tile,
                  borderRadius: AppRadius.card,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Row(
                    children: <Widget>[
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          color: AppColors.navIndicator,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(
                          dimension: AppSizes.iconCircle,
                          child: Icon(
                            item.icon,
                            size: AppSizes.iconInline,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(item.title, style: AppTextStyles.bodyStrong),
                            const SizedBox(height: 2),
                            Text(item.subtitle, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: AppSizes.iconInline,
                        color: AppColors.iconInactive,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.space6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MascotMoment(
            mood: MascotMood.happy,
            reaction: MascotReaction.hello,
            say: 'Nice to meet you!',
            size: 120,
          ),
          SizedBox(height: AppSpacing.space3),
          Text('Auditor Monkey', style: AppTextStyles.title),
          SizedBox(height: AppSpacing.space2),
          Text(
            'Your personal money tracker. Every rupee, every account, '
            'even offline.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
