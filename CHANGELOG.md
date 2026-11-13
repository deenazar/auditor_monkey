# Changelog

One entry per pull request, grouped as Added / Changed / Fixed / Security.

## 2026-11-13: Design polish (PR: -)

### Added
- Motion tokens from DESIGN.md in `AppMotion`, and a staggered entrance
  for cards and list rows (`StaggeredEntrance`).
- Balance roll-up: balances and net worth roll from 0 the first time
  they show in each app launch, then roll from the old to the new value
  when they change.
- Saved toast in Quick Add now shows a drawn success check
  (`SuccessCheck`).
- 11 original SVG illustrations in `assets/illustrations/` (empty
  states, error, wizard, mascot poster), drawn by the new
  `AppIllustration` widget. Decorative only (no semantics).
- 3D Auditor Monkey mascot on Home and in the setup wizard
  (`MascotView`). Moods: idle, happy, worried, celebrating, sleeping.
  A tap plays `happy` once. Loads after the first frame, unmounts when
  off-screen or the app is in the background, and shows a still poster
  when the 3D view is not available.
- Placeholder model `assets/3d/monkey.glb` (70KB) with the five named
  animations, made by `tool/make_placeholder_glb.py`.
- Demo data (debug and profile builds only): 3 months of Indian
  personal finance entries in a separate database file, one-tap clear,
  and a "Demo data" ribbon while it is on.
- New goldens and updated ones, listed with pictures in
  `docs/plans/design-polish-goldens.md`.
- Packages: flutter_3d_controller, flutter_svg, visibility_detector.

### Changed
- Quick Add sheet opens with a spring; the number pad works from the
  first frame.
- Tab switch is a fade-through (old tab fades out, new tab fades and
  scales in).
- Pages pushed inside a tab (for example the statement) use a
  shared-axis slide and fade.
- Empty and error states use illustrations instead of large icons.
  `accounts_empty.png` golden replaced by
  `accounts_empty_illustration.png`.
- All new motion respects reduce motion (final state at once).
- No schema change.

