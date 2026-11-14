# Features

One section per feature. Status: Planned / In progress / Done.
Details are filled in further when each feature is planned and built.

## 0. Project setup (roadmap session 1)
- **What it does**: The app's base: Flutter project, theme, navigation,
  logger, money formatting, lint and CI. No real features yet.
- **Screens**: Home, Insights, Transactions, Accounts (placeholders with
  page header and empty state). The centre + opens Quick Add (built in
  session 4, see Feature 2).
- **User flow**: App opens on Home → bottom bar (icons only) switches
  tabs with a short fade; tabs keep their state; tapping the current tab
  again returns to its root. Centre + opens the Quick Add sheet.
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
    income sums, budgets and top categories. Since session 6 (Q1) the
    same goes for entries in the 4 loan categories without a loan link.
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
  - ~~Whether archived accounts count in net worth on the dashboard~~:
    closed in session 6 (yes, Q5).
  - ~~Category colour groups have no colours in DESIGN.md yet~~: closed
    in session 4 (each group uses an existing colour token at 20% tint;
    statement rows and Quick Add chips use it).
- **Status**: Done
- **Date**: 2026-11-12
- **PR link**: PR: https://github.com/deenazar/auditor_monkey/pull/7

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
- **Status**: In progress. Setup wizard done (session 3, below). App
  lock planned for session 8, sign-in for session 9.
- **Date**: 2026-11-12
- **PR link**: -

### 1a. Setup wizard and start screen (roadmap session 3)
- **What it does**: On first launch (no live account yet) the app opens
  a wizard to create accounts with opening balances. After that the app
  opens normally.
- **Screens**:
  - Start (`/start`): white screen; small ring only after 300ms.
    Database error: "We can't open your data" / "Your data is safe.
    Update or restart the app." and "Try again".
  - Wizard (`/setup`, one route, 4 steps):
    - Welcome: mint hero, "Set up your accounts", "Get started".
    - Pick accounts ("Step 1 of 3"): 7 preset tiles, all selected; edit
      icon and "Add another account" open the account sheet (name, type
      chips, colour swatches). "Remove account" only on custom accounts.
    - Opening balances ("Step 2 of 3"): one ₹ field per account; card
      accounts have an "I have / I owe" toggle.
    - Review ("Step 3 of 3"): "STARTING NET WORTH", one mini card per
      account, "Create accounts". Saving shows a ring and blocks a
      second tap; a save error shows a card above the button and keeps
      every entry.
- **User flow**: Open app → Start → Wizard: Welcome → Pick → Balances →
  Review → "Create accounts" → Accounts tab. Android back on steps 1-3
  goes to the previous step; on step 0 it leaves the app.
- **Business rules**:
  - "Setup done" = at least one live account exists (archived count).
  - Nothing is saved until "Create accounts"; then all accounts are
    saved in one database transaction (all or nothing), sort order in
    list order.
  - Presets: Hand (cash), SBI, Axis, SCB (bank), Food Card (wallet),
    Outside (other), PF (pf), each with its `account*` colour and a
    fixed id. Custom accounts get random ids.
  - Opening balance means "balance today". Empty = ₹0.00. Debt on a
    card is entered with "I owe" (stored negative); the field never
    takes a minus sign.
  - The wizard cannot be skipped.
- **Data stored**: Accounts only.
- **Validations**: Name required, up to 40 characters, no control
  characters, unique ignoring case (inside the list and against saved
  accounts). Amount: digits, one dot, at most 2 decimals, Indian commas,
  max ₹10,00,00,00,00,000. Negative only via "I owe" on a card. Errors
  show while typing and on press; Save stays enabled. Continue is
  disabled with a hint when no account is picked.
- **Edge cases**: Leaving mid-way loses the draft. Database newer than
  the app or failing to open: safe message, "Try again" re-opens it,
  nothing wiped. Double tap on "Create accounts" saves once.
- **Tests**: `test/features/setup/` (wizard notifier, redirect, presets
  pinned, opening balance input, wizard screen, start screen),
  `test/features/accounts/create_all_test.dart`,
  `test/shared/widgets/money_input_formatter_test.dart`.
