# Session 3 plan: Accounts + setup wizard

- Roadmap item 3 (Features 1 part, 3). Status: **waiting for owner approval**.
- Date: 2026-11-12. Planned by project-manager.
- Suggested branch: `feature/20261112-accounts-setup-wizard` (from `develop`).
- Done when: balances match the sum of transactions after reload.

## 1. Summary
On first launch (no accounts yet) the app opens a 4-step setup wizard:
welcome, pick accounts, opening balances, review. Saving creates all
accounts in one go. After that the app opens normally. The Accounts tab
shows a card carousel in each account's colour with live balances.
Tapping a card opens its statement: a balance card, a 6-month
income-vs-expense pill bar chart and a paged list of entries with the
running balance after each one, ending with the opening balance.

**No schema change.** Only new repository / DAO queries and providers.

### In scope
Setup wizard, Accounts screen (carousel + list), Account statement
(read-only), app-start redirect, shared UI widgets these screens need,
golden test setup.

### Out of scope (later sessions)
Quick Add, transactions list / edit / delete, budgets, dashboard, login,
Supabase, app lock, archive / delete account UI, Excel import. The
statement only READS transactions.

## 2. Data and logic (no schema change)

Checks against the v1 schema:

| Need | Answer |
|------|--------|
| "Setup done" | Derived: at least one **live** account exists (`deleted_at IS NULL`, archived included). No new table or pref. |
| Type, colour, sort order | Already on `accounts` (`type`, `colour` token name, `sort_order`). Wizard writes sort order 0..n in list order. |
| Opening balance date | Not stored. Balance = opening + all live entries, whatever their date. The statement shows the opening balance as the last (oldest) row without a date. See owner question Q1 for the Excel import impact. |
| Running balance | New SQL query (window `SUM() OVER`, SQLite 3.54.1 supports it). Not stored. |
| Chart sums | New grouped SQL query per account and month. |

New code in existing files (senior-dev):
- `AccountsRepository.createAll(List<AccountDraft>)`: validates every
  draft, checks names are unique inside the list (ignoring case), inserts
  all in ONE database transaction. All or nothing.
- `TransactionsDao` / `TransactionsRepository`:
  - `statementPage(accountId, {cursor, limit})` and a watched version:
    live rows where `account_id = id OR to_account_id = id`, newest first
    (date, created_at, id), keyset paging, max 500 per page (default 50).
    Each line returns the entry, its signed effect on this account and
    `balanceAfter` = opening + running sum, computed in SQL. Overflow
    returns `OverflowFailure`.
  - `watchMonthlyTotalsForAccount(accountId, fromMonth, toMonth)`: income
    and expense per `YYYY-MM` for this account. Leaves out transfers and
    loan-linked rows (same rule as every other income / spending sum).
    Missing months are filled with 0 in Dart.
- No new index (an index is a schema change). Query plan test confirms
  `ix_tx_account` / `ix_tx_to_account` are used; 20,000-row timing is
  recorded only.

## 3. Screens and states

All values come from `lib/shared/theme` tokens. Side padding
`screenPadding` (24), sections `sectionGap` (32), list rows
`listRowGap` (20), cards `radiusCard` + `cardPadding`, flat
(`elevationNone`). Amounts use tabular figures and the small Light ₹
(`AppTextStyles.rupeeSign`). Every animation goes through
`AppMotion.resolve` (zero with reduce motion: fades only, no movement).

