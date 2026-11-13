import '../../mascot/domain/mascot_mood.dart';
import '../../transactions/domain/transaction_entry.dart';

/// Spending (expenses only, paise) on one calendar day.
class DaySpend {
  const DaySpend({required this.date, required this.spent});

  /// `YYYY-MM-DD`.
  final String date;
  final int spent;
}

/// How this month's spending compares with the plan.
enum BudgetState {
  /// Nothing to compare with yet (no budget and no income).
  none,

  /// Comfortably under.
  under,

  /// At 80% or more of the plan.
  near,

  /// Over the plan.
  over,
}

/// Everything the Home screen shows, read from the database. Transfers are
/// never spending (the repository totals leave them out).
class HomeSummary {
  const HomeSummary({
    required this.today,
    required this.days,
    required this.monthSpent,
    required this.monthIncome,
    required this.recent,
  });

  /// `YYYY-MM-DD`.
  final String today;

  /// The last [stripDays] days, oldest first; the last one is [today].
  final List<DaySpend> days;
  final int monthSpent;
  final int monthIncome;

  /// Newest entries first (at most [recentLimit]).
  final List<TransactionEntry> recent;

  /// Days in the date strip.
  static const int stripDays = 9;

  /// Days in the week bars (the last seven of [days]).
  static const int weekDays = 7;

  /// Entries read for the list.
  static const int recentLimit = 60;

  int get todaySpent => days.isEmpty ? 0 : days.last.spent;

  /// The last seven days (for the week bars).
  List<DaySpend> get week =>
      days.length <= weekDays ? days : days.sublist(days.length - weekDays);

  /// Spending on [date] if it is in the strip, else null.
  int? spentOn(String date) {
    for (final DaySpend d in days) {
      if (d.date == date) return d.spent;
    }
    return null;
  }

  /// The plan for the month: the budget total if there is one, else the
  /// month's income.
  int plan(int budgetTotal) => budgetTotal > 0 ? budgetTotal : monthIncome;

  /// Money left this month against [plan] (can be negative).
  int monthLeft(int budgetTotal) => plan(budgetTotal) - monthSpent;

  /// Share of income kept this month, rounded (null without income).
  int? get savingsPercent => monthIncome <= 0
      ? null
      : (((monthIncome - monthSpent) * 100) / monthIncome).round();

  BudgetState budgetState(int budgetTotal) {
    final int p = plan(budgetTotal);
    if (p <= 0) return monthSpent > 0 ? BudgetState.over : BudgetState.none;
    if (monthSpent > p) return BudgetState.over;
    if (monthSpent * 100 >= p * 80) return BudgetState.near;
    return BudgetState.under;
  }

  /// The monkey's base mood: worried when over, happy when under.
  MascotMood mood(int budgetTotal) => switch (budgetState(budgetTotal)) {
    BudgetState.over => MascotMood.worried,
    BudgetState.under => MascotMood.happy,
    BudgetState.near || BudgetState.none => MascotMood.idle,
  };
}
