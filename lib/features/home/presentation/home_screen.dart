import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/logger_provider.dart';
import '../../../core/money/money.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/date_labels.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/skeleton_block.dart';
import '../../../shared/widgets/staggered_entrance.dart';
import '../../../shared/wow/confetti.dart';
import '../../../shared/wow/haptics.dart';
import '../../../shared/wow/parallax.dart';
import '../../../shared/wow/scene_activity.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../accounts/domain/account.dart';
import '../../categories/application/categories_providers.dart';
import '../../categories/domain/category.dart';
import '../../mascot/application/mascot_events.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/mascot_controller.dart';
import '../../quick_add/application/quick_add_state.dart';
import '../../transactions/application/transactions_providers.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../transactions/domain/transaction_entry.dart';
import '../application/home_providers.dart';
import '../domain/home_summary.dart';
import 'widgets/goal_banner.dart';
import 'widgets/home_hero.dart';
import 'widgets/home_stat_tiles.dart';
import 'widgets/recent_row.dart';
import 'widgets/summary_card.dart';

/// Home in the reference layout (DESIGN.md "Screen patterns"): the mint
/// hero (greeting, net worth, area chart, Auditor Monkey) → the lime
/// summary card overlapping its bottom edge → stat tiles → "Recent
/// transactions".
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

  /// Rows in "Recent transactions".
  static const int recentCount = 12;

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

  void _onSummary(HomeSummary s) {
    final MascotMood mood = s.mood(0);
    final MascotMood? before = _lastMood;
    _lastMood = mood;
    final int? saved = s.savingsPercent;
    final bool goal = saved != null && saved >= HomeScreen.savingsGoalPercent;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (before != null && before != mood) {
        if (mood == MascotMood.worried) {
          AppHaptics.warning();
          _monkey.react(MascotReaction.sad, text: 'Uh-oh, over the plan 😟');
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
    ref.invalidate(homeSummaryProvider);
    try {
      await ref.read(homeSummaryProvider.future);
    } catch (_) {
      // The error state shows itself.
    }
  }

  Future<void> _delete(TransactionEntry e) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TransactionsRepository repo = ref.read(
      transactionsRepositoryProvider,
    );
    ref.read(loggerProvider).info('home', 'entry deleted by swipe');
    _monkey.react(MascotReaction.del);
    try {
      await repo.softDelete(e.id);
    } catch (error) {
      ref
          .read(loggerProvider)
          .error('home', 'swipe delete failed', error: error);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not delete. Try again.')),
      );
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Entry removed'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              ref.read(loggerProvider).info('home', 'swipe delete undone');
              try {
                await repo.restore(e.id);
              } catch (error) {
                ref
                    .read(loggerProvider)
                    .error('home', 'undo failed', error: error);
              }
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SavedForMascot?>(mascotEventsProvider, _onSaved);
    ref.listen<AsyncValue<HomeSummary>>(homeSummaryProvider, (
      AsyncValue<HomeSummary>? _,
      AsyncValue<HomeSummary> next,
    ) {
      final HomeSummary? s = next.value;
      if (s != null) _onSummary(s);
    });
    final AsyncValue<HomeSummary> summaryAsync = ref.watch(homeSummaryProvider);
    final int? netWorth = ref.watch(netWorthProvider).value;
    final List<Category> categories = <Category>[
      ...?ref.watch(expenseCategoriesProvider).value,
      ...?ref.watch(incomeCategoriesProvider).value,
    ];
    final List<Account> accounts =
        ref.watch(accountsProvider).value ?? const <Account>[];

    if (summaryAsync.hasError && !summaryAsync.hasValue) {
      return ErrorState(
        title: 'Could not load Home',
        message: 'Your data is safe. Try again.',
        onRetry: () => ref.invalidate(homeSummaryProvider),
      );
    }
    final HomeSummary? summary = summaryAsync.value;
    final MascotMood mood = summary?.mood(0) ?? MascotMood.idle;
    final List<RecentRowView> rows = summary == null
        ? const <RecentRowView>[]
        : _rows(summary, categories, accounts);

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
                        child: summary == null
                            ? const SkeletonBlock(height: 92)
                            : SummaryCard(
                                key: _summaryKey,
                                savingsPercent: summary.savingsPercent,
                                monthSpent: summary.monthSpent,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              if (summary != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.space6,
                    AppSpacing.screenPadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: StaggeredEntrance(
                      index: 1,
                      child: HomeStatTiles(
                        days: <int>[
                          for (final DaySpend d in summary.week) d.spent,
                        ],
                        savingsPercent: summary.savingsPercent,
                      ),
                    ),
                  ),
                ),
              if ((summary?.savingsPercent ?? 0) >=
                  HomeScreen.savingsGoalPercent)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.space6,
                    AppSpacing.screenPadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: GoalBanner(
                      percent: summary!.savingsPercent!,
                      goal: HomeScreen.savingsGoalPercent,
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.space8,
                  AppSpacing.screenPadding,
                  AppSpacing.space3,
                ),
                sliver: SliverToBoxAdapter(
                  child: Semantics(
                    header: true,
                    child: const Text(
                      'Recent transactions',
                      style: AppTextStyles.title,
                    ),
                  ),
                ),
              ),
              if (summary == null)
                SliverList.list(
                  children: <Widget>[
                    for (int i = 0; i < 3; i++)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                          vertical: AppSpacing.space2,
                        ),
                        child: SkeletonBlock(height: 52),
                      ),
                  ],
                )
              else if (rows.isEmpty)
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 320,
                    child: EmptyState(
                      illustration: 'empty_home',
                      title: 'No transactions yet',
                      message: 'Tap + to add your first entry.',
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: rows.length,
                  itemBuilder: (BuildContext context, int i) =>
                      StaggeredEntrance(
                        key: ValueKey<String>('row-${rows[i].entry.id}'),
                        index: i + 1,
                        child: RecentRow(
                          view: rows[i],
                          onDelete: () => _delete(rows[i].entry),
                        ),
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

  List<RecentRowView> _rows(
    HomeSummary summary,
    List<Category> categories,
    List<Account> accounts,
  ) {
    final Map<String, Category> cats = <String, Category>{
      for (final Category c in categories) c.id: c,
    };
    final Map<String, String> accs = <String, String>{
      for (final Account a in accounts) a.id: a.name,
    };
    return <RecentRowView>[
      for (final TransactionEntry e in summary.recent.take(
        HomeScreen.recentCount,
      ))
        _view(e, cats, accs, summary.today),
    ];
  }

  RecentRowView _view(
    TransactionEntry e,
    Map<String, Category> cats,
    Map<String, String> accs,
    String today,
  ) {
    final String account = accs[e.accountId] ?? 'Account';
    final String when = e.date == today
        ? 'Today'
        : shortDateLabel(e.date, todayKey: today);
    final String note = (e.note ?? '').trim();
    if (e.type == TransactionType.transfer) {
      return RecentRowView(
        entry: e,
        title: '$account to ${accs[e.toAccountId] ?? 'Account'}',
        account: 'Transfer',
        date: when,
        iconName: '',
        colourGroup: 'other',
      );
    }
    final Category? cat = cats[e.categoryId];
    return RecentRowView(
      entry: e,
      title: cat?.name ?? (note.isNotEmpty ? note : 'Entry'),
      account: account,
      date: when,
      iconName: cat?.icon ?? '',
      colourGroup: e.type == TransactionType.income
          ? 'income'
          : cat?.colourGroup.name ?? 'other',
    );
  }
}