| # | Screen / state | Route | Shows | Tokens / patterns |
|---|----------------|-------|-------|-------------------|
| A1 | Start: loading | `/start` | White screen; small `primary` progress ring only after 300ms (no flash on fast starts) | `background`, `primary` |
| A2 | Start: database error | `/start` | Lucide `triangle-alert` in `danger`, `title` "We can't open your data", `body` "Your data is safe. Update or restart the app." No wipe, no retry that could harm data | `danger`, `title`, `body`, `inkMuted` |
| W0 | Wizard: welcome | `/setup` (step 0) | Mint hero (`radiusHero` bottom corners) with Lucide `wallet` in an `ink` 44pt circle outline, `displayTitle` "Set up your accounts", `body` one line; `PrimaryButton` "Get started" at bottom | `primary`, `ink` on mint, `displayTitle`, `radiusHero`, `radiusPill` |
| W1 | Wizard: pick accounts | `/setup` (step 1) | Page header (`pageEyebrow` "Step 1 of 3", `displayTitle` "Your accounts"), step dots, 7 preset tiles (Hand, SBI, Axis, SCB, Food Card, Outside, PF) all selected; each tile: 20pt colour dot, name `bodyStrong`, type `caption`, check icon; edit icon opens A/E sheet. "Add another account" row. Continue disabled with `caption` hint when none selected | Selected tile `navIndicator` bg, unselected `tile`; `radiusCard`; icons 20pt; `primaryDeep` check |
| W1s | Add / edit account sheet | sheet over `/setup` | Name field, type chips (cash, bank, card, wallet, PF, other), colour swatches (10 tokens), Save. Inline errors | Sheet `radiusCard` top, `shadowFloat`, `canvas` scrim; chips `radiusPill`; field `radiusField` |
| W2 | Wizard: opening balances | `/setup` (step 2) | Header "Step 2 of 3" / "Opening balances", `caption` "Your balance today. Leave empty for ₹0.00." One row per account: colour dot, name, ₹ amount field. Card accounts get an "I have / I owe" pill toggle | `body`, `caption`, `radiusField`, `danger` errors |
| W3 | Wizard: review | `/setup` (step 3) | Header "Step 3 of 3" / "All set?"; `overline` "STARTING NET WORTH" + `headline` total; mini cards per account (account colour, name, formatted opening); `PrimaryButton` "Create accounts" | account tokens, `overline`, `headline` |
| W3l | Review: saving | same | Button shows a small ring, disabled (no double save) | `primaryDeep` pressed |
| W3e | Review: save error | same | Error card: `danger` icon + message from the failure (e.g. duplicate name), entries kept, button active again | `danger`, `tile` |
| W-done | Wizard finished | → `/accounts` | Redirect; cards fade + slide in (`durationMedium`, `curveEnter`) | motion tokens |
| C1 | Accounts: data | `/accounts` | Page header (`pageEyebrow` "Your Wallet", `displayTitle` "Accounts"); `overline` "NET WORTH" + `headline` amount (rolls on change, `durationSlow`); carousel: current card full width, next card peeks 24pt; page dots; "All accounts" section: compact rows (colour dot, name, balance right) | DESIGN "Accounts" pattern, `curveSpring` snap, `durationSlow` settle |
| C1c | Account card | inside C1 | Account colour block, `primaryDeep` side-tab on the left with the name in vertical text (`onDark`); `overline` type ("BANK"), `displayAmount` balance, `caption` "Opening ₹…". Text colour per DESIGN Accounts table. Negative balance shows `-₹…` | `account*` tokens, `primaryDeep`, `onDark`/`ink`, `radiusCard` |
| C2 | Accounts: loading | `/accounts` | Static skeleton: header text + one card-sized `tile` block + 3 row blocks, faded in | `tile`, `radiusCard` |
| C3 | Accounts: empty | `/accounts` | Should not happen (redirect), but built: `body` "No accounts yet" + `PrimaryButton` "Set up accounts" → `/setup` | header pattern |
| C4 | Accounts: error | `/accounts` | `danger` icon, message (overflow: "A balance is too large to show"), "Try again" (invalidates provider) | `danger`, `accentText` text button |
| S1 | Statement: data | `/accounts/:accountId` | Back button (Lucide `chevron-left`, 44pt); header (`pageEyebrow` = type, `displayTitle` = name); balance card in account colour (`overline` "BALANCE", `displayAmount`); stat tile "INCOME VS EXPENSE": 6 months, paired pill bars, month labels, legend; "Statement" `title`; rows newest first | Stat tile pattern (`tile`), chart rules (6pt pill bars, `primary` income, `sun` expense, `durationChart` draw-in) |
| S1r | Statement row | inside S1 | Leading 44pt circle with category icon (transfer: `arrow-left-right`), name `bodyStrong` ("Groceries" / "To Axis" / "From SBI"), amount `caption` with sign + colour (expense `ink` −, income `accentText` +, transfer `inkMuted` no sign), date right in `body`, running balance under the date in `caption` | DESIGN "List row" pattern + Amounts table |
| S1o | Opening balance row | end of list | "Opening balance", amount, no date | List row |
| S1p | Next page loading / error | list footer | Small `primary` ring / "Couldn't load more. Try again" | `danger`, `accentText` |
| S2 | Statement: loading | same | Skeleton: balance card block, chart tile block, 5 row blocks | `tile` |
| S3 | Statement: no entries | same | Balance card + chart with all-zero months and `caption` "No income or expense in the last 6 months"; list shows only the opening row + `caption` "Entries you add with + show here." | |
| S4 | Statement: not found | same | Bad / deleted / malformed id: "This account isn't available" + back to Accounts | `body`, `accentText` |
| S5 | Statement: error | same | `danger` message + "Try again" | |

