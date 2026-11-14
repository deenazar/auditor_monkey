import '../seed/default_categories.dart';

/// The one rule that decides which rows are loan money and so never count
/// as spending or income (Session 6, answer Q1). Used by the Dashboard, the
/// Transactions month summary and day totals, top categories, the account
/// chart sums and the day strip.
///
/// Session 7 (budgets) must use it too for any "spent" sum, so a budget's
/// spending matches the Dashboard. No budgets spent sum uses it yet.
///
/// A row is left out when it has a loan link OR its category is one of the 4
/// fixed loan categories (an imported row can have the category without the
/// link). Rows without a category (transfers) stay in the query, then the
/// type test decides.
///
/// `+loan_id` (unary plus) keeps SQLite off the weak `ix_tx_loan` index.
/// The ids are fixed constants checked below, never user input.
///
/// [alias] is the table alias with its dot, e.g. `t.`; empty for none.
String notLoanMoneySql([String alias = '']) =>
    '+${alias}loan_id IS NULL AND '
    '(${alias}category_id IS NULL OR ${alias}category_id NOT IN '
    '($_loanCategoryList))';

final RegExp _uuidShape = RegExp(r'^[0-9a-f-]{36}$');

final String _loanCategoryList = loanCategoryIds
    .map((String id) {
      assert(_uuidShape.hasMatch(id), 'loan category id must be a UUID');
      return "'$id'";
    })
    .join(', ');
