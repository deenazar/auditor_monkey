# Decisions Log

One entry per decision: date, decision, options considered, reason.
Newest at the bottom.

## 2026-11-12: Flutter for the app
- Decision: Build with Flutter (Dart), one codebase for iOS and Android.
- Options considered: Flutter, React Native, two native apps.
- Reason: Owner's choice. One codebase for both phones, smooth 60fps
  custom UI and animation, and mature packages for everything we need
  (Drift, fl_chart, local_auth, Supabase, Firebase).

## 2026-11-12: Riverpod for state
- Decision: Use Riverpod (current `Notifier` / `AsyncNotifier` API).
- Options considered: Riverpod, BLoC, Provider.
- Reason: Owner's choice. Less boilerplate than BLoC, compile-safe, easy
  to test, and works well with Drift streams so screens update live.

## 2026-11-12: SQLite with Drift, encrypted, as the local database
- Decision: Drift on SQLite, encrypted with SQLCipher. The key is kept
  in the phone's secure storage (Keychain / Keystore).
- Options considered: Drift, Isar, Hive, sqflite directly.
- Reason: Owner's choice. Money data is relational (accounts,
  transactions, budgets, loans) and needs SQL sums for balances and
  reports. Drift gives typed queries, live streams and real migrations.
  Isar was ruled out (not relational, uncertain maintenance).

## 2026-11-12: Offline-first
- Decision: The local DB is the source of truth. Every write goes to the
  phone first and is queued for sync. Rows use UUIDs, `updatedAt`,
  `deletedAt` (soft delete) and a sync status.
- Options considered: Offline-first with sync queue; online-only with
  a cache.
- Reason: Entries must be quick and work with no network (shops,
  travel). UUIDs avoid ID clashes between phone and cloud; soft deletes
  let deletes sync.

## 2026-11-12: Supabase for login, sync and backup
- Decision: Supabase Auth (Google, Apple, phone OTP), Postgres for cloud
  sync with Row Level Security, Storage for backups.
- Options considered: Supabase, Firebase (Auth + Firestore), own server.
- Reason: Owner's choice. Postgres matches the relational local model,
  so sync maps table-to-table. Firebase is still used only for push
  notifications (FCM).

## 2026-11-12: Money stored as integer paise
- Decision: Store every amount as an integer number of paise. Show as
  Indian format, e.g. `₹1,23,456.00`.
- Options considered: integer paise, double, decimal string.
- Reason: Doubles cause rounding errors in totals. Integers are exact,
  fast to sum in SQL and simple to sync.

## 2026-11-12: Login built late (roadmap session 9)
- Decision: Build the app, data and daily-use screens first; add login
  and Supabase sync in session 9.
- Options considered: login first; login late.
- Reason: Offline-first means the app is fully usable with no account.
  Building the data model and screens first lets the owner start using
  the app sooner. Sync is then added on top of a stable local schema
  instead of chasing schema changes.

## 2026-11-12: Flutter SDK pinned for cloud sessions
- Decision: A SessionStart hook installs Flutter 3.47.9 (stable) in
  Claude Code cloud sessions only.
- Options considered: latest stable 3.50.0 (released 2026-11-11);
  3.47.9 (released 2026-10-29); unpinned stable channel.
- Reason: A pinned version keeps builds repeatable. 3.47.9 is the
  newest patch of the previous stable line and has been out for two
  weeks; we can move to 3.50.x once it has settled.

## 2026-11-12: Design changed from dark navy to reference screenshot
- Decision: Replace the dark navy theme (`#1D293B` / `#334054`) with
  the light mint design from `docs/design/reference.png`: white
  background, mint `#70D0B2` hero and cards, lime `#E4E782` and yellow
  `#FDD85C` accents, dark-green `#1E3B31` text, flat rounded cards,
  thin outline icons, curved area charts, rounded doughnuts and pill
  bars. Full spec in `DESIGN.md`.
- Options considered: keep dark navy; follow the reference exactly;
  follow the reference with accessibility and feature fixes.
- Reason: Owner's choice; the owner wants the app to match the
  reference. We changed a few things on purpose: dark text on mint
  instead of white (white fails contrast at 1.85:1), a Quick Add +
  button in the centre nav slot instead of a profile photo, added
  red/amber/green status colours, Outfit as a free stand-in for the
  unnamed font, and light theme only for Phase 1. Account colours
  (Axis yellow, SBI magenta, SCB green, Hand orange) kept and tuned to
  the palette.

## 2026-11-12: All design tokens in one DESIGN.md
- Decision: Keep every design token (colours, typography, spacing,
  radius, shadows, motion, navigation) and the design assumptions in a
  single `DESIGN.md` at the repo root. `docs/PROJECT.md` links to it.
- Options considered: Design section inside `docs/PROJECT.md`; a
  separate `DESIGN.md`.
- Reason: Owner's request. One file for designers and code to follow;
  the Flutter theme maps 1:1 to its token names.

## 2026-11-12: Lint rules
- Decision: flutter_lints plus strict rules (strict-casts, strict-inference,
  strict-raw-types, avoid_print, prefer_const_*, prefer_final_locals,
  unawaited_futures, require_trailing_commas, directives_ordering and
  others).
- Options considered: flutter_lints; very_good_analysis.
- Reason: Owner's choice. Matches PROJECT.md ("recommended lints") with
  extra safety, without very_good_analysis's noise.