Route rules: `/start` while accounts are loading, `/setup` when no live
account exists, otherwise normal tabs. `/accounts/:accountId` is a child
of the Accounts branch (bottom bar stays). The id is checked to be a UUID
shape before any query. Android back on wizard steps 1-3 goes to the
previous step; on step 0 it leaves the app.

Motion summary: wizard steps slide 24pt + fade (`durationMedium`,
`curveEnter` in / `curveExit` out); carousel snap `curveSpring`, settle
`durationSlow`; numbers roll `durationSlow`; chart draws in and morphs
`durationChart`; pressed buttons scale `pressScale` 0.94 over
`durationFast`. Reduce motion: fades only, final values at once.

## 4. Tasks

Skills on every task: feature-workflow, validation, logging, security,
performance; UI tasks also ui-ux-motion, flutter-mobile-design,
design-taste; tests qa-testing.

### senior-dev
| ID | Task | Files (main) | Acceptance |
|----|------|--------------|------------|
| S1 | `createAll`, statement page with running balance, monthly totals per account (sec. 2) | `features/accounts/data/accounts_repository.dart`, `core/database/daos/transactions_dao.dart`, `features/transactions/data/transactions_repository.dart`, `features/transactions/domain/statement_line.dart` | All-or-nothing save; `balanceAfter` of the newest line equals `accountBalancesProvider` balance; oldest line's balance before it equals opening; transfers counted both sides; deleted rows ignored; overflow typed; no names/amounts in logs |
| S2 | Providers: `setupCompleteProvider`, `setupWizardProvider` (Notifier: presets, selection, edits, balances, validation, save), `accountStatementProvider(id)` (paged, refreshes on table change), `accountMonthlyTotalsProvider(id)`, `todayProvider` (local date from `clockProvider`) | `features/setup/application/*`, `features/accounts/application/*` | Wizard state never touches the DB until "Create accounts"; double save impossible; statement keeps loaded pages and refreshes live |
| S3 | Router: `/start`, `/setup`, `/accounts/:accountId`, redirect via `refreshListenable` bridged from Riverpod; update `test/app/app_test.dart` to override `appDatabaseProvider` with in-memory DB | `app/router.dart`, `app/app.dart` | No flash of Home before the wizard; tabs keep state; deep link to bad id → S4 |
| S4 | Money input: rupee text + "I owe" → paise (uses `parseRupeesToPaise`), Indian grouping on blur, `TextInputFormatter` (digits, one dot, 2 decimals, commas, max 40 chars) | `features/setup/domain/opening_balance_input.dart`, `shared/widgets/money_input_formatter.dart` | Empty = 0; negative only via "I owe" on card type; max `maxPaise`; no doubles anywhere |
| S5 | `IncomeExpenseBarChart` with fl_chart (add pinned version, log it) | `features/accounts/presentation/widgets/income_expense_bar_chart.dart` | Pill bars 6pt, `primary` / `sun`, draws in `durationChart`, zero with reduce motion, `RepaintBoundary`, semantics label per month |
| S6 | Motion pieces: `AccountCarousel` (PageView.builder, 24pt peek, spring snap), `RollingAmount` (integer paise tween), `WizardStepTransition` | `features/accounts/presentation/widgets/account_carousel.dart`, `shared/widgets/rolling_amount.dart`, `features/setup/presentation/widgets/wizard_step_transition.dart` | 60fps in profile mode with 10 cards; final values exact; reduce motion = fade only |
| S7 | Golden setup (sec. 6) and CI artifact upload | `test/flutter_test_config.dart`, `test/support/golden.dart`, `dart_test.yaml`, `.github/workflows/ci.yml`, `.gitignore` | Same PNGs on two runs; Outfit and Lucide glyphs visible (not boxes) |
| S8 | Acceptance test "balances match after reload" + 20k-row statement timing (record only) + query plan check | `test/features/accounts/reload_balance_test.dart`, `test/core/database/query_plan_test.dart` | See sec. 5 |

