# Database

Local database: SQLite through Drift. This is the source of truth; the
cloud copy comes later (session 9). Code lives in `lib/core/database/`.

- **Schema version: 1** (all 8 tables).
- File: `auditor_monkey.sqlite` in the app documents folder. It is opened
  in ONE place only: `lib/core/database/connection/open_connection.dart`.
  Session 8 changes that one file to add SQLCipher encryption and will
  convert the existing data, never wipe it.
- Foreign keys are switched on every time the database opens.

## Rules for every table
- `id`: UUID v4 text, made in Dart.
- `created_at`, `updated_at`: UTC time as whole milliseconds. `updated_at`
  is never before `created_at`.
- `deleted_at`: empty (NULL) while the row is live. Deleting only sets
  this. Nothing is ever removed from the file.
- `sync_status`: `pending` or `synced`. Every local write (add, change,
  delete, restore) sets `updated_at` to now and `sync_status` to `pending`.
- All writes go through the repositories in `lib/features/*/data/`.
  Never write to the database from a screen.
- Money is a whole number of paise. There are no decimal columns.
  Amounts are always above zero; the type decides the direction.
- Enums are stored as lower case text with a CHECK rule. Calendar dates
  are text `YYYY-MM-DD` (local date). Months are text `YYYY-MM`.
- Foreign keys are real (`ON DELETE RESTRICT`, checked at commit).
- The CHECK rules in the database are a backup. The repositories check
  first and return a clear error (`ValidationFailure`, `DuplicateFailure`,
  `InUseFailure`, `NotFoundFailure`, `OverflowFailure`, `StorageFailure`).

## Tables
| Table | What it holds | Main rules |
|-------|---------------|------------|
| `accounts` | Hand, SBI, Axis, PF... | name 1-40 characters, unique among live rows (ignoring case). Type: cash, bank, card, wallet, pf, other. Colour is a DESIGN.md token name. Opening balance may be negative only for `card`. |
| `categories` | Expense and income categories | name 1-40, unique per kind among live rows. Kind: expense or income. 34 are created on first run (26 expense, 8 income) with fixed ids. |
| `transactions` | Expense, income, transfer | amount above 0 and at most 1e14 paise. Transfer: needs a different `to_account_id`, no category, no loan. Expense or income: needs a category of the same kind, no `to_account_id`. Note up to 200 characters. `loan_id` links a loan payment. |
| `budgets` | Monthly limit per expense category | one live budget per category and month. Amount above 0. |
| `loans` | Money lent or borrowed | person 1-60, principal above 0, due date not before start date. |
| `gold_holdings` | Gold owned | weight in milligrams (1 to 100,000,000), purity 24k / 22k / 18k, price 0 or more. The account is information only; it creates no transaction. |
| `gold_rates` | Price per gram per day | one live rate per date and purity. Rate above 0, at most Rs 1 crore per gram. |
| `daily_activities` | Simple daily log | title 1-80, note up to 1000. |

Archived accounts and categories can still be used in new entries and
still count in balances; the screens decide whether to offer them.

Deleting an account, category or loan that live rows still use is refused.
Deleting a category also deletes its live budgets. Restoring a row checks
the same rules again (for example, a name that is taken now).

## Balance rule
Balances are never stored. They are calculated by one SQL query:

```
balance = opening balance
        + income
        - expense
        - transfers out
        + transfers in
```
Only live rows count. Transfers change two accounts and leave net worth
the same. Loan-linked entries count in balances.

Spending sums (month spent, budgets, top categories) count only
`type = expense` rows with no `loan_id`. Transfers are never counted.
Income sums also leave out loan-linked rows.

## Loans
- Lent: giving the money is an expense with `loan_id`; a repayment is an
  income with `loan_id`.
- Borrowed: receiving the money is an income with `loan_id`; a repayment
  is an expense with `loan_id`.