## 2026-11-12: Icon package
- Decision: lucide_icons_flutter.
- Options considered: lucide_icons_flutter; lucide_icons (older).
- Reason: Named in DESIGN.md and still maintained.

## 2026-11-12: Plain Riverpod, no code generation
- Decision: flutter_riverpod with hand-written providers.
- Options considered: plain Riverpod; riverpod_generator.
- Reason: Owner's choice. Less build setup; build_runner is only for
  Drift.

## 2026-11-12: App id
- Decision: `com.deenazar.auditormonkey`; Dart package `auditor_monkey`.
- Options considered: n/a (owner's choice).
- Reason: Owner's choice.

## 2026-11-12: Outfit font as 4 static files
- Decision: Bundle static Outfit TTFs for weights 300, 400, 500, 600
  from Outfitio/Outfit-Fonts. Register the OFL licence with
  LicenseRegistry.
- Options considered: 4 static files; 1 variable font (google/fonts
  only ships the variable font); fetch at runtime (google_fonts).
- Reason: Static weights map to FontWeight reliably on both platforms;
  bundling works offline and starts faster.

## 2026-11-12: Logger and money helper in session 1
- Decision: Build them in session 1, as the PROJECT.md roadmap says.
  `AppLogger` has debug / info / warning / error; debug is dropped in
  release; `LogRedactor` masks amounts, emails, long digit runs and long
  tokens; output goes through a swappable `LogSink` (dart:developer by
  default); Flutter and platform errors go to the logger.
  `formatPaise(int)` gives `₹1,23,456.00` (negatives `-₹…`).
  `parseRupeesToPaise(String?)` returns null when invalid: negatives,
  more than 2 decimals, bad grouping, non-ASCII digits, or above
  ₹10,00,00,00,00,000 (1e14 paise). Zero is allowed; Quick Add must
  reject zero later.
- Options considered: in session 1; move to session 2.
- Reason: Owner's choice. Every later feature needs logging and money
  display.

## 2026-11-12: Quick Add placeholder
- Decision: The centre + opens an empty bottom sheet (durationMedium,
  curveEnter in, curveExit out). Pressed state: scales to 0.94 and turns
  primaryDeep with an onDark icon; no scale when reduce motion is on.
- Options considered: empty sheet; placeholder route; "coming soon"
  snackbar.
- Reason: Matches the real Quick Add sheet planned for session 4.

## 2026-11-12: Reduce motion
- Decision: `AppMotion.resolve` returns a zero duration when the phone's
  reduce-motion setting is on.
- Options considered: n/a.
- Reason: DESIGN.md rule: show final values instantly.

## 2026-11-12: DESIGN.md gaps filled (owner approved)
- Decision:
  - Nav icons: house, chart-pie, plus, list, wallet at 24pt, default
    Lucide stroke (1.5pt not tuned).
  - Nav bar: 72pt high plus bottom safe area, 1pt `divider` top border,
    Quick Add 56pt centred, each slot full height (at least 44pt).
  - Tab switch: durationFast fade (FadeIndexedStack); tabs keep state;
    tapping the current tab returns to its root.
  - `shadowFloat`: offset (0, 4), blur 16, spread 0,
    rgba(30,59,49,0.12).
  - `curveSpring`: damping ratio 0.8, stiffness 200, mass 1.
  - Home avatar left out for now.
  - Insights is a placeholder; its purpose is still to be decided.
- Options considered: as proposed in the session 1 plan.
- Reason: DESIGN.md did not specify these; owner approved the
  proposals.

## 2026-11-12: CI
- Decision: GitHub Actions on pull requests and pushes to main, Flutter
  3.47.9 pinned: format check, `flutter analyze --fatal-infos`,
  `flutter test`. Read-only permissions.
- Options considered: n/a.
- Reason: Same Flutter version as cloud sessions; least privilege.

## 2026-11-12: Open / needs owner
- ~~Active nav icon colour~~: closed, see the decision below.
- iOS build not verified (still open): there is no macOS runner. Owner
  will test on their own Mac before release. Deferred.

## 2026-11-12: Active nav icon is ink on a mint pill (closed)
- Decision: The active nav icon uses `ink` `#1E3B31`, with a soft mint
  pill behind it (`navIndicator` `#DDF4EC`, 56x32, `radiusPill`). The
  pill fades and scales in over `durationFast`; it only fades with
  reduce motion on. Inactive icons stay `iconInactive`. DESIGN.md is
  updated.
- Reason: `primary` on white (about 1.85:1) failed the 3:1 icon rule.
  `ink` is 12.2:1 on white and 10.6:1 on the pill.
- Decided by: owner.

## 2026-11-12: All 8 tables built in session 2
- Decision: Session 2 builds all 8 tables from PROJECT.md (accounts,
  categories, transactions, budgets, loans, gold_holdings, gold_rates,
  daily_activities) with repositories, providers and tests. No screens.
- Options considered: all 8 now (matches PROJECT.md); only 4 now and
  the rest by migration in Phase 2.
- Reason: Matches the roadmap. One stable v1 schema before sync is
  built, and `transactions.loan_id` can be a real foreign key.
- Decided by: owner.

## 2026-11-12: How data is stored on disk
- Decision:
  - Enums are lower case text with a CHECK rule (e.g. `expense`).
  - Calendar dates are text `YYYY-MM-DD` (local date); months `YYYY-MM`.
  - Timestamps are UTC epoch milliseconds (plain integers).
  - SQL columns are snake_case.
  - Money is integer paise only; no decimal columns; CHECK rules reject
    non-integers.
  - Ids are UUID v4 text made in Dart. Delete is a soft delete
    (`deleted_at`). `sync_status` is `pending` or `synced`; every local
    write sets `pending` and bumps `updated_at`.
- Options considered: enums as numbers; dates as numbers or Drift
  `DateTimeColumn`; camelCase columns.
- Reason: Text enums are readable in Supabase and safe if enum order
  changes. Text dates never shift a day across time zones, sort
  correctly and map to Postgres `date`. snake_case matches Postgres, so
  sync maps column to column. These formats are hard to change later.
- Decided by: owner.

## 2026-11-12: Default categories with fixed ids
- Decision: 34 default categories (26 expense, 8 income) are added on
  first launch, each with a fixed, hard-coded UUID. List in
  `lib/core/database/seed/default_categories.dart` and DATABASE.md. It
  includes 4 loan categories (Loan Given, Loan Repayment, Loan Received,
  Loan Repayment Received) added by the team.
- Options considered: random ids per install; fixed ids; owner's Excel
  sheet list.
- Reason: Fixed ids mean the same category on every install, so a
  reinstall, restore or second phone does not make duplicates, and the
  Excel import has stable targets. The owner chose the proposed list
  over supplying the sheet list. The loan categories let loan entries
  have a category, as the rules require.
- Decided by: owner (list and fixed ids); team (4 loan categories).

## 2026-11-12: Loans and money rules
- Decision:
  - `transactions.loan_id` is a real foreign key to `loans` (owner).
  - Lent: giving money is an expense, a repayment is income. Borrowed:
    the other way round. Outstanding = principal − repayments, in SQL.
  - Loan entries count in account balances but are left out of
    spending, income sums, budgets and top categories.
  - Overpaying is allowed (outstanding goes below zero). Several
    disbursements are allowed. The principal cannot drop below what was
    repaid. Lent / borrowed cannot change while entries are linked. A
    closed loan takes no new links. A loan in use cannot be deleted.
  - Transfers can never be linked to a loan.
- Options considered: loan_id without a foreign key; a separate
  repayments table.
- Reason: Loans are real money moves, so balances must include them,
  but they are not spending or earning. Using transactions keeps one
  balance rule.
- Decided by: owner (foreign key); team (the other rules).

## 2026-11-12: Account and category rules
- Decision:
  - A negative opening balance is allowed only for card accounts
    (owner). The database allows ± the max amount; the repository
    enforces the card rule.
  - Archived accounts and categories still count in balances and net
    worth and can still be used; screens decide whether to offer them.
  - Account colour is a DESIGN.md token: `primary`, `lime`, `sun` or
    one of the 7 `account*` tokens.
  - A category's kind cannot change while it is in use. Deleting a
    category also deletes its live budgets. Deleting an account,
    category or loan that live rows use is refused.
  - Restoring a deleted row checks all rules again.
  - Names reject control characters; dates must be years 1900–2100.
- Options considered: negative opening for any account; hide archived
  rows from totals.
- Reason: Keeps history and totals correct. Card balances can start
  owing money. Token names survive palette changes.
- Decided by: owner (card rule); team (the rest).

## 2026-11-12: Gold value
- Decision: Value of a holding = (weight_mg × latest live rate per gram
  of the same purity + 500) ÷ 1000, in integer maths (rounds half up to
  whole paise). "Latest" is the newest rate by date, future dates
  included. No rate means no value. A holding's account is information
  only and creates no transaction.
- Options considered: round down; ignore future-dated rates.
- Reason: Exact integer maths, no doubles. The largest possible value
  (1e17) fits safely in 64 bits.
- Decided by: team.

## 2026-11-12: Encryption later, data kept
- Decision: The database is not encrypted until session 8. It is opened
  in one file only (`lib/core/database/connection/open_connection.dart`,
  `NativeDatabase.createInBackground`, statement logging off). Session 8
  converts the existing data to SQLCipher and never wipes it. Android
  `allowBackup` is off until then.
- Options considered: wipe data at session 8; encrypt now.
- Reason: The owner may record real entries before session 8. One open
  point keeps the switch small. Backup is off so an unencrypted copy
  does not leave the phone.
- Decided by: owner (convert, never wipe); team (allowBackup off).

## 2026-11-12: Database packages and code structure
- Decision:
  - Packages: uuid ^4.6.0, path_provider ^2.1.6, path ^1.9.1,
    sqlite3 ^3.9.1 (its build hook bundles SQLite 3.54.1; no
    sqlite3_flutter_libs).
  - DAOs in `lib/core/database/daos/`. Domain models (Account, Category,
    TransactionEntry, Budget, Loan, GoldHolding, GoldRate,
    DailyActivity) are separate from Drift rows, which end in `Row`.
  - Writes use an `XDraft` plus `validateXDraft`. Errors are a sealed
    `DataFailure`: ValidationFailure, NotFoundFailure, InUseFailure,
    DuplicateFailure, OverflowFailure, StorageFailure.
  - Plain Riverpod providers: `appDatabaseProvider`, one repository
    provider per feature, and stream providers such as
    `accountBalancesProvider`, `netWorthProvider` and
    `budgetsForMonthProvider(month)`.
  - Transaction list uses keyset paging, at most 500 rows per page.
  - Sum overflow is detected and returned as `OverflowFailure`.
  - Foreign keys are `ON DELETE RESTRICT`, checked at commit (deferred),
    so sync batches can arrive in any order.
  - Logs show the action and the first 8 characters of the id only;
    never amounts, names, notes, people or SQL text.
- Options considered: `drift_flutter`; `sqlite3_flutter_libs`; Drift
  rows used directly in the app; OFFSET paging.
- Reason: The bundled SQLite needs no extra plugin. A single open point
  is easy to swap for SQLCipher. Separate models keep screens free of
  Drift. Keyset paging stays fast with 20,000+ rows.
- Decided by: team (senior-dev).

## 2026-11-12: Schema change process and tests
- Decision: `schemaVersion` starts at 1. Schema dumps live in
  `drift_schemas/app/` and are never edited. Each change raises the
  version, runs `drift_dev make-migrations` and adds a `stepByStep`
  step plus a data test (steps start from v2; make-migrations writes no
  steps file at v1). A guard test fails if a dump is missing. Opening a
  newer database stops with an error and keeps the data. Timing tests
  (20,000 rows) record numbers only and do not fail the build; query
  plan tests check the indexes. Full steps in `docs/DATABASE.md`.
- Options considered: hand-written migrations without dumps; timing
  tests as hard gates.
- Reason: Generated dumps and tests catch broken migrations before
  they reach the owner's data. Timing gates are flaky on CI machines.
- Decided by: team.

## 2026-11-12: Open after session 2
- Archived accounts in net worth: the data layer counts them; confirm
  on screen in sessions 3 and 6.
- iOS: exclude the database file from iCloud / device backup; do in
  session 8 with encryption.
- Category colour groups have no colours in DESIGN.md yet; decide in
  session 4.

## 2026-11-12: Opening balance means "balance today" (session 3, Q1)
- Decision: The opening balance is the account's balance today. No
  opening date column; no schema change (still v1). In session 10 the
  Excel import offers to lower each opening balance by the imported net
  amount, with a preview, so today's balance stays right.
- Options considered: (a) "balance today" + fix at import; (b) add
  `opening_balance_date` now (schema v2); (c) enter the balance from
  the sheet's first date.
- Reason: No migration needed, and the import fix is a normal opening
  balance edit that the owner sees first.
- Decided by: owner.

## 2026-11-12: Fixed ids for the 7 preset accounts (session 3, Q2)
- Decision: Hand, SBI, Axis, SCB, Food Card, Outside and PF get fixed,
  hard-coded UUIDs in `lib/features/setup/domain/account_presets.dart`
  (never change them; a test pins them). Custom accounts get random ids.
- Options considered: random ids for all; fixed ids for presets.
- Reason: If the wizard runs again on a new phone or after a reinstall
  before sign-in, the same ids let sync merge the accounts instead of
  making a second "SBI". Hard to change once synced.
- Decided by: owner.

## 2026-11-12: Edit / Add account sheets, no archive or delete (session 3, Q3)
- Decision: "Edit account" (name, type, colour, opening balance) on the
  statement and "Add account" on the Accounts screen, both reusing the
  wizard sheet. No archive or delete UI.
- Options considered: add now; leave to a later session.
- Reason: No roadmap session covered it, so a typo or wrong opening
  balance could not be fixed.
- Decided by: owner.

## 2026-11-12: DESIGN.md component sizes and rules (session 3)
- Decision: Approved the Component sizes and Component rules sections
  (`AppSizes` in code): `accountCardHeight` 200, `accountSideTabWidth`
  40, `carouselPeek` 24, `buttonHeight` 52, `fieldHeight` 52,
  `iconCircle` 44, `colourDot` 20 (swatch 32 in a 44 target),
  `statChartHeight` 160, `stepDot` 8 (active 24 wide); PF side-tab in
  `ink`; text field, disabled button and selected tile styles; wizard
  step motion.
- Options considered: as proposed in the session 3 plan.
- Reason: DESIGN.md did not give these sizes; one set of tokens keeps
  screens consistent.
- Decided by: owner.

## 2026-11-12: Session 3 low-risk decisions (plan section 7)
- Decision:
  1. "Setup done" = at least one live account exists (archived
     included). No new table or pref.
  2. The wizard cannot be skipped. Nothing is saved until "Create
     accounts"; leaving mid-way loses the draft.
  3. Preset types and colours: Hand cash `accountHand`, SBI bank
     `accountSbi`, Axis bank `accountAxis`, SCB bank `accountScb`, Food
     Card wallet `accountFoodCard`, Outside other `accountOutside`, PF
     pf `accountPf`. All editable.
  4. Empty opening balance = ₹0.00. Card debt uses an "I owe" toggle
     (stored negative); the field never takes a minus sign.
  5. Wizard steps live in one route (`/setup`) with in-memory Notifier
     state; statement is `/accounts/:accountId` inside the Accounts tab.
  6. Statement chart: last 6 months including this month; transfers and
     loan entries left out.
  7. Statement: newest first, 50 rows per page, running balance after
     each row, opening balance as the last row with no date.
  8. Running balance and chart sums are computed in SQL, never stored.
  9. Accounts screen: net worth (includes archived accounts; closes the
     session 2 open point for this screen), carousel, then an "All
     accounts" list. Archived accounts last.
  10. Category circles use a neutral tint with an `ink` icon until
      session 4 sets category colour groups.
  11. Goldens: Linux-only masters, 0.5% pixel tolerance, PNGs next to
      the tests.
  12. fl_chart added now.
  13. Start ring shows only after 300ms; a database error shows a safe
      message and never wipes data.
- Options considered: as listed in the plan.
- Reason: Low risk and easy to change later.
- Decided by: team (project-manager plan, owner approved the plan).

## 2026-11-12: Session 3 data and app-start choices
- Decision:
  - The "setup done" check is a live `EXISTS` stream on accounts. The
    router uses `resolveSetupRedirect` with a `refreshListenable`
    bridged from Riverpod: `/start` while loading, `/setup` with no
    accounts, otherwise the tabs.
  - Name uniqueness in `createAll` is checked across the whole list and
    against saved accounts.
  - Running balance: one SQL window sum over a `UNION ALL` of the two
    account indexes; no new index (that would be a schema change). The
    page joins category and counterpart names with `LEFT JOIN`.
  - Live refresh re-reads the pages already loaded (up to 5,000 lines).
    Fine for personal data; optimise if it gets slow.
  - `accountBalancesProvider` and `netWorthProvider` use `noRetry`, so
    error states show instead of retrying forever.
  - Start error "Try again" re-opens the database (nothing is wiped).
    This differs from plan A2, which had no retry; re-opening cannot
    harm data.
  - fl_chart pinned to 1.3.1.
- Options considered: a stored "setup done" flag; running balance in
  Dart; OFFSET paging; Riverpod's default retry.
- Reason: Derived state cannot go out of sync. SQL keeps memory low and
  stays fast with 20,000 rows (first page 42ms, next 32ms, monthly 6ms
  in test mode, recorded only).
- Decided by: team (senior-dev).

## 2026-11-12: Session 3 UI choices
- Decision:
  - Extra size tokens: `iconInline` 20, `iconChip` 16, `iconLarge` 48,
    `progressRing` 24, `progressStroke` 2, `fieldLineWidth` 2,
    `chartBarWidth` 6, `chartGridLine` 1; motion `springStiffness` 200
    and `springDampingRatio` 0.8. Added to DESIGN.md.
  - Loading rings: `primaryDeep` on white (`primary` is only 1.9:1 and
    fails the 3:1 rule), `ink` on mint. A loading button keeps its
    `primary` fill with an `ink` ring; pressed = `primaryDeep` +
    `onDark`.
  - Amounts and card text scale down (FittedBox) at large text instead
    of clipping.
  - Archived card overline: "BANK · ARCHIVED".
  - `StartScreen` is a `Scaffold` and never shows the raw error; the
    caller logs it.
  - 30 category icon names mapped; unknown names use Lucide ellipsis.
  - Statement icon circle tint uses `navIndicator` (closest token to
    `primary` at 20%).
  - The save error card sits above "Create accounts".
  - Sheet field errors show while typing and on press; Save stays
    enabled.
  - "Remove account" only for custom accounts in the wizard.
  - Statement loads the next page at 80% scroll.
  - Negative balances show "−" (U+2212), like expenses.
  - Bottom sheets honour reduce motion. Reduce motion in the wizard:
    `durationFast` fade; the carousel uses a critically damped spring.
  - The colour picker hides `sun` (same colour as `accountAxis`); the
    token still resolves for existing rows.
  - Type chips sit in a `Wrap` so they never overflow.
- Options considered: n/a (filling gaps in the plan and DESIGN.md).
- Reason: Contrast, large-text and reduce-motion rules; fewer
  confusing choices.
- Decided by: team (senior-dev, junior-dev, qa-reviewer).

## 2026-11-12: ₹ glyph uses the system font
- Decision: Outfit has no ₹ glyph, so phones draw ₹ with the system
  fallback font. Golden tests load Roboto as a test-only fallback
  (`RupeeFallback`), so the ₹ in goldens looks slightly different from
  a real phone.
- Options considered: bundle a second font for ₹; draw ₹ as an icon.
- Reason: System fonts already have a good ₹; no extra asset.
- Decided by: team.

## 2026-11-12: Open after session 3
- Statement live refresh re-reads loaded pages; optimise if slow.
- Fixed preset id vs a soft-deleted row with the same id: test once
  delete UI exists.
- Archived accounts in net worth: done on the Accounts screen; confirm
  on the dashboard in session 6.

## 2026-11-12: Session 4 low-risk decisions (Quick Add plan section 7)
Part of the session 4 plan (`docs/plans/session-4-quick-add.md`),
approved by the owner on 2026-11-12.
- Decision:
  1. "Last used" and "recent / frequent" come from SQL queries on live
     transactions. No prefs, no new table, no new package, no schema
     change.
  2. Quick Add queries look at entries dated in the last 90 days
     (future dates included), ordered by entry time (`created_at`).
     Loan-linked entries are left out.
  3. Archived accounts and categories are not offered in Quick Add.
  4. The sheet always opens on Expense. Amount, date and note are shared
     by the tabs; account and category picks are kept per tab.
  5. Defaults: last-used account / category per type, with fallbacks to
     the first account or category. Transfer needs 2 offered accounts;
     otherwise the tab is disabled with a hint.
  6. Categories: up to 6 suggested (last used, then most used), then
     the rest in sort order, in one scrolling row plus an "All" sheet
     grouped by colour group.
  7. Recent strip: up to 6 distinct recent entries of all types. A tap
     fills the form (keeps the form's date) and does not save by itself.
  8. The number pad is always on screen. Input that would need rounding
     (more than 2 decimals, above the max) is refused with a hint, never
     rounded. Paste by long press on the amount.
  9. Quick Add date rule: up to 31 days after today; "Today" and
     "Yesterday" chips plus a date picker. The repository keeps the
     1900-2100 rule.
  10. After save the sheet closes and a toast shows for 4s with Undo
      (soft delete via the existing repository). No "add another" mode.
      Closing the sheet drops the draft without asking.
  11. Today's date is read from the clock on each open.
  12. Category colour groups use existing tokens at 20% tint:
      essentials `accountScb`, food `accountHand`, transport
      `accountOutside`, home `sun`, lifestyle `accountSbi`, health
      `primaryLight`, family `lime`, finance `accountPf`, other
      `iconInactive`, income `primary`. Statement rows use the group
      tint (closes the session 2 / 3 open item).
  13. DESIGN.md additions: `numPadKeyHeight` 56, `chipHeight` 44,
      `chipIconCircle` 28, motion `toastDuration` 4000ms; rules for
      choice chips, segmented tabs, number pad keys, refused input and
      the toast (plan section 9).
  14. Quick Add speed targets (save < 100ms, open data < 100ms with
      20,000 rows): the test prints and records the real median and p95,
      and fails only if the median is above 250ms (owner answer, so slow
      CI machines do not fail at random). Other timing tests stay
      "record only".
- Options considered: shared_preferences for last-used values; a new
  "recent" table; auto-save on recent tap; "add another" mode; offering
  archived rows; timing as record only.
- Reason: Derived values cannot go out of sync and need no migration or
  package. Fewer taps for the common case, no accidental entries, and
  every choice is easy to change later.
- Decided by: team (project-manager plan).

## 2026-11-12: Loan categories hidden in Quick Add
- Decision: The 4 seeded loan categories (Loan Given, Loan Repayment,
  Loan Received, Loan Repayment Received) are not offered in Quick Add
  until the loan screens exist. How they count in totals does not
  change. Lending meanwhile can be a transfer to "Outside".
- Options considered: (a) hide; (b) show, counted as spending / income;
  (c) show and leave loan categories out of every total.
- Reason: Quick Add cannot link an entry to a loan, so such entries would
  count as normal spending and need a data fix later.
- Decided by: owner (session 4 plan Q1).

## 2026-11-12: Undo in the saved toast
- Decision: Keep Undo in the 4s saved toast (soft delete via the existing
  repository). It is not a delete screen.
- Reason: The only way to fix a mistake before the transactions list
  (session 5).
- Decided by: owner.

## 2026-11-12: Session 4 build choices (Quick Add)
- Decision:
  1. Saved entries go through an app-wide `quickAddSavedProvider`. The
     shell shows the toast with Undo from it, so the toast shows even if
     the sheet is swiped away while the save is running. A route check
     stops a second pop of the sheet.
  2. The toast and date picker themes use elevation 0 (flat rule).
     Material cannot apply the `shadowFloat` token to a dialog, so the
     date picker has no shadow and the scrim separates it.
  3. The amount hint line always keeps its space, so nothing jumps when
     a hint shows or goes.
  4. The amount rolls (`RollingAmount`, `durationSlow`) only when a
     recent entry is applied, never while typing.
  5. New size tokens: `categoryLabelMaxWidth` 160, `recentLabelMaxWidth`
     120, `notePillMaxWidth` 200, `typeTabInset` 2, `quickAddErrorHeight`
     280, `quickAddSheetHeightFraction` 0.92. Added to DESIGN.md.
  6. Reduce motion uses zero durations (instant), per the existing
     project rule (`AppMotion.resolve`).
  7. The app theme is built once (`AppTheme.light()` returns one cached
     `ThemeData`), so rebuilds do not start a theme animation.
  8. Category usage groups by `+category_id`, so SQLite uses `ix_tx_date`
     for the 90-day range. Measured on 20,000 rows: save p50 about
     3.6ms, open data p50 about 35–38ms; the gate is p50 under 250ms.
- Options considered: toast owned by the sheet; a dialog shadow
  workaround; a hint line that collapses; rolling on every key.
- Reason: The toast and Undo must not be lost; flat design rule; no
  layout jumps; rolling digits while typing is distracting.
- Decided by: team (senior-dev, junior-dev, qa-reviewer).

## 2026-11-12: Open after session 4
- Quick Add open time on a real phone (profile mode, target under
  300ms) is not measured yet: there is no device in CI or the cloud
  session. The owner should check it on a phone.
- The bottom sheet theme still uses elevation 16 with `shadowInk`
  instead of a flat or `shadowFloat` style. Align it later.
- DESIGN.md's toast rule still lists `shadowFloat`; the built toast is
  flat (elevation 0). Update DESIGN.md or the toast to match.
  (Closed 2026-11-13: DESIGN.md now says the toast is flat.)

## 2026-11-13: Design polish session pre-approved
- Decision: A design polish session runs before roadmap session 5
  (plan: `docs/plans/design-polish.md`). The build starts right after
  the plan, without waiting for approval. DESIGN.md is updated first.
  No schema change; nothing from later sessions.
- Decided by: owner (pre-approved).

## 2026-11-13: 3D mascot package
- Decision: `flutter_3d_controller`.
- Options considered: `model_viewer_plus` (same web engine, but
  animations only via raw JS / attributes, no controller API);
  `flutter_scene` (native Flutter GPU, but needs Impeller and the
  experimental Flutter GPU flag, not stable on Android, API still
  changing); `three_dart` / `flutter_gl` (unmaintained).
- Reason: Plays named glTF animations from a Dart controller, supports
  .glb with embedded textures, iOS and Android, actively maintained.
- Trade-off: It uses a WebView (memory, first-load cost). Mitigated by
  lazy load after the first frame, pause / unmount when off-screen, and
  a still poster fallback.
- Decided by: team (project-manager plan, owner pre-approved).

## 2026-11-13: Demo data in a separate database file
- Decision: Demo data lives in its own DB file
  (`auditor_monkey_demo.sqlite`) instead of tagging rows. A small
  marker file remembers that demo mode is on. Clearing deletes the demo
  file and switches back to the real file. Only available when
  `kReleaseMode` is false; the code path is guarded by that
  compile-time constant, so release builds tree-shake it. A "Demo data"
  ribbon shows while it is on.
- Options considered: a `demo` flag column on every table; demo rows
  with an id prefix in the real DB.
- Reason: Demo data can never mix with real data and no schema change
  is needed.
- Decided by: team (owner pre-approved).

## 2026-11-13: Placeholder 3D model
- Decision: A placeholder `assets/3d/monkey.glb` is generated by
  `tool/make_placeholder_glb.py`: a simple low-poly monkey head shape
  with the five named animations (`idle`, `happy`, `worried`,
  `celebrating`, `sleeping`), well under 3 MB. The owner's real model
  replaces the file later with no code change (requirements in
  DESIGN.md, Mascot).
- Reason: The feature can be built and tested before the real model
  exists; the script makes the file reproducible.
- Decided by: team.

## 2026-11-13: Illustrations
- Decision: Original, hand-written SVG illustrations using the
  DESIGN.md palette only, stored in `assets/illustrations/`, drawn with
  `flutter_svg` (new package). Each under 8KB, decorative (no
  semantics).
- Options considered: stock illustration packs (palette and licence
  issues); PNG images (bigger, blurry at some sizes); Lottie (bigger,
  more motion than needed).
- Reason: Small, sharp at any size, matches the brand exactly, no
  licence risk.
- Decided by: team.

## 2026-11-13: Off-screen detection package
- Decision: `visibility_detector` to pause or unmount the 3D mascot
  when it is off-screen.
- Reason: Small, widely used, works inside scroll views; saves memory
  and battery from the WebView.
- Decided by: team.

## 2026-11-13: Mascot loopback server on Android (lead)
- Decision: `flutter_3d_controller` serves `assets/3d/monkey.glb` to its
  WebView from a small HTTP server on `127.0.0.1`. Android blocks plain
  HTTP by default, so the app gets a `network_security_config.xml` that
  allows cleartext **only** for `127.0.0.1` and `localhost`; everything
  else stays HTTPS-only. The `INTERNET` permission is added to the main
  manifest (the WebView needs it even for loopback; Supabase sync needs it
  in session 9 anyway). iOS needs no change: App Transport Security does
  not apply to loopback IP addresses, and the old
  `io.flutter.embedded_views_preview` flag is no longer needed.
- Options considered: the package's suggested app-wide
  `usesCleartextTraffic="true"`.
- Reason: a money app must not allow plain HTTP to any real host.
- Decided by: team (lead).

## 2026-11-13: Design polish build choices (senior-dev)
- **Motion tokens**: all DESIGN.md tokens added to `AppMotion`.
  `StaggeredEntrance` uses ONE controller (delay + move in one interval),
  so no timers stay pending in tests. Reduce motion returns the child
  as is.
- **Tab fade-through**: `FadeIndexedStack` runs one 400ms controller:
  first 150ms old tab fades out (`curveExit`), then the index swaps and the
  new tab fades in and scales 0.98 to 1 (250ms, `curveEnter`). Only opacity
  and scale; one `RepaintBoundary`.
- **Page push**: `SharedAxisTransition` widget (used by `_slidePage`),
  slide `pageSlideOffset` (24pt) + fade.
- **Quick Add sheet spring**: `sheetSpring` (stiffness 380, damping 0.82)
  is turned into a curve (`AppMotion.sheetSpringCurve`) over 350ms and
  given to `showModalBottomSheet`. The sheet is built on frame 1, so the
  pad works during the spring. Known trade-off: the spring overshoots by
  about 1%, so for a few frames the sheet sits about 8pt above its final
  place. Close stays `durationMedium` / `curveExit`.
- **Save success**: `SuccessCheck` (circle + tick drawn with
  `PathMetric`, `durationSlow`, scale pop 0.8 to 1) inside the saved toast
  only (not "Entry removed").
- **Balance roll-up**: `RollingAmount(rollKey: ...)`. The first time a key
  is shown in an app launch it rolls from 0 (keys live in the in-memory
  `rolledKeysProvider`); later shows are instant; later changes roll old to
  new. Keys: `account:<id>`, `statement:<id>`, `net-worth`. Without a key or
  without a `ProviderScope` nothing changes from before.
- **Mascot**: `MascotView` builds the viewer only after the first frame,
  only while `VisibilityDetector` shows it and the app is resumed;
  otherwise the viewer is unmounted and the poster shows. The viewer is
  built once per mount (never on rebuilds). Viewer creation goes through
  `mascotViewerFactoryProvider`, so tests use a fake. 
  `mascotPosterOnlyProvider` defaults to TRUE under `flutter test`
  (`FLUTTER_TEST` env), so whole-app tests never build the WebView; mascot
  tests override it to false. Tap: light haptic, `happy` once (loop count 1,
  back to the mood after 1.8s). Missing clip uses `idle`. Native taps on
  the model are off (`enableTouch: false`) so the tap is ours.
- **Demo data**: `openAppConnection({fileName, directory})` is still the
  only place that opens files. `appDatabaseProvider` watches
  `demoModeActiveProvider` (guarded by `!kReleaseMode`). The marker file
  `auditor_monkey_demo.on` is read once in `main` before `runApp`
  (`demoModeInitialProvider`). Load: delete any old demo file, open a
  separate `AppDatabase` on the demo file, seed in ONE transaction through
  the normal repositories, close, write the marker, switch. Clear: delete
  the marker, switch back, close the demo database (tracked by
  `DatabaseCloseTracker`), then delete the demo file and its side files.
  The seed is a pure function of "today" (seed 20261113): 90 days, every
  preset account and every default category used, salary on the 1st,
  transfers have no category, no expense or transfer takes an account below
  zero (such entries are dropped in a final pass).
- **Isolate note**: the closure given to `NativeDatabase.createInBackground`
  must not capture non-sendable objects, so it is built in its own function
  that holds only the temp path string.

## 2026-11-13: Open after design polish
- Real-phone checks (no phone in the cloud session): Quick Add open
  time (target under 300ms, profile mode) and the mascot WebView memory
  and first-load time. Owner to check.
- Owner to supply the real `monkey.glb` (requirements in DESIGN.md,
  Mascot). The placeholder stays until then.
- Pre-existing flaky test "logs operations by name and short id": when
  the random UUID's 8-character prefix is all digits, the log redactor
  masks it as a number. Fixed in this session (see next entry).
- Wizard choices made by junior-dev: the mascot replaces the welcome
  illustration on the welcome step, and the review step shows the
  celebrating mascot (there is no separate done step). So the
  `wizard_welcome` and `wizard_done` SVGs are currently shown only in
  the illustrations gallery golden (`illustrations_all.png`).

## 2026-11-13: Short ids in logs are never masked (lead)
- Decision: the log redactor keeps our own short-id marker `id=` plus
  exactly 8 hex characters, even when all 8 are digits. A longer digit
  run after `id=` (a phone or card number) is still masked. The statement
  log now writes `open id=<short id>` too. Tests: redactor cases for
  all-digit ids and for a phone after `id=`, and a repository test with a
  fake id maker whose ids start with 8 digits (`TestEnv(ids: ...)`).
- Options considered: shorter ids (6 characters, loses detail); a
  different separator inside the id; fixing only the test with
  non-random ids (hides the real bug: such logs lost the id in the app
  too).
- Reason: about 1 in 100 UUIDs start with 8 digits; those log lines lost
  their id, and the test "logs operations by name and short id" failed
  at random.
- Decided by: team (lead).

## 2026-11-13: Port mini_checklist's visual system natively (owner)
- Decision: Replace the mint design with mini_checklist's system
  (tokens from `web/styles.css`, the sky and Mimi from
  `web/mimi-world.*`), built natively: `CustomPainter` for the sky and
  the monkey, `Ticker`s for loops, a `Keyframes` helper that ports CSS
  keyframes 1:1. Drop the 3D mascot and its WebView package.
- Options considered: a WebView with the original HTML (rejected by the
  owner, and heavy); `flutter_svg` + transforms per part (SVG parts
  cannot be animated individually without splitting files, and parses
  on every change); Rive / Lottie (new tool and assets, not a port).
- Reason: Owner's request. One painter keeps the monkey at 60 fps with
  no allocations per frame; loops rest after 15s like mini_checklist's
  battery rule; reduce motion turns all movement off.
- Glass: `BackdropFilter` blur 14 + saturate 1.4 with a 1px white inner
  border as asked. mini_checklist turns blur off over its moving sky for
  battery; we keep the blur but share one backdrop per stage
  (`BackdropGroup` + `BackdropFilter.grouped`).
- Fonts: the WOFF2 files from `web/vendor/fonts` converted to TTF with
  fontTools (Flutter does not load WOFF2). Same Latin subset; ₹ comes
  from the system font, as before.
- Contrast: white on coral (2.8:1) and the coral "today" number are
  kept for the look, as in mini_checklist; used only for bold labels and
  with semantics. `success` darkened to `#33801A` and `accentText` to
  `#C2410C` so small text stays AA.
- "Month left" with no budgets uses income minus spending, so Home is
  useful before budgets exist (budgets come in roadmap session 5).
- Decided by: owner (look), lead (build choices).