### junior-dev
| ID | Task | Files (main) | Acceptance |
|----|------|--------------|------------|
| J1 | Shared widgets: `PageHeader` (move out of `PlaceholderView`), `AmountText` (₹ glyph, sign + colour by kind), `PrimaryButton` (pressed / loading / disabled), `AppTextField`, `EmptyState`, `ErrorState` (retry), `SkeletonBlock`, `StepDots` | `shared/widgets/*` | Tokens only (no hex, no magic numbers); tap targets ≥ 44; large text (2.0) does not cut amounts |
| J2 | Account visuals: token → `Color` and text colour helper, `AccountCard` + vertical side-tab, `ColourSwatchPicker`, `AccountTypeChips`, `categoryIconFor(kebabName)` (34 seeded icons + fallback) | `features/accounts/presentation/widgets/*`, `shared/widgets/category_icon.dart` | All 10 colour tokens map; PF card side-tab rule (sec. 8); unknown icon name → fallback, no crash |
| J3 | Wizard screens W0-W3, W1s sheet, UI field validation (name required, ≤ 40, no control characters, unique ignoring case vs list; amount valid) | `features/setup/presentation/*` | Friendly inline messages; Continue / Create disabled while invalid; errors from the data layer shown too |
| J4 | Accounts screen C1-C4 using S6 carousel; "All accounts" list; tap card or row → statement | `features/accounts/presentation/accounts_screen.dart` + widgets | Live balance updates roll; archived accounts shown last with `overline` "ARCHIVED" |
| J5 | Statement screen S1-S5 using S1/S2/S5; `StatementRow`, `OpeningBalanceRow`, date label helper (`12 Nov`, year added when not this year) | `features/accounts/presentation/account_statement_screen.dart` + widgets, `core/utils/date_labels.dart` | Paging at 80% scroll; footer states; no write actions anywhere |
| J6 | Start screen A1 / A2 UI | `features/setup/presentation/start_screen.dart` | Ring appears only after 300ms |

Order / parallel: S1, S4, S7, J1, J2 start together. S2 after S1. S3
after S2. S5, S6 any time. J3 after S2 + S4 API is agreed (stub the
notifier first). J4 after S6. J5 after S1, S2, S5. S8 last. qa-reviewer
then reviews (code-review + qa-testing).

## 5. Tests

Unit (`test/features/...`, in-memory DB via `TestEnv`):
- `createAll`: saves all in order with sort order 0..n; one bad or
  duplicate (including case-only) draft saves nothing; card negative OK,
  bank negative refused.
- Statement: running balance with expense, income, transfer in / out,
  same-day ordering (created_at, id), deleted rows ignored, paging
  boundaries (49 / 50 / 51 rows), newest `balanceAfter` = balance query,
  overflow → `OverflowFailure`.
- Monthly totals: transfers and loan rows left out, empty months = 0,
  month edges (31st, 1st), other accounts' rows ignored.
- Wizard notifier: presets, toggle, add / edit / rename, duplicate names,
  amount parsing ("1,23,456.50", "", "abc", "-5", ">1e14"), "I owe" only
  for card, save success / failure keeps state.
- Redirect logic: loading → `/start`, no accounts → `/setup`, accounts →
  stays; malformed statement id.
- Money input formatter and opening balance input; date labels;
  `categoryIconFor` covers all 34 seeded icons.
- Logs: a wizard save and a statement load write no account names or
  amounts (MemoryLogSink check).
- **Acceptance (S8)**: file DB in a temp folder; run wizard save through
  providers; add 200 mixed entries (incl. transfers, loans, one deleted)
  via the repository; dispose container and close DB; reopen; each card
  balance equals opening + a hand sum in Dart of live rows, and the
  statement's newest running balance equals the card balance.
- Timing (record only): statement first page and monthly totals with
  20,000 rows on one account. Query plan uses the account indexes.

Widget (`test/features/.../presentation/`, providers overridden with an
in-memory DB and `FakeClock`):
- Wizard: full flow to Accounts; Continue disabled with nothing picked;
  inline errors; back between steps keeps data; double tap on Create
  saves once; save error card.
- Accounts: loading, data, empty, error states; tap card → statement;
  balance updates live after a repository write.
- Statement: loading, data, empty, not found, error, page footer;
  transfer rows show To / From and no sign; opening row last.
- Start screen: ring hidden before 300ms; error text for DB failure.
- Shared widgets: pressed / loading / disabled button; 44pt targets;
  reduce motion gives zero durations; text scale 2.0 no overflow.
- App: existing nav tests still pass (with DB override and one account).