- Outstanding = principal - repayments (live rows only), worked out in SQL.
  New repayments may go over the principal (overpaid): outstanding then
  shows below zero. This is allowed on purpose.
- Several disbursements on one loan are allowed.
- A loan entry must be an expense or income, with a category of the same
  kind. Transfers can never be linked to a loan.
- A closed loan takes no new links: creating an entry for it, setting or
  changing `loan_id` on an entry, or restoring a linked entry is refused.
  Entries already linked can still be edited. Reopen the loan to add more.
- Changing lent / borrowed is refused while the loan has live entries.
- The principal cannot be lowered below what was repaid so far.
- A loan with live linked entries cannot be deleted (close it instead).

## Gold value
Current value of a holding =
`(weight_mg * latest live rate_per_gram of the same purity + 500) / 1000`
in whole-number maths (rounds half up). "Latest" means the newest rate by
date, future dates included. No rate yet means no value.

## Speed
Indexes cover balances (`ix_tx_account`, `ix_tx_to_account`), list paging
(`ix_tx_date`), category sums (`ix_tx_category_date`) and loans
(`ix_tx_loan`), and gold by account (`ix_gold_holdings_account`). The list uses keyset paging (no OFFSET). A test checks the
query plans and records timings with 20,000 rows.

## Session 3 queries (accounts and setup wizard)
**No schema change in session 3 (still schema v1).** Only new queries
and repository methods. No new index.

Accounts (`lib/core/database/daos/accounts_dao.dart`,
`lib/features/accounts/data/accounts_repository.dart`):
- `watchHasLive()`: `SELECT EXISTS (... accounts WHERE deleted_at IS
  NULL)`, as a live stream. This is the "setup done" rule (archived
  accounts count). Stops at the first row.
- `getBalance(id)`: one live account with its balance (the session 2
  balance query, filtered to one id). `null` if not found.
- `maxSortOrder()`: largest live `sort_order`, or -1 when none.
- `createAll(drafts, fixedIds)`: 1 to 50 drafts. Every draft is
  validated; names must be unique ignoring case, inside the list and
  against saved accounts. Preset accounts use their fixed ids
  (`lib/features/setup/domain/account_presets.dart`, never change them);
  others get random ids. Sort order continues after `maxSortOrder()`
  (0..n on a fresh database). All rows saved in ONE transaction: all or
  nothing.
- `addAccount(details)`: same checks; random id; goes last in the list.
- `editAccount(id, details)`: changes name, type, colour and opening
  balance only (sort order and archived stay). Same checks, including
  "negative opening only for card". Marks the row `pending`. Balances
  and running balances follow at once because they are calculated.

Transactions (`lib/core/database/daos/transactions_dao.dart`,
`lib/features/transactions/data/transactions_repository.dart`):
- **Statement page** (`statementPage`): the account's live rows, newest
  first (`date`, `created_at`, `id`), keyset paging, default 50 rows
  (max 500). The rows come from two branches joined with `UNION ALL`:
  `account_id = ?` (uses `ix_tx_account`; income +, expense and
  transfer out −) and `to_account_id = ?` (uses `ix_tx_to_account`;
  transfer in +). A window sum
  `opening_balance + SUM(effect) OVER (ORDER BY date, created_at, id)`
  gives the running balance over ALL live rows before the page is cut.
  Category and other-account names come by `LEFT JOIN`. An overflowing
  sum (SQLite turns it into a float) returns `OverflowFailure`. A bad
  or unknown account id returns `NotFoundFailure`.
- `statementThrough(id, count)`: re-reads the first `count` lines (max
  5,000) in one read transaction, for live refresh of loaded pages.
- **Monthly totals per account** (`watchMonthlyTotalsForAccount`):
  income and expense per `YYYY-MM` for one account between two months.
  Leaves out transfers and loan-linked rows (`+loan_id IS NULL` keeps
  SQLite off the weak `ix_tx_loan` index). Empty months are filled with
  0 in Dart.

