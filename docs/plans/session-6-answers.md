# Session 6: owner answers (plan approved 2026-11-14)

The owner approved docs/plans/session-6-dashboard.md. Open questions take
the plan's proposals:

- Q1: Loan categories (the 4 fixed loan category ids) are left out of
  Spent, Income and Top 3 everywhere, the same as loan-linked rows. One
  shared SQL filter, so the Transactions month summary and the Statement
  chart follow the same rule. Dashboard and Transactions Spent must match.
- Q2: "This month" = the whole calendar month (future-dated rows count).
  Add a second test with today = 2026-10-15 that pins this.
- Q3: Remaining = Budget total − all spending. No budget: "—".
- Q4: Refunds stay income; they do not lower Spent or the category.
- Q5: Net Worth = sum of account balances only (archived and cards in;
  no loans or gold). Future-dated rows count in balances.
- Q6: Recent shows future-dated rows with their date.
- Q7: Keep the existing Spendings / Savings tiles under the new month
  tiles.
- Section 7 low-risk choices: as written.