Golden (tag `golden`, files in sec. 6):
`wizard_welcome`, `wizard_pick`, `wizard_pick_add_sheet`,
`wizard_balances` (with a card "I owe" and an error), `wizard_review`,
`wizard_review_error`, `accounts_data` (7 accounts, one negative),
`accounts_loading`, `accounts_empty`, `accounts_error`,
`accounts_data_textscale2`, `statement_data`, `statement_empty`,
`statement_loading`, `statement_not_found`, `start_error`,
`account_card_all_colours` (10 cards).

## 6. Golden tests in CI (ubuntu, Flutter 3.47.9)
- **Fonts**: `test/flutter_test_config.dart` loads the 4 Outfit TTFs
  with `FontLoader('Outfit')` and the Lucide font from the package
  (family taken from the package's `IconData.fontFamily` /
  `fontPackage`, e.g. `packages/lucide_icons_flutter/<family>`; senior
  checks the exact name) before any test runs. Do not rely on automatic
  font loading.
- **Surface**: one helper `pumpGolden(tester, widget, name)` sets
  `tester.view.physicalSize` 780x1688 with `devicePixelRatio` 2 (390x844
  logical), `textScaler` 1 (plus the one 2.0 case), resets in
  `addTearDown`.
- **Determinism**: `MediaQuery(disableAnimations: true)`, `pumpAndSettle`,
  `FakeClock` at 2026-11-12, fixed seed data, fixed UUIDs in fixtures,
  `debugDisableShadows = false` so `shadowFloat` renders as in the app.
- **Comparator**: small tolerance (0.5% pixels) via a custom
  `LocalFileComparator` subclass, to absorb tiny anti-alias noise only.
- **Where PNGs live**: next to the tests, e.g.
  `test/features/setup/presentation/goldens/wizard_review.png` and
  `test/features/accounts/presentation/goldens/accounts_data.png`. Committed,
  so the PR links them with GitHub blob URLs. `**/failures/` is git-ignored.
- **Making / updating**: only on Linux with Flutter 3.47.9 (cloud
  session): `flutter test --tags golden --update-goldens`. macOS output
  differs, so never commit goldens made on a Mac.
- **CI**: the normal `flutter test` runs goldens too. On failure an
  `actions/upload-artifact` step uploads `**/failures/*.png`
  (read-only permissions stay).

## 7. Low-risk decisions (to log in DECISIONS.md)
1. "Setup done" = at least one live account exists (archived included).
   No new table or pref. Archived accounts still hold history, so
   re-running the wizard for them would make duplicates.
2. Wizard cannot be skipped; at least one account is needed. Nothing is
   saved until "Create accounts"; leaving mid-way loses the draft.
3. Preset types and colours: Hand cash `accountHand`, SBI bank
   `accountSbi`, Axis bank `accountAxis`, SCB bank `accountScb`, Food Card
   wallet `accountFoodCard`, Outside other `accountOutside`, PF pf
   `accountPf`. All editable in the wizard.
4. Opening balance means "balance today". Empty field = ₹0.00. Card
   accounts enter debt with an "I owe" toggle (stored negative); the
   amount field never takes a minus sign.
5. Wizard steps live in one route (`/setup`) with in-memory Notifier
   state; statement is `/accounts/:accountId` inside the Accounts tab.
6. Statement chart: last 6 months including this month, income vs
   expense for this account; transfers and loan entries left out (same
   rule as all income / spending sums).
7. Statement: newest first, 50 rows per page, running balance after each
   row, opening balance as the last row with no date.
8. Running balance and chart sums are computed in SQL, never stored.
9. Accounts screen: net worth line (includes archived accounts, as the
   data layer does; closes the session 2 open point for this screen),
   carousel, then an "All accounts" list for quick access and screen
   readers. Archived accounts last with an "ARCHIVED" label.
10. Category circles use a neutral tint (`primary` at 20%) with an `ink`
    icon until session 4 sets category colour groups.
11. Golden setup as in sec. 6 (Linux-only masters, 0.5% tolerance,
    PNGs next to tests).
12. fl_chart added now (pinned version logged by senior-dev).
13. Start screen ring shows only after 300ms; a newer-database error
    shows a safe message and never wipes data.

## 8. Owner questions (hard to undo / money storage)
- **Q1. Opening balance vs Excel import (session 10).** With no opening
  date, importing full history later would count old entries on top of
  today's opening balance. Options: (a) keep "balance today"; in session
  10 the import offers to lower each opening balance by the imported net
  amount so today's balance stays right (preview first). (b) Add an
  `opening_balance_date` column now (schema v2 migration). (c) Ask the
  owner to enter the balance from the sheet's first date.
  **Recommend (a)**: no schema change, and the fix is a normal opening
  balance update with a preview.
