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
- **Data stored**: None. Drift is installed but has no tables.
- **Validations**: `parseRupeesToPaise` returns null (invalid) for
  negatives, more than 2 decimals, bad grouping, non-ASCII digits and
  amounts above ₹10,00,00,00,00,000. Zero is allowed here; Quick Add must
  reject zero later.
- **Edge cases**: Reduce motion on; large system text; app or platform
  errors are routed to the logger.
- **Known gaps**: Active nav icon colour (`primary` on white, about
  1.85:1) is below the 3:1 icon rule; needs owner choice (see
  DECISIONS.md). iOS build not verified (no macOS runner).
- **Status**: Done
- **Date**: 2026-11-12
- **PR link**: PR: pending

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
  valid ₹ amount (0 or more; negative allowed only for card/loan-type
  accounts if needed); PIN 4–6 digits.
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
- **Data stored**: Loans (table created in session 2); repayments are
  Transactions linked by `loanId`.
- **Status**: Planned (Phase 2)
- **Date**: 2026-11-12
- **PR link**: -

## 10. Gold (Phase 2)
- **What it does**: Track gold holdings and their value from daily
  rates.
- **Data stored**: GoldHoldings, GoldRates (tables created in
  session 2).
- **Status**: Planned (Phase 2)
- **Date**: 2026-11-12
- **PR link**: -

## 11. Daily Activities (Phase 2)
- **What it does**: A simple daily log.
- **Data stored**: DailyActivities (table created in session 2).
- **Status**: Planned (Phase 2)
- **Date**: 2026-11-12
- **PR link**: -
