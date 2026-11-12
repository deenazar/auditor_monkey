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
  It can go below zero if more than the principal was repaid.

## Gold value
Current value of a holding =
`(weight_mg * latest live rate_per_gram of the same purity + 500) / 1000`
in whole-number maths (rounds half up). No rate yet means no value.

## Speed
Indexes cover balances (`ix_tx_account`, `ix_tx_to_account`), list paging
(`ix_tx_date`), category sums (`ix_tx_category_date`) and loans
(`ix_tx_loan`). The list uses keyset paging (no OFFSET). A test checks the
query plans and records timings with 20,000 rows.

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

The test `test/drift/app/migration_test.dart` checks that the code and the
v1 dump match. (`make-migrations` writes its own tests only from version 2.)

## Generated code
`*.g.dart` files are made by `dart run build_runner build` and are
committed. Do not edit them by hand.
