import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/budgets/domain/budget.dart';
import 'package:auditor_monkey/features/categories/domain/category.dart';
import 'package:auditor_monkey/features/daily_activities/domain/daily_activity.dart';
import 'package:auditor_monkey/features/gold/domain/gold.dart';
import 'package:auditor_monkey/features/loans/domain/loan.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';

const String day = '2026-11-12';

AccountDraft accountDraft({
  String name = 'SBI',
  AccountType type = AccountType.bank,
  int opening = 0,
}) => AccountDraft(
  name: name,
  type: type,
  colour: 'accountSbi',
  openingBalance: opening,
);

CategoryDraft categoryDraft({
  String name = 'Pets',
  CategoryKind kind = CategoryKind.expense,
}) => CategoryDraft(
  name: name,
  kind: kind,
  colourGroup: kind == CategoryKind.income
      ? CategoryColourGroup.income
      : CategoryColourGroup.other,
  icon: 'paw-print',
);

TransactionDraft expenseDraft({
  required String accountId,
  required String categoryId,
  int amount = 10000,
  String date = day,
  String? loanId,
  String? note,
}) => TransactionDraft(
  type: TransactionType.expense,
  amount: amount,
  date: date,
  accountId: accountId,
  categoryId: categoryId,
  loanId: loanId,
  note: note,
);

TransactionDraft incomeDraft({
  required String accountId,
  required String categoryId,
  int amount = 10000,
  String date = day,
  String? loanId,
}) => TransactionDraft(
  type: TransactionType.income,
  amount: amount,
  date: date,
  accountId: accountId,
  categoryId: categoryId,
  loanId: loanId,
);

TransactionDraft transferDraft({
  required String from,
  required String to,
  int amount = 10000,
  String date = day,
}) => TransactionDraft(
  type: TransactionType.transfer,
  amount: amount,
  date: date,
  accountId: from,
  toAccountId: to,
);

LoanDraft loanDraft({
  LoanDirection direction = LoanDirection.lent,
  int principal = 100000,
  String person = 'Ravi',
}) => LoanDraft(
  direction: direction,
  person: person,
  principal: principal,
  startDate: '2026-10-01',
);

GoldHoldingDraft goldHoldingDraft({
  int weightMg = 10000,
  GoldPurity purity = GoldPurity.k22,
  String? accountId,
}) => GoldHoldingDraft(
  description: 'Chain',
  weightMg: weightMg,
  purity: purity,
  purchaseDate: '2025-05-01',
  purchasePrice: 5000000,
  accountId: accountId,
);

GoldRateDraft goldRateDraft({
  String date = day,
  GoldPurity purity = GoldPurity.k22,
  int rate = 700000,
}) => GoldRateDraft(date: date, purity: purity, ratePerGram: rate);

BudgetDraft budgetDraft({
  required String categoryId,
  String month = '2026-11',
  int amount = 300000,
}) => BudgetDraft(categoryId: categoryId, month: month, amount: amount);

DailyActivityDraft activityDraft({String title = 'Paid milk bill'}) =>
    DailyActivityDraft(date: day, title: title);
