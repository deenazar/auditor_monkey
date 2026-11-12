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