- **Goldens** (`test/features/setup/presentation/goldens/`):
  `wizard_welcome.png`, `wizard_pick.png`, `wizard_pick_add_sheet.png`,
  `wizard_balances.png`, `wizard_review.png`, `wizard_review_error.png`,
  `start_error.png`.
- **Status**: Done
- **Date**: 2026-11-12
- **PR link**: [#9](https://github.com/deenazar/auditor_monkey/pull/9)

## 2. Quick Add (roadmap session 4)
- **What it does**: Adds an expense, income or transfer in a few taps,
  fully offline. The most used screen in the app.
- **Screens**:
  - Quick Add sheet (opened by the centre +, about 92% of the screen
    height). Top: close button and tabs Expense / Income / Transfer, then
    the amount. Middle (scrolls on small phones and large text):
    "RECENT" strip, "CATEGORY" chip row (Transfer: From / swap / To),
    detail pills (account, Today, Yesterday, calendar, note). Bottom:
    number pad and "Save expense" / "Save income" / "Save transfer".
  - States: loading (pad already works, skeleton chips), empty, typing,
    amount refused (hint, sideways nudge), income, transfer, transfer
    disabled (fewer than 2 accounts, with a hint), recent entry applied,
    saving (ring), save error card (fields kept), no categories, load
    error ("Try again").
  - Account picker (colour dot, name, balance; in the To picker the
    From account is disabled), "All" categories sheet grouped by colour
    group, note sheet, date picker.
  - Saved toast above the nav bar: "Expense saved · ₹250.00" with Undo
    for 4s; after Undo, "Entry removed".
- **User flow**: Tap + → type the amount → Save (3 steps when the
  defaults are right). Other category: tap a chip first. Repeat a past
  entry: + → recent chip → Save (3 taps). Income or transfer: one extra
  tap on the tab.
- **Business rules**:
  - Number pad first: it is on screen from the first frame, no system
    keyboard for the amount. Hardware keys (digits, dot, Backspace,
    Enter = Save) work too. Long press on the amount pastes a copied
    amount.
  - Defaults per type: the last-used account and category (expense,
    income) and the last transfer's From and To. Fallback: the first
    account or category. A choice the user made is never replaced by a
    default that loads later.
  - Categories: up to 6 suggested (last used, then most used) first,
    then the rest in sort order. "All" opens every category grouped by
    colour group.
  - Recent strip: up to 6 distinct recent entries of all types. A tap
    fills type, amount, accounts, category and note; the date stays the
    form's date. It does not save by itself; Save is still needed.
  - Date: "Today" (default), "Yesterday", or the picker, up to 31 days
    after today. Today is read fresh on every open.
  - Amount, date and note are shared by the tabs; account and category
    picks are kept per tab. The sheet always opens on Expense.
  - Transfer changes both balances and is never counted as income or
    expense. It has no category.
  - Loan categories (Loan Given, Loan Repayment, Loan Received, Loan
    Repayment Received) are hidden until the loan screens exist. How
    totals count them did not change.
  - Archived accounts and categories are not offered.
  - Suggestions, defaults and recent entries look only at entries dated
    in the last 90 days (future dates included) and leave out
    loan-linked entries.
  - After save the sheet closes and the toast shows, even if the sheet
    was swiped away while saving. Undo soft deletes the entry. Closing
    the sheet drops the draft without asking.
- **Data stored**: Transactions (through the existing repository). No
  schema change.
- **Validations**:
  - Amount: above ₹0 and at most ₹10,00,00,00,00,000.00, at most 2
    decimals. Input is never rounded: a third decimal or a value over
    the max is refused with a hint. Empty or zero keeps Save disabled.
  - Category required for expense / income and of the same kind.
  - Transfer: From and To required and different (picking To = From
    swaps them).
  - Note: optional, up to 200 characters (counter from 180), single
    line, no control characters.
  - Date: real date, from 1900-01-01, up to 31 days after today.
  - The repository checks everything again.
- **Edge cases**: Double tap on Save saves once. Save fails (for example
  an account deleted meanwhile): error card, fields kept. Only one
  account: Transfer disabled. No categories of a kind: message and Save
  disabled. Large text (2.0): middle scrolls, amount never clips. Reduce
  motion: no nudge, slide, scale or turn; changes are instant.
- **Known gaps**: Open time on a real phone (profile mode, target under
  300ms) not yet measured; the owner should check it.
- **Tests**: `test/features/quick_add/` (amount input, domain logic,
  repository queries, notifier, logs, money correctness, performance,
  sheet, body states and flows, widgets, mapping),
  `test/core/database/query_plan_test.dart`.
- **Goldens** (`test/features/quick_add/presentation/goldens/`):
  `quick_add_loading.png`, `quick_add_expense_empty.png`,
  `quick_add_expense_typing.png`, `quick_add_amount_refused.png`,
  `quick_add_income.png`, `quick_add_transfer.png`,
  `quick_add_transfer_disabled.png`, `quick_add_recent_applied.png`,
  `quick_add_saving.png`, `quick_add_save_error.png`,
  `quick_add_no_categories.png`, `quick_add_load_error.png`,
  `quick_add_saved_toast.png`, `quick_add_account_picker.png`,
  `quick_add_all_categories.png`, `quick_add_note_sheet.png`,
  `quick_add_date_picker.png`, `quick_add_textscale2.png`,
  `category_chips_all_groups.png`. Updated: `statement_data.png`
  (group tints).
- **Status**: Done
- **Date**: 2026-11-12
- **PR link**: -

## Design polish (before roadmap session 5)
- **What it does**: Makes the app feel alive without changing any data
  or rules. Plan: [design-polish.md](plans/design-polish.md).
  - Motion: cards and rows slide in one after another; balances and net
    worth roll from ₹0 the first time you see them in each launch, then
    roll from the old to the new value; Quick Add springs open and you
    can type at once; the saved toast shows a tick; tabs fade through;
    pages inside a tab slide in.
  - Illustrations: 11 original drawings in the app's colours for empty
    states, errors, the wizard and the mascot poster.
  - Mascot: the Auditor Monkey on Home and in the setup wizard. It
    idles, looks happy, worried, celebrates or sleeps. Tap it to see it
    happy. (Built here as a 3D `.glb` model; since replaced by the 2.5D
    painter, see "Motion & 3D layer" below.)
  - Demo data: fills the app with 3 months of sample Indian personal
    finance entries, so you can see how screens look with real-sized
    data.
- **Screens**:
  - Home: mascot, flask button (top right, demo data).
  - Wizard: the mascot replaces the illustration on the welcome step
    (with the flask button, top right); the review step shows the
    celebrating mascot.
  - Accounts and statement empty states, generic error state, start
    error, Quick Add load error: now with illustrations.
  - Quick Add saved toast: success tick (not on "Entry removed").
  - "Demo data" ribbon at the top of the app while demo data is on.
- **User flow (demo data)**: Debug or profile build only → tap the
  flask button (top right on Home, or on the wizard welcome step) → load
  demo data → the app switches to the demo data and shows the "Demo
  data" ribbon. Tap the flask again → clear → the app goes back to your
  real data and the demo file is deleted.
- **Business rules**:
  - Reduce motion on: no slides, springs, rolls or ticks; final state
    shown at once. The mascot stays still.
  - Demo data lives in its own database file
    (`auditor_monkey_demo.sqlite`); your real data is never touched.
    Release builds do not contain demo data.
  - Illustrations are decorative; screen readers skip them.
- **Data stored**: No schema change. Demo data in a separate file plus a
  small marker file (`auditor_monkey_demo.on`) while it is on.
- **Validations**: n/a (no new inputs). Demo entries go through the
  normal repositories, so all existing rules apply.
- **Edge cases**: Large text (illustrations shrink to 120pt); demo
  data cleared while screens are open (they switch back to real data).
- **Security**: Plain HTTP is blocked everywhere. Release builds have
  no `INTERNET` permission until sync (roadmap session 9); see
  DECISIONS.md, 2026-11-14.
- **Known limits**:
  - Quick Add open time on a real phone (target under 300ms, profile
    mode) is not measured yet; there is no phone in the cloud session.
- **Tests**: motion widgets, roll-up keys, mascot view,
  demo seed and load / clear, illustrations, plus goldens.
- **Goldens**: all new and updated pictures on one page:
  [design-polish-goldens.md](plans/design-polish-goldens.md).
- **Status**: Done
- **Date**: 2026-11-13
- **PR link**: -

## Motion & 3D layer (before roadmap session 5)
- **What it does**: Keeps the original reference design and adds depth
  and motion on top. Rules: DESIGN.md "Motion & 3D".
- **Home**: mint hero with drifting blobs and parallax, net worth that
  rolls, a spending chart that draws in, the 2.5D Auditor Monkey; the
  lime card (saved % and spent this month) tilts when touched;
  Spendings bars and a Savings ring; "Savings goal reached" card at 20%
  saved; recent transactions: swipe left to delete (Undo in the toast),
  long-press to preview; pull down to refresh. Since session 6 the
  recent list shows 5 rows plus "See all" (was 12), and Home also has
  the Dashboard sections (Feature 4).
- **Monkey**: follows your finger, reacts to taps (head, belly, ears,
  tail, stroke, double tap, many taps), hops on a save, worries when
  spending is above income this month, dances with confetti when the
  savings goal is hit, sleeps 23:00–5:00.
- **Setup wizard**: blob hero with the waving monkey, steps turn in 3D,
  confetti when accounts are created.
- **Accounts**: cards tilt and fly into the statement; long-press a row
  to preview its card; pull to refresh.
- **Quick Add**: haptic on every key, chip and tab; springy presses;
  success haptic on save.
- **Everywhere**: illustrations pop in, loading blocks shimmer, buttons
  spring. With reduce motion everything is still; haptics, moods and
  speech remain.
- **Data**: no schema or money-rule change; delete uses the existing
  soft delete and restore.
- **Tests**: wow toolkit (tilt, haptics, confetti, shimmer limit, blob
  rest, parallax, flip), Home (layout, reduce motion, long-press
  preview, swipe delete + Undo on a real database), mascot, Home
  summary maths; goldens for Home (data, over plan, empty) and updated
  wizard / accounts / illustrations goldens.

## Motion & illustration pass (before roadmap session 5)
- **What it does**: Brings every screen to the Home dashboard's level of
  illustration, motion and interaction. The ticked list of screens and
  what each got: [motion-illustration-pass.md](plans/motion-illustration-pass.md).
- **New screen**: Settings (gear at the top left of Home):
  - Demo data (debug builds only).
  - "Say hi to the monkey" (the monkey dances, with confetti).
  - Motion (shows whether the phone's Reduce Motion is on).
  - Open-source licences.
  - About.
- **What you notice**:
  - The monkey reacts on every screen.
  - Errors show a worried monkey with Try again.
  - Pages swing in with depth.
  - Sheets spring up.
  - Rows can be swiped:
    - Statement: delete, with Undo.
    - Accounts: preview, or open the statement.
    - Settings: run the setting.
  - Long-press shows a preview.
  - The account sheet shows a live card as you type.
- **Rule**: every new screen must ship at this level (DESIGN.md
  "Quality bar", CLAUDE.md).
- **Data**: no schema or money-rule change; deletes use the existing soft
  delete and restore.

## 3. Accounts
- **What it does**: Shows live balances and each account's statement;
  lets the owner fix or add an account.
- **Screens**:
  - Accounts (`/accounts`): "Your Wallet" / "Accounts" header, "NET
    WORTH" amount (rolls on change), card carousel (next card peeks
    24pt, spring snap, page dots), "All accounts" list, "Add account".
    States: loading (skeleton), empty ("No accounts yet" + "Set up
    accounts"), error ("Try again").
  - Account card: account colour, dark side-tab with the name in
    vertical text (PF uses an `ink` tab), type overline (e.g. "BANK";
    archived: "BANK · ARCHIVED"), balance, "Opening ₹…".
  - Statement (`/accounts/:accountId`, inside the Accounts tab): back
    button, "Edit account", balance card, "INCOME VS EXPENSE" chart
    (last 6 months, pill bars: income `primary`, expense `sun`),
    entries newest first. Each row: icon circle (tinted in the
    category's colour group since session 4), name ("Groceries" /
    "To Axis" / "From SBI"), signed amount, date, running balance.
    "Opening balance" is the last row. Footer: ring while the next page
    loads, "Couldn't load more. Try again" on error. States: loading,
    no entries, not found ("This account isn't available"), error.
  - Edit / Add account sheet: name, type, colour, opening balance.
- **User flow**: Open Accounts → swipe cards or tap a card / row →
  statement → scroll (next page at 80%) → optional "Edit account".
  "Add account" on the Accounts screen opens the same sheet.
- **Business rules**:
  - Balance = opening balance + income − expense − transfers out +
    transfers in, from SQL; never typed in.
  - Net worth includes archived accounts. Archived accounts are listed
    last.
  - Running balance is worked out in SQL over all live entries of the
    account, then cut into pages of 50. Transfers count on both sides.
    Deleted entries are left out.
  - Chart: income and expense of this account per month; transfers and
    loan money left out (loan-linked entries and, since session 6, the 4
    loan categories without a link); empty months show 0.
  - The Home doughnut's second tap on a slice opens this statement
    (session 6).
  - Amounts: expense and negative balances use "−" (U+2212); income
    `+` in `accentText`; transfers no sign.
  - Editing the opening balance changes every running balance at once
    (nothing is stored). New accounts go last in the list.
  - No archive or delete UI yet.
- **Data stored**: Accounts (reads Transactions and Categories).
- **Validations**: Same as the wizard: name required, ≤ 40, unique
  ignoring case; type and colour required; negative opening balance
  only for card. Account id in the URL must be a UUID shape before any
  query.
- **Edge cases**: Account with no entries (zero chart, only the opening
  row, "Entries you add with + show here."); negative balance; balance
  too large ("A balance is too large to show"); bad or deleted id;
  large text (amounts scale down, never clip); reduce motion (fades
  only, final values at once).
- **Known gaps**: Live refresh re-reads every loaded page (fine for
  personal data; optimise if slow). Fixed preset ids vs a soft-deleted
  row with the same id: test once delete UI exists.
- **Tests**: `test/features/accounts/` (create all, balances, statement
  provider, form rules, reload acceptance test, screens, sheet, card,
  carousel, chart), `test/core/database/query_plan_test.dart` (indexes
  used; 20,000-row timings recorded), `test/shared/widgets/`.
- **Goldens** (`test/features/accounts/presentation/goldens/`):
  `accounts_data.png`, `accounts_loading.png`, `accounts_empty.png`,
  `accounts_error.png`, `accounts_data_textscale2.png`,
  `statement_data.png`, `statement_empty.png`, `statement_loading.png`,
  `statement_not_found.png`, `account_card_all_colours.png`,
  `edit_account_sheet.png`, `add_account_sheet.png`. Golden setup check:
  `test/support/goldens/golden_infra.png`.
- **Status**: Done
- **Date**: 2026-11-12
- **PR link**: [#9](https://github.com/deenazar/auditor_monkey/pull/9)

## 4. Dashboard (roadmap session 6)
- **What it does**: One-screen overview of the month. The Dashboard **is
  the Home tab**, extended (no second screen). Insights stays a
  placeholder. Plan: [session-6-dashboard.md](plans/session-6-dashboard.md).
- **Screens** (Home, top to bottom):
  - Hero (existing): NET WORTH rolls, area chart, monkey, parallax blobs.
  - Lime card (existing, tilts): THIS MONTH SPENT + saved %. Tap opens
    Transactions filtered to this month + expense.
  - Month tiles (new): one row of 3, Budget / Remaining / Income. The
    row tilts as one; each tile springs and has a long-press preview
    with the sum (e.g. "₹13,000.00 budget − ₹31,300.50 spent").
  - Spendings / Savings tiles (existing, kept, Q7).
  - Goal banner (existing, when saved % is 20 or more).
  - "Where your money is" (new): account balance doughnut with legend.
  - "Top spending" (new): the 3 biggest categories, each with icon,
    name, amount, % and a pill bar.
  - "Recent transactions": 5 rows plus a "See all" button.
  - States: loading (each section shimmers), empty month, no budget,
    over budget, only negative balances, section error (worried monkey
    + "Try again" on that card only).
- **User flow**:
  - Open the app → Home shows the month at a glance.
  - Tap a doughnut slice (or legend row) → it pops out and the monkey
    says e.g. "PF holds 50%" → tap it again → that account's statement.
  - Tap a Top spending row → Transactions filtered to this month +
    expense + that category.
  - Tap a recent row → the entry detail. Swipe left = delete with Undo,
    swipe right = edit (same actions as the Transactions tab).
  - "See all" → the Transactions tab with no filter.
  - Tap Budget → toast "Budgets come in a later update" (session 7).
  - Pull down to refresh.
- **Business rules** (number rules; `M` = the whole calendar month of
  today, future-dated rows included, Q2):
  - **This Month Spent**: sum of live `expense` rows in `M`, without
    loan money. Transfers never count. Refunds do not lower it (Q4).
  - **Income**: sum of live `income` rows in `M`, without loan money.
    Refunds count here.
  - **Loan money** (Q1): a row with a loan link OR one of the 4 loan
    categories. One shared SQL filter (`notLoanMoneySql`) used by the
    Dashboard, the Transactions day totals and month summary, and the
    account statement chart, so Spent / Income match on every screen.
  - **Budget**: sum of live budgets with `month = M`. None: "No budget
    yet".
  - **Remaining** (Q3): Budget − all of This Month Spent. Negative: in
    `danger` as "−₹…" with "over budget". No budget: "—" and "Set a
    budget (coming soon)".
  - **Net Worth** (Q5): sum of every live account's balance (all rows
    of any date, loan rows included), archived accounts and cards in.
    No loans outstanding or gold. Same as the Accounts screen.
  - **Doughnut**: one slice per account with balance > 0 (archived
    included). Zero: no slice. Negatives: no slice, an "Owed −₹…" line
    under the ring. Biggest first, ties by sort order then name. Max 5
    slices: with 6 or more, the 4 biggest + "Other". Centre: "ASSETS"
    and the sum of the slices. % = share of assets, whole numbers by
    the largest-remainder method, adding to 100; a share under 1% shows
    "<1%". Rules in DESIGN.md "Charts".
  - **Top 3**: live expense rows in `M` without loan money, grouped by
    category, biggest first (ties by category id). % = share of This
    Month Spent, whole %, rounded half up in integer maths. The bar
    length is that share.
  - **Recent**: the 5 newest live rows of all types (transfers and loan
    rows included). Order: date, then created time, then id, newest
    first. Future-dated rows show with their date (Q6).
  - **Saved %**: `round((Income − Spent) × 100 / Income)`, hidden when
    Income is 0; now over the whole month.
  - **Mascot mood**: plan = Budget if above 0, else Income. Worried when
    Spent is above the plan ("Uh-oh, over budget"), "Back on track!"
    when it recovers.
  - One snapshot: Spent, Income, Budget, Top 3, Recent and the 9-day
    chart are read in ONE read transaction, so they always agree. They
    reload when entries, accounts, categories or budgets change.
  - Today comes from the phone clock and is read again when the app
    comes back to the front, so Home rolls over at midnight and on the
    1st. Dates are local `YYYY-MM-DD` text; no time zone maths.
  - Money is integer paise, never rounded; INR only.
- **Data stored**: None. Read-only (Transactions, Accounts, Categories,
  Budgets). No schema change.
- **Validations**: Today must be a valid date; list limits 1 to 500
  (default 5 recent, 3 top). Account ids from the doughnut go through
  the statement's UUID check. Logs: `load ok ms=… rows=…`, never
  amounts or names.
- **Edge cases**:
  - Empty month: Spent ₹0.00, Income ₹0.00, Top spending empty
    illustration, doughnut still shows balances.
  - No accounts (cannot happen after setup): mascot "Add an account
    balance to see it here".
  - Only negative balances: ring hidden, "Owed −₹…" line and mascot
    "Only debts for now".
  - A balance too large: "A balance is too large to show" on that card
    only.
  - The selected slice stays selected (by account id) when balances
    change; it clears if the account is gone.
  - Large text (2.0): labels scale down to one line; nothing clips.
  - Reduce motion: no sweep, bar grow, tilt or stagger; final values at
    once. Haptics, moods and speech stay.
- **Known gaps**:
  - Detail and statement open with `context.go`, so Back goes to the
    Transactions / Accounts tab root, not to Home. Owner to decide on
    push.
  - At text scale 2 the tile amounts shrink a lot and recent names are
    cut short.
  - While categories load, Top spending rows show "Category" briefly.
  - Real-phone checks by the owner: 60fps ring and scroll, haptics,
    cold start under 2s.
- **Tests**: `test/features/home/` (domain: balance slices, top
  categories, dashboard summary; data: dashboard repository;
  `dashboard_numbers_test.dart` on the October 2026 test month, every
  value to the paisa; the repository test also pins "whole month" with
  today = 2026-10-15; `dashboard_fixture_test.dart`; `dashboard_performance_test.dart`
  on 20,000 rows, median and p95 recorded, fails if the median is above
  300ms; widgets: month tiles, doughnut, top spending, see all; Home
  screen and wiring), `test/support/fixtures/test_month_2026_10.dart`,
  `test/features/transactions/loan_category_filter_test.dart`,
  `test/core/utils/date_keys_test.dart`.
- **Goldens** (`test/features/home/presentation/goldens/`):
  `dashboard_data.png`, `dashboard_loading.png`,
  `dashboard_empty_month.png`, `dashboard_no_budget.png`,
  `dashboard_over_budget.png`, `dashboard_only_negative.png`,
  `dashboard_section_error.png`, `dashboard_text_scale_2.png`,
  `dashboard_slice_selected.png`. Home goldens still run:
  `home_data.png`, `home_over_plan.png`, `home_empty.png`.
- **Status**: Done (roadmap session 6)
- **Date**: 2026-11-14
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

## 6. Transactions list (roadmap session 5)
- **What it does**: Browse, search, filter and fix past entries.
- **Screens**:
  - Transactions tab: sky stage on top with month summary chips (Spent /
    Income / Net for the month of the top visible day; they follow the
    filters). Below: search field, filter button, saved filter chips and
    the list grouped by day, each day header with its daily total.
  - Filter sheet: date range (presets or custom), type, account (matches
    the From or the To side of a transfer), category.
  - Detail screen (`/transactions/:id`): the full entry with Edit and
    Delete.
  - Edit: the Quick Add sheet in edit mode.
  - States: loading, no entries, no results for the search / filters,
    error.
- **User flow**:
  - Open the tab → scroll (next page of 50 loads at the end) → search or
    filter → optionally save the filter as a chip.
  - Swipe left on a row = delete; a toast "Entry deleted" with Undo
    shows for 5s.
  - Swipe right on a row = edit in Quick Add; save shows "Changes saved"
    (no Undo).
  - Tap a row → detail → Edit, or Delete (asks to confirm, then back to
    the list with the Undo toast).
- **Business rules**:
  - Pages of 50, loaded with keyset paging (newest first).
  - Search: note, category name, or the exact amount when the text reads
    as rupees.
  - Filters: AND across facets (date, type, account, category), OR
    within one facet.
  - Saved filter chips keep facets only (never the search text). Max 12,
    name up to 24 characters, unique ignoring case.
  - Balances are always worked out from the rows, so they stay right
    after edit, delete and undo, transfers included.
  - Day totals and the month summary leave out transfers and loan money:
    loan-linked entries and, since session 6 (Q1), entries in the 4 loan
    categories without a loan link. Same shared filter as the Dashboard,
    so Spent / Income match. These entries still show in the list.
  - Edit mode: keeps the loan link and import source; a loan-linked
    entry keeps its type; an archived account or category already on the
    entry is still offered.
  - Undo restore is refused if the account was deleted meanwhile (an
    archived account is fine) or if the entry is linked to a loan that
    was closed meanwhile (DATABASE.md rule; reopen the loan first).
- **Data stored**: Transactions (no schema change). Saved filters in
  `saved_filters.json` in the app support folder (facets only).
- **Validations**: Same as Quick Add when editing; the repository checks
  again. Filter values (dates, ids, amounts) are checked before any
  query. Saved filter name: required, ≤ 24, no control characters.
- **Edge cases**:
  - 20,000 rows, p50: first page about 2ms, filtered page about 12ms,
    month summary under 1ms.
  - No results: message and a way to clear filters.
  - Deleting a transfer: both balances change back; Undo restores both.
  - Corrupt saved filters file: starts empty with a warning in the log.
- **Known gaps**: 60fps scrolling at 20,000 rows and swipe haptics need
  a real-phone check by the owner. Day headers scroll with the list (not
  pinned).
- **Status**: Done (roadmap session 5)
- **Date**: 2026-11-13
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
