import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/logging/logger_provider.dart';
import '../../../core/money/money.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/date_labels.dart';
import '../../../shared/scene/sky_phase.dart';
import '../../../shared/scene/sky_scene.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/error_state.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../accounts/domain/account.dart';
import '../../categories/application/categories_providers.dart';
import '../../categories/domain/category.dart';
import '../../mascot/application/mascot_events.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/mascot_controller.dart';
import '../../quick_add/application/quick_add_state.dart';
import '../../transactions/domain/transaction_entry.dart';
import '../application/home_providers.dart';
import '../domain/home_summary.dart';
import 'widgets/home_entry_row.dart';
import 'widgets/home_panel.dart';
import 'widgets/home_stage.dart';

/// Home, in mini_checklist's layout: an illustrated sky on top (date,
/// glass buttons, the Auditor Monkey beside the week's spending bars, stat
/// chips) and a panel that slides over it with a date strip and the latest
/// entries. The monkey hops when an entry is added, worries when the month
/// goes over plan, smiles when under, and sleeps late at night.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MascotController _monkey = MascotController();
  final SceneActivity _activity = SceneActivity();
  final ValueNotifier<double> _collapse = ValueNotifier<double>(0);
  String? _selected;
  Timer? _skyTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _now = _readNow();
    // The sky follows the clock; check every five minutes.
    _skyTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) setState(() => _now = _readNow());
    });
  }

  DateTime _readNow() =>
      DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs());

  @override
  void dispose() {
    _skyTimer?.cancel();
    _monkey.dispose();
    _activity.dispose();
    _collapse.dispose();
    super.dispose();
  }

  void _pick(String date) {
    final String? next = _selected == date ? null : date;
    ref.read(loggerProvider).debug('home', 'day picked');
    setState(() => _selected = next);
    _monkey.look(const Offset(1, 0.3));
  }

  void _poke() {
    _activity.poke();
    _monkey.poke();
  }

  void _onSaved(SavedForMascot? previous, SavedForMascot? next) {
    if (next == null || next.serial == previous?.serial) return;
    final SavedEntry e = next.entry;
    final String amount = formatPaise(e.amount);
    _poke();
    _monkey.react(
      MascotReaction.add,
      text: switch (e.type) {
        TransactionType.expense => 'Logged $amount ✍️',
        TransactionType.income => 'Nice! $amount in 💰',
        TransactionType.transfer => 'Moved $amount ⇄',
      },
    );
  }

  void _onMoodChange(MascotMood? before, MascotMood after) {
    if (before == null || before == after) return;
    if (after == MascotMood.worried) {
      _monkey.react(MascotReaction.sad, text: 'Uh-oh, over the plan 😟');
    } else if (before == MascotMood.worried) {
      _monkey.react(MascotReaction.hello, text: 'Back on track 🎉');
    }
  }

  MascotMood? _lastMood;

  @override
  Widget build(BuildContext context) {
    ref.listen<SavedForMascot?>(mascotEventsProvider, _onSaved);
    final AsyncValue<HomeSummary> summaryAsync = ref.watch(homeSummaryProvider);
    final int budgetTotal = ref.watch(monthBudgetTotalProvider).value ?? 0;
    final List<Category> categories = <Category>[
      ...?ref.watch(expenseCategoriesProvider).value,
      ...?ref.watch(incomeCategoriesProvider).value,
    ];
    final List<Account> accounts =
        ref.watch(accountsProvider).value ?? const <Account>[];

    if (summaryAsync.hasError && !summaryAsync.hasValue) {
      return ColoredBox(
        color: AppColors.panel,
        child: ErrorState(
          title: 'Could not load Home',
          message: 'Your data is safe. Try again.',
          onRetry: () => ref.invalidate(homeSummaryProvider),
        ),
      );
    }
    final HomeSummary summary = summaryAsync.value ?? _emptySummary();
    final MascotMood mood = summaryAsync.hasValue
        ? summary.mood(budgetTotal)
        : MascotMood.idle;
    if (summaryAsync.hasValue) {
      final MascotMood? before = _lastMood;
      _lastMood = mood;
      if (before != mood) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => mounted ? _onMoodChange(before, mood) : null,
        );
      }
    }
    final SkyPhase phase = SkyPhase.at(_now);
    final List<HomeEntryView> rows = _rows(summary, categories, accounts);

    return Listener(
      onPointerDown: (_) => _poke(),
      behavior: HitTestBehavior.translucent,
      child: ColoredBox(
        color: AppColors.panel,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final double padTop = MediaQuery.paddingOf(context).top;
            final double stageH =
                padTop + (c.maxHeight * 0.42).clamp(250.0, 360.0);
            final double initial = ((c.maxHeight - stageH + 22) / c.maxHeight)
                .clamp(0.2, 0.9);
            final double max = ((c.maxHeight - padTop - 64) / c.maxHeight)
                .clamp(initial, 1.0);
            return Stack(
              children: <Widget>[
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: stageH,
                  child: HomeStage(
                    summary: summary,
                    budgetTotal: budgetTotal,
                    selected: _selected,
                    phase: phase,
                    sleepyHour: isSleepyHour(_now),
                    mood: mood,
                    monkey: _monkey,
                    activity: _activity,
                    collapse: _collapse,
                    onPick: _pick,
                    onClearPick: () => setState(() => _selected = null),
                    onAccounts: () => context.go(AppRoutes.accounts),
                  ),
                ),
                NotificationListener<DraggableScrollableNotification>(
                  onNotification: (DraggableScrollableNotification n) {
                    _collapse.value = max <= initial
                        ? 0
                        : ((n.extent - initial) / (max - initial)).clamp(
                            0.0,
                            1.0,
                          );
                    return false;
                  },
                  child: DraggableScrollableSheet(
                    initialChildSize: initial,
                    minChildSize: initial,
                    maxChildSize: max,
                    snap: true,
                    builder: (BuildContext context, ScrollController scroll) =>
                        MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          child: HomePanel(
                            scroll: scroll,
                            summary: summary,
                            budgetTotal: budgetTotal,
                            selected: _selected,
                            rows: rows,
                            onPick: _pick,
                          ),
                        ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  HomeSummary _emptySummary() {
    final String today = dateKey(_now);
    return HomeSummary(
      today: today,
      days: <DaySpend>[
        for (int i = HomeSummary.stripDays - 1; i >= 0; i--)
          DaySpend(date: addDays(today, -i), spent: 0),
      ],
      monthSpent: 0,
      monthIncome: 0,
      recent: const <TransactionEntry>[],
    );
  }

  List<HomeEntryView> _rows(
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
    final String? day = _selected;
    final Iterable<TransactionEntry> entries = day == null
        ? summary.recent.take(HomePanel.recentCount)
        : summary.recent.where((TransactionEntry e) => e.date == day);
    return <HomeEntryView>[
      for (final TransactionEntry e in entries)
        _view(e, cats, accs, summary.today, showDate: day == null),
    ];
  }

  HomeEntryView _view(
    TransactionEntry e,
    Map<String, Category> cats,
    Map<String, String> accs,
    String today, {
    required bool showDate,
  }) {
    final String account = accs[e.accountId] ?? 'Account';
    final String when = e.date == today
        ? 'Today'
        : shortDateLabel(e.date, todayKey: today);
    final String note = (e.note ?? '').trim();
    if (e.type == TransactionType.transfer) {
      final String to = accs[e.toAccountId] ?? 'Account';
      return HomeEntryView(
        entry: e,
        title: '$account › $to',
        meta: <String>[
          if (showDate) when,
          if (note.isNotEmpty) note else 'Transfer',
        ].join(' · '),
        iconName: '',
        colourGroup: 'other',
      );
    }
    final Category? cat = cats[e.categoryId];
    return HomeEntryView(
      entry: e,
      title: cat?.name ?? (note.isNotEmpty ? note : 'Entry'),
      meta: <String>[
        if (showDate) when,
        account,
        if (note.isNotEmpty) note,
      ].join(' · '),
      iconName: cat?.icon ?? '',
      colourGroup: e.type == TransactionType.income
          ? 'income'
          : cat?.colourGroup.name ?? 'other',
    );
  }
}
