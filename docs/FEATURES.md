# Features

One section per feature. Status: Planned / In progress / Done.
Details are filled in further when each feature is planned and built.

## 0. Project setup (roadmap session 1)
- **What it does**: The app's base: Flutter project, theme, navigation,
  logger, money formatting, lint and CI. No real features yet.
- **Screens**: Home, Insights, Transactions, Accounts (placeholders with
  page header and empty state); Quick Add (empty bottom sheet).
- **User flow**: App opens on Home → bottom bar (icons only) switches
  tabs with a short fade; tabs keep their state; tapping the current tab
  again returns to its root. Centre + opens the empty Quick Add sheet.
- **Business rules**: Theme built only from `DESIGN.md` tokens, light
  mode only. Outfit font bundled (no runtime download). Money shown as
  `₹1,23,456.00` (Indian grouping; negatives `-₹…`). Debug logs off in
  release; logs mask amounts, emails, long digit runs and tokens.
  Animations drop to zero length when "reduce motion" is on.
- **Data stored**: None. Drift was installed with no tables; the tables
  came in session 2 (see "Data model" below).
- **Validations**: `parseRupeesToPaise` returns null (invalid) for
  negatives, more than 2 decimals, bad grouping, non-ASCII digits and
  amounts above ₹10,00,00,00,00,000. Zero is allowed here; Quick Add must
  reject zero later.
- **Edge cases**: Reduce motion on; large system text; app or platform
  errors are routed to the logger.
- **Known gaps**: iOS build not verified (no macOS runner); owner
  will test on a Mac before release.
- **Status**: Done
- **Date**: 2026-11-12
- **PR link**: PR: https://github.com/deenazar/auditor_monkey/pull/6

## Data model (roadmap session 2)
- **What it does**: The local database that every screen will use. All
  8 tables (accounts, categories, transactions, budgets, loans,
  gold_holdings, gold_rates, daily_activities), with repositories and
  Riverpod providers. Full details in [DATABASE.md](DATABASE.md).
- **Screens**: None (data layer only).
- **User flow**: First launch creates the database and adds 34 default
  categories. Later launches open it without adding them again.
- **Business rules**:
  - Balance = opening balance + income − expense − transfers out +
    transfers in. Only live (not deleted) rows count. Worked out in one
    SQL query, never stored.
  - A transfer changes two balances and leaves net worth the same. It is
    never counted as income or expense.
  - Loan-linked entries count in balances but are left out of spending,
    income sums, budgets and top categories.
  - Loans: lent = giving money is an expense, a repayment is income;
    borrowed = the other way round. Outstanding = principal − repayments
    (can go below zero if overpaid).
  - Gold value = weight (mg) × latest rate per gram for that purity
    ÷ 1000, rounded half up in whole paise.
  - Delete is a soft delete (`deleted_at`); rows can be restored. Every
    write marks the row `pending` for sync.
  - Archived accounts and categories still count in balances and can
    still be used; screens decide whether to offer them.
- **Data stored**: All 8 tables. Money is whole paise. Ids are UUID v4.
  Times are UTC milliseconds; dates are `YYYY-MM-DD` text. 34 default
  categories (26 expense, 8 income) with fixed ids.
- **Validations** (in the repository first, database CHECK rules as a
  backup; errors come back as a typed failure, never a crash):
  - Amount above 0 and at most ₹10,00,00,00,00,000 (1e14 paise).
  - Transfer: different To account, no category, no loan.
  - Expense / income: category required and of the same kind.
  - Valid dates (years 1900–2100) and months; due date not before start.
  - Names: required, max length, no control characters; account names
    unique (ignoring case); category names unique per kind.
  - One budget per category per month; one gold rate per date and purity.
  - Note up to 200 characters (daily activity note up to 1000).
  - Negative opening balance only for card accounts.
  - Account colour must be a DESIGN.md token name.
