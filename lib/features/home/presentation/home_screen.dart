import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/logger_provider.dart';
import '../../../core/money/money.dart';
import '../../../core/utils/clock.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/skeleton_block.dart';
import '../../../shared/widgets/staggered_entrance.dart';
import '../../../shared/wow/confetti.dart';
import '../../../shared/wow/haptics.dart';
import '../../../shared/wow/parallax.dart';
import '../../../shared/wow/scene_activity.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../mascot/application/mascot_events.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/mascot_controller.dart';
import '../../quick_add/application/quick_add_state.dart';
import '../../transactions/domain/transaction_entry.dart';
import '../application/dashboard_providers.dart';
import '../domain/dashboard_summary.dart';
import '../domain/home_summary.dart';
import 'home_actions.dart';
import 'widgets/goal_banner.dart';
import 'widgets/home_hero.dart';
import 'widgets/home_recent_section.dart';
import 'widgets/home_section_error.dart';
import 'widgets/home_sections.dart';
import 'widgets/summary_card.dart';

/// Home = the Dashboard (Session 6): the mint hero (greeting, net worth,
/// area chart, Auditor Monkey) → the lime summary card overlapping its
/// bottom edge → Budget / Remaining / Income tiles → Spendings and Savings
/// tiles → goal banner → "Where your money is" doughnut → "Top spending" →
/// "Recent transactions" (5 rows + See all). Every section loads and fails
/// on its own.
///
/// Motion & 3D: living blob header with parallax, rolling numbers, the
/// chart drawing in, a tilting summary card, swipe-to-delete rows with
/// Undo, long-press previews, pull-to-refresh, and the monkey following
/// your finger and reacting to money events (save → hop, over plan →
/// worried, savings goal reached → confetti).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  /// Savings share that counts as the month's goal (confetti once).
  static const int savingsGoalPercent = 20;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MascotController _monkey = MascotController();
  final SceneActivity _activity = SceneActivity();
  final ScrollOffset _scroll = ScrollOffset();
  final GlobalKey _summaryKey = GlobalKey();
  MascotMood? _lastMood;
  bool _goalCelebrated = false;
  bool _savedSinceOpen = false;

  @override
  void dispose() {
    _monkey.dispose();
    _activity.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _sleepy {
    final int h = DateTime.fromMillisecondsSinceEpoch(
      ref.read(clockProvider).nowMs(),
    ).hour;
    return h >= 23 || h < 5;
  }

  void _onSaved(SavedForMascot? previous, SavedForMascot? next) {
    if (next == null || next.serial == previous?.serial) return;
    _savedSinceOpen = true;
    final SavedEntry e = next.entry;
    final String amount = formatPaise(e.amount);
    _activity.poke();
    _monkey.react(
      MascotReaction.add,
      text: switch (e.type) {
        TransactionType.expense => 'Logged $amount ✍️',
        TransactionType.income => 'Nice! $amount in 💰',
        TransactionType.transfer => 'Moved $amount',
      },
    );
  }

  void _onSummary(DashboardSummary s) {
    final MascotMood mood = s.mood;
    final MascotMood? before = _lastMood;
    _lastMood = mood;
    final int? saved = s.toHomeSummary().savingsPercent;
    final bool goal = saved != null && saved >= HomeScreen.savingsGoalPercent;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (before != null && before != mood) {
        if (mood == MascotMood.worried) {
          AppHaptics.warning();
          _monkey.react(MascotReaction.sad, text: 'Uh-oh, over budget 😟');
        } else if (before == MascotMood.worried) {
          _monkey.react(MascotReaction.hello, text: 'Back on track!');
        }
      }
      // Goal: savings at or above the goal, reached after a save here.
      if (goal && _savedSinceOpen && !_goalCelebrated) {
        _goalCelebrated = true;
        _monkey.react(MascotReaction.win, text: 'Savings goal hit! 🎉');
        Confetti.burst(context, origin: _summaryCentre());
      }
    });
  }

  Offset? _summaryCentre() {
    final RenderObject? box = _summaryKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  Future<void> _refresh() async {
    ref.read(loggerProvider).info('home', 'pull to refresh');
    _monkey.react(MascotReaction.spin);
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(accountBalancesProvider);
    try {
      await ref.read(dashboardSummaryProvider.future);
    } catch (_) {
      // The error state shows itself.
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SavedForMascot?>(mascotEventsProvider, _onSaved);
    ref.listen<AsyncValue<DashboardSummary>>(dashboardSummaryProvider, (
      AsyncValue<DashboardSummary>? _,
      AsyncValue<DashboardSummary> next,
    ) {
      final DashboardSummary? s = next.value;
      if (s != null) _onSummary(s);
    });
    final AsyncValue<DashboardSummary> async = ref.watch(
      dashboardSummaryProvider,
    );
    final DashboardSummary? summary = async.value;
    final int? netWorth = ref.watch(netWorthProvider).value;
    final MascotMood mood = summary?.mood ?? MascotMood.idle;
    final int? savings = summary?.toHomeSummary().savingsPercent;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent e) {
        _activity.poke();
        _monkey.follow(e.position);
      },
      onPointerMove: (PointerMoveEvent e) => _monkey.follow(e.position),
      child: NotificationListener<ScrollNotification>(
        onNotification: _scroll.onScroll,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primaryDeep,
          backgroundColor: AppColors.background,
          edgeOffset: MediaQuery.paddingOf(context).top,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: HomeHero.overlap + 24,
                      ),
                      child: HomeHero(
                        netWorth: netWorth,
                        chart: <int>[
                          for (final DaySpend d
                              in summary?.days ?? const <DaySpend>[])
                            d.spent,
                        ],
                        mood: mood,
                        sleepyHour: _sleepy,
                        monkey: _monkey,
                        activity: _activity,
                        scroll: _scroll,
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.screenPadding + AppSpacing.space4,
                      right: AppSpacing.screenPadding + AppSpacing.space4,
                      bottom: 0,
                      child: StaggeredEntrance(
                        index: 0,
                        child: _summaryCard(async),
                      ),
                    ),
                  ],
                ),
              ),
              _section(
                top: AppSpacing.space6,
                child: MonthTilesSection(summary: async, index: 1),
              ),
              _section(child: StatTilesSection(summary: async, index: 2)),
              if ((savings ?? 0) >= HomeScreen.savingsGoalPercent)
                _section(
                  top: AppSpacing.space6,
                  child: GoalBanner(
                    percent: savings!,
                    goal: HomeScreen.savingsGoalPercent,
                  ),
                ),
              _section(
                top: AppSpacing.space8,
                child: const BalanceSection(index: 3),
              ),
              _section(
                top: AppSpacing.space6,
                child: TopSpendingSection(summary: async, index: 4),
              ),
              SliverToBoxAdapter(
                child: RecentSection(
                  summary: async,
                  firstIndex: 5,
                  onDeleted: () => _monkey.react(MascotReaction.del),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.paddingOf(context).bottom + 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(AsyncValue<DashboardSummary> async) {
    final DashboardSummary? summary = async.value;
    if (summary != null) {
      return SummaryCard(
        key: _summaryKey,
        savingsPercent: summary.toHomeSummary().savingsPercent,
        monthSpent: summary.spent,
        onSpentTap: () =>
            HomeActions(ref, context).openMonthSpending(summary.month),
      );
    }
    if (!async.hasError) return const SkeletonBlock(height: 92);
    return HomeSectionError(
      message: summaryErrorMessage(async, 'Could not load this month.'),
      onRetry: () => ref.invalidate(dashboardSummaryProvider),
    );
  }

  Widget _section({required Widget child, double top = 0}) => SliverPadding(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.screenPadding,
      top,
      AppSpacing.screenPadding,
      0,
    ),
    sliver: SliverToBoxAdapter(child: child),
  );
}