### Security
- Android network security config: plain HTTP is allowed only to
  `127.0.0.1` and `localhost` (the mascot's local file server);
  everything else stays HTTPS only. `INTERNET` permission added.
- Demo data code runs only when `kReleaseMode` is false, so release
  builds do not include it, and demo entries never mix with real data.

### Fixed
- Logs keep short row ids that are all digits (about 1 in 100 ids were
  masked as `[number]`); this also fixes a randomly failing logging test.

## 2026-11-12: Session 4, Quick Add (PR: -)

### Added
- Quick Add sheet behind the centre +: tabs Expense / Income / Transfer,
  number pad on screen at once, amount with live Indian grouping,
  category chips (up to 6 suggested first, then the rest) and an "All"
  sheet grouped by colour group, account picker with balances, From /
  swap / To for transfers, "Today" / "Yesterday" chips plus a date
  picker (up to 31 days ahead), note sheet, Save.
- Last-used account and category per type are picked by default. An
  expense with the right defaults takes 3 steps: open, type amount,
  save.
- "RECENT" strip: up to 6 distinct recent entries; a tap fills the form
  (Save still needed).
- Saved toast above the nav bar with Undo (4s), shown even if the sheet
  was closed while saving.
- States: loading, typing, amount refused, transfer disabled (one
  account), saving, save error, no categories, load error.
- Read-only Quick Add queries (last used per type, category usage,
  recent entries) in `transactions_quick_add_queries.dart` and
  `QuickAddRepository`. No schema change.
- Category colour groups: each group uses an existing colour token at
  20% tint (DESIGN.md). Statement rows now use the group tint.
- New DESIGN.md tokens in code: `numPadKeyHeight`, `chipHeight`,
  `chipIconCircle`, `quickAddSheetHeightFraction`,
  `categoryLabelMaxWidth`, `recentLabelMaxWidth`, `notePillMaxWidth`,
  `typeTabInset`, `quickAddErrorHeight`, motion `toastDuration`. Rules
  for choice chips, segmented tabs, number pad keys, refused input and
  the toast. Toast and date picker themes from tokens.
- Tests: amount parsing and refusal cases (no rounding, no doubles),
  defaults, category order, recent de-duplication, validation, queries,
  notifier (double save saves once), money correctness (expense, income,
  both sides of a transfer, spending totals unchanged by transfers,
  Undo), logs, performance on 20,000 rows, widget tests and 19 new
  goldens.

### Changed
- `statementPageSql` also returns the category colour group.
- Loan categories are not offered in Quick Add (owner decision); how
  totals count them did not change.

### Fixed
- The app theme is now built once, so rebuilds no longer start a theme
  animation.

### Security
- Quick Add logs show only the type, timings, counts and failure codes;
  never amounts, notes, names, dates or clipboard text (tested).

## 2026-11-12: Session 3, accounts and setup wizard (PR: [#9](https://github.com/deenazar/auditor_monkey/pull/9))

### Added
- Setup wizard on first launch (`/setup`): welcome, pick accounts (7
  presets plus your own), opening balances (card accounts get an
  "I owe" toggle), review with starting net worth. "Create accounts"
  saves all accounts in one go, all or nothing.
- Start screen (`/start`): loading ring after 300ms; on a database
  error a safe message and "Try again" (re-opens the database, never
  wipes data).
- Accounts tab: net worth (rolls on change), card carousel in each
  account's colour with spring snap, and an "All accounts" list.
  Loading, empty and error states.
- Account statement (`/accounts/:accountId`): balance card, 6-month
  income-vs-expense pill bar chart, entries newest first with the
  running balance after each one, opening balance as the last row.
  Pages of 50, next page at 80% scroll, live refresh.
- "Edit account" sheet on the statement and "Add account" on the
  Accounts screen (name, type, colour, opening balance). No archive or
  delete UI.
- The 7 preset accounts have fixed, hard-coded ids; custom accounts get
  random ids.
- New queries: statement page with running balance in SQL, monthly
  income / expense per account, "has live account", one account's
  balance, max sort order. `createAll`, `addAccount`, `editAccount` in
  `AccountsRepository`.
- Shared widgets: `PageHeader`, `AmountText`, `PrimaryButton`,
  `AppTextField`, `EmptyState`, `ErrorState`, `SkeletonBlock`,
  `StepDots`, `RollingAmount`, `StatTile`, category icons, money input
  formatter.
- New DESIGN.md tokens in code (`AppSizes`, `AppMotion`): component
  sizes (card, side-tab, peek, button, field, icon circle, colour dot,
  swatch, chart, step dots, icon sizes, progress ring, field line,
  chart bar and grid line) and the spring stiffness / damping values.
- Golden tests (20 PNGs under `test/**/goldens/`), with Outfit, Lucide
  and a test-only Roboto ₹ fallback loaded in
  `test/flutter_test_config.dart`. CI uploads `**/failures/*.png` as an
  artifact when tests fail.
- Acceptance test: balances match the sum of transactions after the
  database is closed and reopened.
- Package: fl_chart 1.3.1 (pinned).

### Changed
- App start now goes `/start` → `/setup` (no accounts) or the normal
  tabs. `test/app/app_test.dart` uses an in-memory database.
- `accountBalancesProvider` and `netWorthProvider` no longer retry, so
  error states show.

### Security
- Logs from the wizard, statement and account edits show no account
  names or amounts (tested).
- The start screen never shows the raw error; it is logged instead.

## 2026-11-12: Session 2, data model and Drift database (PR: https://github.com/deenazar/auditor_monkey/pull/7)

### Added
- Drift database, schema version 1, with all 8 tables: accounts,
  categories, transactions, budgets, loans, gold_holdings, gold_rates,
  daily_activities. Every row has a UUID v4 id, `created_at`,
  `updated_at`, `deleted_at` (soft delete) and `sync_status`.
- Money stored as whole paise only; database CHECK rules block decimals,
  zero or negative amounts, bad dates and broken transfer rules.
- 34 default categories (26 expense, 8 income) with fixed ids, added on
  first launch only.
- One SQL query for all account balances; spending, budget and income
  sums that leave out transfers and loan entries; loan outstanding
  amount; gold current value.
- Repositories and plain Riverpod providers for every table (for
  example `accountBalancesProvider`, `netWorthProvider`,
  `budgetsForMonthProvider`). Clear typed errors instead of crashes.
- Migration setup: `build.yaml` for `drift_dev make-migrations`, v1
  schema dump in `drift_schemas/app/`, schema check and dump guard
  tests.
- Unit tests on an in-memory database: CRUD, balances, transfers, soft
  delete and restore, validation, money precision, loans, gold, query
  plans and 20,000-row timings.
- `docs/DATABASE.md`: tables, rules and the step-by-step guide for
  changing the schema.
- Packages: uuid, path_provider, path, sqlite3 (bundles SQLite).

### Security
- The database is opened in one file only
  (`lib/core/database/connection/open_connection.dart`), ready for
  SQLCipher in session 8.
- SQL statement logging is off. Logs show only the action and a short id
  prefix, never amounts, names, notes or people.
- Android `allowBackup` is off until the database is encrypted.

## 2026-11-12: Session 1, project setup (PR: https://github.com/deenazar/auditor_monkey/pull/6)

### Added
- Flutter app for iOS and Android (`com.deenazar.auditormonkey`),
  feature-first folders (`lib/app`, `lib/core`, `lib/features`,
  `lib/shared`).
- Packages: flutter_riverpod, go_router, drift (tables added in
  session 2),
  drift_dev, build_runner, lucide_icons_flutter, flutter_lints.
- Strict lint rules in `analysis_options.yaml`.
- Outfit font (300 / 400 / 500 / 600) bundled as assets, with its OFL
  licence shown in the app's licence page.
- `AppTheme` and token files in `lib/shared/theme/` built from
  `DESIGN.md` (colours, type, spacing, radius, shadow, motion), light
  mode only.
- Bottom nav: Home, Insights, Quick Add (+) centre, Transactions,
  Accounts. Placeholder screens; Quick Add opens an empty bottom sheet.
  Active tab: `ink` icon on a soft mint pill (`navIndicator`).
- Central logger (`AppLogger`) with levels, release-mode debug off,
  redaction of sensitive values, and app error capture.
- Money helpers: `formatPaise` and `parseRupeesToPaise`, with tests.
- GitHub Actions CI on pull requests and pushes to main: format check,
  `flutter analyze --fatal-infos`, `flutter test` on Flutter 3.47.9.
- Widget test: app launches and the bottom nav shows 5 items.

### Security
- Logs never contain amounts, emails, long numbers or tokens.
- CI runs with read-only permissions.

## 2026-11-12: New design from reference screenshot

### Added
- `docs/design/reference.png`: the owner's design reference.

### Changed
- `DESIGN.md` at the repo root: all design tokens (colours as hex,
  typography, spacing, radius, shadows, icons, charts, motion,
  navigation) and the design assumptions with their approval status.
- Design section of `docs/PROJECT.md` replaced with a short summary
  and a link to `DESIGN.md`; the dark navy theme is gone.
- Roadmap session 1 now sets up the new theme.
- `docs/DECISIONS.md`: logged the design change.

## 2026-11-12: Project kickoff

### Added
- `docs/PROJECT.md`: overview, users, Phase 1 and 2 features, out of
  scope, tech stack, data model, design, folder structure, project
  skills, performance targets and the 11-session roadmap.
- `docs/DECISIONS.md` with the first decisions (Flutter, Riverpod,
  Drift, offline-first, Supabase, paise, login built late, pinned
  Flutter SDK).
- `docs/FEATURES.md` with all features marked Planned.
- Project skills `flutter-mobile-design` and `design-taste` in
  `.claude/skills/`, tracked in `skills-lock.json`.
- SessionStart hook (`.claude/hooks/session-start.sh`, registered in
  `.claude/settings.json`) that installs Flutter 3.47.9 in Claude Code
  cloud sessions and runs `flutter pub get` once `pubspec.yaml` exists.