- **Edge cases**:
  - Deleting an account, category or loan that live rows still use is
    refused. Deleting a category also deletes its live budgets.
  - Restore checks the rules again (for example, a name now taken).
  - Category kind and loan direction cannot change while in use.
  - A closed loan takes no new links; the principal cannot go below what
    was repaid.
  - Sum overflow returns a typed failure; 10,000 × 1 paisa sums exactly.
  - Opening a database newer than the app stops with an error and leaves
    the data untouched.
- **Known gaps**:
  - Database is not encrypted yet (session 8 will convert the existing
    data to SQLCipher, never wipe it). Android backup is off until then.
  - iOS: the file should be excluded from iCloud / device backup;
    to do in session 8.
  - Whether archived accounts count in net worth on screen: to confirm
    in sessions 3 and 6.
  - Category colour groups have no colours in DESIGN.md yet (session 4).
- **Status**: Done
- **Date**: 2026-11-12
- **PR link**: -

## 1. Onboarding and security
- **What it does**: Sign in, lock the app, and set up accounts on first
  launch.
- **Screens**: Welcome, Sign in (Google / Apple / phone OTP), Set PIN,
  Enable Face ID / fingerprint, Setup wizard (accounts + opening
  balances), Lock screen.
- **User flow**: Open app → setup wizard adds accounts → set PIN and
  biometrics → (later) sign in to turn on sync. Reopening the app shows
  the lock screen.
- **Business rules**: App is usable offline with no account. Default
  accounts offered: Hand, SBI, Axis, SCB, Food Card, Outside, PF.
  Opening balance becomes the account's starting point; after that,
  balances only change through transactions.
- **Data stored**: Accounts; PIN hash and DB key in secure storage; auth
  tokens in secure storage.
- **Validations**: Account name required and unique; opening balance a
  valid ₹ amount (0 or more; negative allowed only for card accounts);
  PIN 4–6 digits.
- **Edge cases**: Biometrics not available or changed; forgotten PIN;
  sign-in cancelled; no network during sign-in.
- **Status**: Planned (roadmap sessions 3, 8, 9)
- **Date**: 2026-11-12
- **PR link**: -

## 2. Quick Add
- **What it does**: Add an expense, income or transfer in a few taps.
- **Screens**: Quick Add sheet with tabs Expense / Income / Transfer.
- **User flow**: Tap + → type amount on number pad → pick category chip
  → account (or From / To) → date (default today) → optional note →
  Save.
- **Business rules**: Transfer updates both balances and is never
  counted as income or expense. Recent and frequent categories shown
  first. "Duplicate" copies a past entry with today's date.
- **Data stored**: Transactions.
- **Validations**: Amount > 0 with at most 2 decimals; category required
  for expense / income; From and To must differ; date not empty.
- **Edge cases**: Very large amounts; no categories yet; account
  archived; saving offline; double-tap on Save.
- **Status**: Planned (roadmap session 4)
- **Date**: 2026-11-12
- **PR link**: -

## 3. Accounts
- **What it does**: Shows live balances and each account's statement.
- **Screens**: Accounts list (balance cards in account colours),
  Account statement (running balance, income-vs-expense bar chart).
- **User flow**: Open Accounts → tap a card → scroll statement.
- **Business rules**: Balance = opening balance + income − expense ±
  transfers. Balances are never typed in.
- **Data stored**: Accounts (reads Transactions).
- **Validations**: Account name required and unique; colour required.
- **Edge cases**: Account with no transactions; negative balance;
  archived account with history.
- **Status**: Planned (roadmap session 3)
- **Date**: 2026-11-12
- **PR link**: -

## 4. Dashboard
- **What it does**: One-screen overview of the month.
- **Screens**: Dashboard (top cards, balance doughnut, top 3 expense
  categories, recent transactions).
- **User flow**: App opens to Dashboard after unlock.
- **Business rules**: Top cards: This Month Spent, Budget, Remaining,
  Income, Net Worth. Spending excludes transfers. Top categories exclude
  transfers and loan entries. Net Worth = sum of all account balances.
- **Data stored**: None (reads Transactions, Accounts, Budgets).
- **Validations**: n/a (read-only).
- **Edge cases**: New month with no entries; no budget set; negative
  remaining.
