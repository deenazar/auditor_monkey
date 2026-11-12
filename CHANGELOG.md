# Changelog

One entry per pull request, grouped as Added / Changed / Fixed / Security.

## 2026-11-12: Session 2, data model and Drift database (PR: -)

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