- **Q2. Fixed ids for the 7 preset accounts.** If the wizard runs again
  on a new phone or after a reinstall before sign-in (session 9), random
  ids would make a second "SBI" that clashes with the cloud copy (names
  are unique). Fixed, hard-coded UUIDs (as for categories) let sync merge
  them. Custom accounts keep random ids. Hard to change once synced.
  **Recommend: yes, fixed ids for presets.**
- **Q3. Edit / add accounts after the wizard.** No roadmap session covers
  it, so a typo or wrong opening balance could not be fixed. Changing an
  opening balance changes every running balance in that statement.
  **Recommend: add a small "Edit account" sheet (name, colour, type,
  opening balance) on the statement and an "Add account" button on the
  Accounts screen, both reusing the wizard sheet. No archive / delete
  UI.** About +1 dev task each; otherwise put it in a later session.

### Owner answers (2026-11-12)
- **Q1: (a)** Opening balance means "balance today". No schema change.
  Session 10's import offers to lower opening balances, with a preview.
- **Q2: yes.** The 7 presets get fixed, hard-coded UUIDs (like the seed
  categories). Custom accounts keep random ids. → task **S9**.
- **Q3: yes.** Add an "Edit account" sheet (name, type, colour, opening
  balance) on the statement and an "Add account" button on the Accounts
  screen, both reusing the wizard sheet. No archive / delete UI.
  → tasks **S10** (repository update/add + validation, live refresh)
  and **J7** (UI).
- **DESIGN.md additions: approved** and added (Component sizes and
  Component rules sections; `AppSizes` in code).

| ID | Owner | Task | Acceptance |
|----|-------|------|------------|
| S9 | senior-dev | Fixed UUIDs for the 7 presets (`features/setup/domain/account_presets.dart`); `createAll` uses them | Ids hard-coded, documented "never change"; test pins them |
| S10 | senior-dev | Update an account (name, type, colour, opening balance) and add one after setup, via existing repository (add methods only if missing); same validation as wizard | Balance and statement running balances update live after edit; duplicate name rejected; negative opening only for card |
| J7 | junior-dev | "Edit account" (statement app bar) and "Add account" (Accounts screen) using the W1s sheet plus an opening balance field | Widget + golden tests for both |

## 9. Schema and DESIGN.md
- **Schema change: none.** (Q1 option b would be the only one: v2 adds
  `accounts.opening_balance_date TEXT NULL`, migration fills NULL, new
  dump + step test per DATABASE.md. Not recommended.)
- **Proposed DESIGN.md additions** (need owner OK, then senior adds them
  to `lib/shared/theme`):

| Token / rule | Value | Use |
|--------------|-------|-----|
| `accountCardHeight` | 200 | Carousel card |
| `accountSideTabWidth` | 40 | Card side-tab |
| `carouselPeek` | 24 | Next card peek (DESIGN says "about 24pt") |
| `buttonHeight` | 52 | Primary pill button |
| `fieldHeight` | 52 | Text fields |
| `iconCircle` | 44 | List row leading circle (DESIGN text says 44pt) |
| `colourDot` | 20 | Colour dot in rows; swatch 32 inside a 44 target |
| `statChartHeight` | 160 | Bar chart inside the stat tile |
| `stepDot` | 8 (active: 24 wide pill) | Wizard step dots, `primaryDeep` active, `divider` inactive |
| Side-tab on PF | `ink` tab, `onDark` text | `accountPf` equals `primaryDeep`, so the normal tab would vanish |
| Text field style | fill `tile`, no border; focus 2pt `primaryDeep`; error 2pt `danger` + `caption` in `danger` | Wizard fields |
| Disabled button | `divider` fill, `inkMuted` text | Continue / Create while invalid |
| Selected tile | `navIndicator` fill + `primaryDeep` check icon (no border, keeps flat rule) | Wizard pick list |
| Wizard step motion | 24pt slide + fade, `durationMedium`, `curveEnter` / `curveExit` | Uses existing tokens |

## 10. Docs after build (project-manager)
FEATURES.md (Features 1 part and 3), CHANGELOG.md, DECISIONS.md
(sec. 7 + owner answers), DESIGN.md (approved tokens), DATABASE.md (new
queries, no schema change).
