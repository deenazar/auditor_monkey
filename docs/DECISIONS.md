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