Timings with 20,000 rows on one account (test mode, recorded only, not
a gate): statement first page 42ms, next page 32ms, monthly totals 6ms.
`test/core/database/query_plan_test.dart` checks the indexes are used.

## Session 4 queries (Quick Add)
**No schema change in session 4 (still schema v1, `schemaVersion` 1).**
No new index, no new table, no prefs. Only read queries. Saves use the
existing `TransactionsRepository.create`; Undo uses `softDelete`.

Code: `lib/core/database/daos/transactions_quick_add_queries.dart` (an
extension on `TransactionsDao`) and
`lib/features/quick_add/data/quick_add_repository.dart`
(`loadHints(today)`, all queries in ONE read transaction).

Rules for all three queries:
- Only live rows dated on or after today − 90 days (`date >= ?`;
  future dates included). This range uses `ix_tx_date`.
- Loan-linked rows are left out (`+loan_id IS NULL`; the unary plus
  keeps SQLite off the weak `ix_tx_loan` index). Quick Add cannot
  create a loan link, so repeating one would drop it.
- "Newest" means entry time: `created_at DESC, id DESC`.

Queries:
- **Last used per type** (run for expense, income, transfer): the newest
  row's `account_id`, `to_account_id`, `category_id`, `LIMIT 1`.
- **Category usage per type** (expense, income): `COUNT(*)` and
  `MAX(created_at)` per category, `GROUP BY +category_id`. The plus sign
  stops SQLite from walking the whole `ix_tx_category_date` index, so it
  uses `ix_tx_date` for the date range.
- **Recent entries** (all types): the newest 50 rows. Dart removes
  repeats and keeps 6.

Dart then leaves out archived or deleted accounts and categories and the
4 loan categories.

Timings with 20,000 rows (test mode, in-memory database; the test
prints p50 / p95 and fails only if p50 is above 250ms):
- Save through `QuickAddNotifier.save()`: p50 about 3.6ms, p95 about
  6ms (target under 100ms).
- Quick Add open data (`quickAddDataProvider`): p50 about 35–38ms, p95
  about 47ms.
`test/core/database/query_plan_test.dart` checks the Quick Add queries
use `ix_tx_date`.

## Change the schema (migration steps)
The version is `schemaVersion` in `lib/core/database/app_database.dart`.
Keep it a plain number. Never edit an old schema dump.

1. Change the table files in `lib/core/database/tables/`.
2. Raise `schemaVersion` by 1.
3. Run `dart run build_runner build`.
4. Run `dart run drift_dev make-migrations`. It writes the new dump
   `drift_schemas/app/drift_schema_vN.json` and, once two versions exist,
   the step helper `lib/core/database/app_database.steps.dart` and the
   generated migration test in `test/drift/app/`.
5. In `onUpgrade` in `app_database.dart`, call the generated
   `stepByStep(...)` and write each `fromXToY` step (add the column or table,
   fill data if needed). Never drop or rewrite user data without a copy.
6. Add a data test for the step in `test/drift/app/` (start from the old
   schema, add rows, migrate, check the rows).
7. Run `dart format .`, `flutter analyze --fatal-infos` and `flutter test`.
8. Commit the dump, the generated files and the tests together. Update
   this file and `docs/DECISIONS.md`.

An app never opens a database that is newer than itself: it logs an error
and stops, and the data is left untouched.

`test/drift/app/schema_dump_guard_test.dart` fails when `schemaVersion`
is raised without a dump for every version 1..schemaVersion.

The test `test/drift/app/migration_test.dart` checks that the code and the
v1 dump match. (`make-migrations` writes its own tests only from version 2.)

## Generated code
`*.g.dart` files are made by `dart run build_runner build` and are
committed. Do not edit them by hand.

## Backup note (Android)
`android:allowBackup="false"` is set in the Android manifest because the
database file is not encrypted until session 8. Revisit it then.
