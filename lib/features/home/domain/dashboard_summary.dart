import '../../mascot/domain/mascot_mood.dart';
import '../../transactions/domain/transaction_entry.dart';
import 'home_summary.dart';
import 'top_categories.dart';

/// Everything the Dashboard (Home tab) reads about the current month, from
/// ONE read transaction, so all numbers agree. Money is integer paise.
///
/// Rules: Session 6 plan, section 2 (and the owner's answers). Spent and
/// income are for the whole calendar month [month] (future-dated entries
/// count), leave out transfers, loan-linked rows and the loan categories.
class DashboardSummary {
  const DashboardSummary({
    required this.today,
    required this.month,
    required this.days,
    required this.spent,
    required this.income,
    required this.budgetTotal,
    required this.topCategories,
    required this.recent,
  });

  /// `YYYY-MM-DD`, the phone's local date when read.
  final String today;

  /// `YYYY-MM` of [today].
  final String month;

  /// The last [HomeSummary.stripDays] days, oldest first (last = [today]).
  final List<DaySpend> days;

  /// This Month Spent (paise).
  final int spent;

  /// This month's income (paise). Refunds count here, not against [spent].
  final int income;

  /// Sum of this month's live budgets (0 = no budget yet).
  final int budgetTotal;

  /// At most 3, biggest first, each with its half-up percent of [spent].
  final List<TopCategoryShare> topCategories;

  /// Newest live entries of all types (default 5), future dates included.
  final List<TransactionEntry> recent;

  bool get hasBudget => budgetTotal > 0;

  /// Budget minus all spending. Null without a budget (show "-").
  /// Negative when over budget.
  int? get remaining => hasBudget ? budgetTotal - spent : null;

  bool get isOverBudget => hasBudget && spent > budgetTotal;

  /// No entries counted this month (spent and income are both 0).
  bool get isEmptyMonth => spent == 0 && income == 0;

  /// The same numbers in the shape the existing Home widgets use.
  HomeSummary toHomeSummary() => HomeSummary(
    today: today,
    days: days,
    monthSpent: spent,
    monthIncome: income,
    recent: recent,
  );

  /// The monkey's mood from the real budget total (plan = budget if there
  /// is one, else income).
  MascotMood get mood => toHomeSummary().mood(budgetTotal);

  BudgetState get budgetState => toHomeSummary().budgetState(budgetTotal);
}