- **Status**: Planned (roadmap session 6)
- **Date**: 2026-11-12
- **PR link**: -

## 5. Monthly budgets
- **What it does**: Set a budget per category each month and get alerts.
- **Screens**: Budgets list with progress bars; Edit budget.
- **User flow**: Open Budgets → set amount per category → progress
  updates as entries are added.
- **Business rules**: Budgets reset every month. Bar green under 80%,
  amber from 80%, red when over 100%. Local notification once at 80%
  and once at 100% per category per month, e.g. "Groceries is at 85%
  of ₹3,000".
- **Data stored**: Budgets.
- **Validations**: Amount > 0; one budget per category per month.
- **Edge cases**: Entry edited or deleted after an alert; backdated
  entries; notifications turned off.
- **Status**: Planned (roadmap session 7)
- **Date**: 2026-11-12
- **PR link**: -

## 6. Transactions list
- **What it does**: Browse, search and fix past entries.
- **Screens**: Transactions list, filter sheet, edit (reuses Quick Add).
- **User flow**: Open list → search or filter by month / account /
  category → swipe left to delete, swipe right to edit.
- **Business rules**: Delete asks to confirm (or offers undo). Edits
  update balances and budgets right away.
- **Data stored**: Transactions.
- **Validations**: Same as Quick Add when editing.
- **Edge cases**: 20,000+ rows; no results; deleting a transfer.
- **Status**: Planned (roadmap session 5)
- **Date**: 2026-11-12
- **PR link**: -

## 7. Import from Excel
- **What it does**: Brings the existing sheet's history into the app.
- **Screens**: Pick file, preview and mapping, import summary.
- **User flow**: Pick `.xlsx` → preview rows → confirm → see counts of
  imported, skipped and failed rows.
- **Business rules**: EX rows become expenses, IN rows become income,
  with original dates, accounts and categories. Imported rows are
  marked with their source so a re-import does not duplicate them.
- **Data stored**: Transactions (and any missing Accounts / Categories).
- **Validations**: File type and size; required columns present; valid
  dates and amounts.
- **Edge cases**: Unknown account or category names; blank or merged
  rows; very large file; import interrupted.
- **Status**: Planned (roadmap session 10)
- **Date**: 2026-11-12
- **PR link**: -

## 8. Export and backup
- **What it does**: Export data and keep a cloud backup.
- **Screens**: Export options (Excel / PDF, date range, filters);
  Backup status.
- **User flow**: Choose export → share or save the file. Backups run
  automatically when online and signed in.
- **Business rules**: Exports show amounts in ₹ format. Backups are
  private to the owner's Supabase account.
- **Data stored**: Backup files in Supabase Storage.
- **Validations**: Valid date range.
- **Edge cases**: Empty range; no network; backup during sync.
- **Status**: Planned (roadmap sessions 9 and 11)
- **Date**: 2026-11-12
- **PR link**: -

## 9. Loans (Phase 2)
- **What it does**: Track money lent and borrowed, with repayments.
- **Data stored**: Loans; disbursements and repayments are Transactions
  linked by `loan_id`. Table, repository and outstanding-amount query
  created in session 2.
- **Status**: Planned (Phase 2; data layer done in session 2, screens
  later)
- **Date**: 2026-11-12
- **PR link**: -

## 10. Gold (Phase 2)
- **What it does**: Track gold holdings and their value from daily
  rates.
- **Data stored**: GoldHoldings, GoldRates. Tables, repositories and the
  current-value query created in session 2.
- **Status**: Planned (Phase 2; data layer done in session 2, screens
  later)
- **Date**: 2026-11-12
- **PR link**: -

## 11. Daily Activities (Phase 2)
- **What it does**: A simple daily log.
- **Data stored**: DailyActivities. Table and repository created in
  session 2.
- **Status**: Planned (Phase 2; data layer done in session 2, screens
  later)
- **Date**: 2026-11-12
- **PR link**: -
