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
