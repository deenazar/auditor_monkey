# Auditor Monkey

## Overview
Auditor Monkey is a personal money tracker that fully replaces the
owner's Excel sheet. It records expenses, income and transfers across
all accounts, shows live balances, tracks monthly budgets, and keeps a
full history. It works fully offline: anything added without a network
is saved on the phone and synced to the cloud later.

- Currency: Indian Rupee only. Money is stored as integer **paise** and
  shown in Indian format, e.g. `₹1,23,456.00`.
- Balances are always calculated from transactions, never typed in.
- Transfers move money between accounts and are never counted as
  income or expense.

## Users
- One user: the owner (personal use).
- iPhone and Android phone, used many times a day for quick entries.
- No sharing, no multi-user, no admin.

## Features

### Phase 1 (MVP: replace the sheet for daily use)
1. **Onboarding and security**: sign in with Google, Apple or phone OTP;
   app lock with Face ID / fingerprint / PIN; setup wizard to add
   accounts (Hand, SBI, Axis, SCB, Food Card, Outside, PF) with opening
   balances.
2. **Quick Add** (most important screen): one floating + button with
   tabs Expense / Income / Transfer. Big number pad first, then category
   chips with colour groups, account, date (default today), note.
   Transfer picks From and To and updates both balances; it is never
   counted as an expense. Recent and frequent categories on top.
   Duplicate a past entry with one tap.
3. **Accounts**: live balance cards in each account's colour. Tap an
   account to see its statement with running balance and an
   income-vs-expense bar chart.
4. **Dashboard**: top cards This Month Spent, Budget, Remaining, Income,
   Net Worth. Account balance doughnut, top 3 expense categories
   (excluding transfers and loans), recent transactions.
5. **Monthly budgets**: budget per category, resets every month.
   Progress bar green, amber at 80%, red when over. Notifications at 80%
   and 100%, e.g. "Groceries is at 85% of ₹3,000".
6. **Transactions list**: search, filter by month, account or category,
   swipe to edit or delete.
7. **Import from Excel**: upload the existing `.xlsx`; existing EX/IN
   rows come in with full history.
8. **Export and backup**: export to Excel / PDF, automatic cloud backup.

### Phase 2 (tables created in Phase 1, screens later)
9. **Loans**: money lent and borrowed, with repayments.
10. **Gold**: gold holdings and daily gold rates, current value.
11. **Daily Activities**: a simple daily log.

## Out of scope
- Multiple users, family sharing, web or desktop apps.
- Bank, SMS or UPI auto-import.
- Currencies other than INR.
- Investments other than gold and PF (stocks, mutual funds).
- Receipt photos / OCR.

## Tech stack
| Area | Choice |
|------|--------|
| App | Flutter (iOS + Android, one codebase), Dart. Flutter SDK pinned in `.claude/hooks/session-start.sh` (currently 3.47.9 stable) |
| State | Riverpod |
| Navigation | go_router |
| Local DB | SQLite with Drift, encrypted with SQLCipher; key kept in the phone's secure storage (Keychain / Keystore) |
| Offline sync | Local DB is the source of truth. Every row has a UUID, `updatedAt`, `deletedAt` (soft delete) and a sync status; a queue pushes changes when online |
| Backend | Supabase: auth (Google, Apple, phone OTP), Postgres for cloud sync, Storage for backups. Row Level Security on every table |
| Charts | fl_chart |
| Notifications | Firebase Cloud Messaging (remote) + flutter_local_notifications (budget alerts, which work offline) |
| Security | Face ID / fingerprint (local_auth) + PIN lock, encrypted DB, secure storage for tokens |
| Excel / PDF | An xlsx package for import and export, plus a PDF package (exact packages chosen in their sessions and logged) |
| Tests | flutter_test (unit and widget), integration_test for the main flow |
| Lint | `flutter analyze` with the recommended lints |

### Data model (all tables created in roadmap session 2)
All money columns are integer paise. All tables also have `id` (UUID),
`createdAt`, `updatedAt`, `deletedAt` and `syncStatus`.

| Table | Key fields |
|-------|------------|
| Accounts | name, type (cash / bank / card / wallet / PF / other), colour, openingBalance, sortOrder, archived |
| Categories | name, kind (expense / income), colourGroup, icon, sortOrder, archived |
| Transactions | type (expense / income / transfer), amount, date, accountId, toAccountId (transfers only), categoryId (not for transfers), note, loanId (optional), importSource |
| Budgets | categoryId, month (YYYY-MM), amount |
| Loans | direction (lent / borrowed), person, principal, startDate, dueDate, note, closed |
| GoldHoldings | description, weightMg, purity (24K / 22K / 18K), purchaseDate, purchasePrice, accountId (optional) |
| GoldRates | date, purity, ratePerGram (paise) |
| DailyActivities | date, title, note |

Rules:
- Account balance = opening balance + income − expense ± transfers.
- Transfers have no category and are excluded from spending, budgets
  and "top categories". Loan-linked entries are excluded from "top
  categories".
- Amounts are always positive; the type decides the direction.

## Design
All design tokens and rules live in **[DESIGN.md](../DESIGN.md)** at the
repo root: colours (hex), typography, spacing, radius, shadows, icons,
charts, motion, navigation, screen patterns, accessibility and the
design assumptions. The reference image is
[`docs/design/reference.png`](design/reference.png).

Summary: light mint design. White background, mint `#70D0B2` hero and
cards, lime and yellow accents, dark-green `#1E3B31` text, Outfit font,
flat rounded cards, Lucide outline icons, Quick Add + in the centre of
the bottom bar. A Motion & 3D layer (tilt, parallax, blobs, confetti,
2.5D mascot) sits on top without changing the base. Use the DESIGN.md token names in code; if code and
DESIGN.md disagree, DESIGN.md wins.

## Folder structure
Feature-first, per the flutter-mobile-design skill:
```
lib/
  main.dart
  app/                  app.dart (MaterialApp, theme), router.dart
  core/
    database/           Drift database, tables, DAOs, migrations
    sync/               sync queue and Supabase sync
    security/           app lock, secure storage, DB key
    logging/            central logger
    money/              paise <-> ₹ formatting and parsing
    utils/
  features/<feature>/
    presentation/       screens and widgets
    application/        Riverpod providers / notifiers
    domain/             models and rules
    data/               repositories
  shared/
    widgets/            reusable widgets
    theme/              colours, text styles, motion constants
test/                   mirrors lib/ (unit and widget tests)
integration_test/       main-flow tests
docs/                   PROJECT.md, DECISIONS.md, FEATURES.md
```
- Files `snake_case.dart`; classes `PascalCase`.
- One public widget per file; keep files under ~300 lines.
- Generated files (`*.g.dart`, Drift) are not edited by hand.

## Project skills
Installed from the skills-catalog into `.claude/skills/`:

| Skill | Source | Use for |
|-------|--------|---------|
| flutter-mobile-design | `saaip7/ipdev-mobileapps-skill` | All Flutter UI, screens and architecture. Note: its Riverpod example uses the older `StateNotifier`; we use the current `Notifier` / `AsyncNotifier` API instead. |
| design-taste | `h3nryprod01/design-taste` | UI design quality and reviews. Its web-only checks (CSS, `scripts/preflight.mjs`) do not apply to Flutter; DESIGN.md wins on colours, fonts and brand. |

## Performance targets
- Cold start to usable screen: under 2s on a mid-range phone.
- Quick Add opens in under 300ms; saving an entry offline in under 100ms.
- Smooth 60fps scrolling and animations.
- Transactions list stays smooth with 20,000+ rows (paged, lazy lists).
- Balances and dashboard totals come from SQL sums, not by loading all
  rows into memory.
- Excel import of 10,000 rows in under 30s, with progress shown, off
  the main thread.

## Roadmap
One item per session, offline-first. Each session follows the
feature-workflow skill (plan → owner approval → build → QA → PR).

1. **Project setup**: Flutter app, Riverpod, go_router, theme (all tokens
   from DESIGN.md: light mint palette, Outfit font, account colours,
   Lucide icons), central logger, paise formatting helper,
   lint and test setup.
   Done when: app runs on iOS and Android, `flutter analyze` and tests
   pass, `₹1,23,456.00` formatting is tested.
2. **Data model + Drift DB**: all 8 tables, DAOs, balance rules, seed
   categories, migrations set up.
   Done when: unit tests prove balance and transfer rules on an
   in-memory DB.
3. **Accounts + setup wizard** (Features 1 part, 3): wizard with opening
   balances, account cards, statement with running balance and bar
   chart.
   Done when: balances match the sum of transactions after reload.
4. **Quick Add** (Feature 2): expense / income / transfer, number pad,
   category chips, recent/frequent, duplicate entry.
   Done when: an entry saves offline in under 100ms and a transfer
   changes both balances but no spending totals.
5. **Transactions list** (Feature 6): search, filters, swipe to edit or
   delete.
   Done when: filters combine correctly and the list is smooth with
   20,000 rows.
6. **Dashboard** (Feature 4): top cards, doughnut, top 3 categories,
   recent transactions.
   Done when: every number matches a hand-checked test month.
7. **Budgets + local notifications** (Feature 5): per-category monthly
   budgets, colour states, 80% and 100% alerts.
   Done when: each alert fires once per category per month, offline.
8. **App lock + encrypted DB** (Feature 1 part): Face ID / fingerprint /
   PIN, SQLCipher encryption with the key in secure storage.
   Done when: the DB file cannot be opened without the key and the app
   locks when reopened.
9. **Login + Supabase sync/backup** (Features 1 part, 8 part): Google,
   Apple, phone OTP; two-way sync of offline changes; automatic backup;
   FCM set up.
   Done when: an entry added in airplane mode appears in Supabase after
   reconnecting, and a reinstall restores all data.
10. **Excel import** (Feature 7): upload `.xlsx`, map EX/IN rows to
    transactions with full history, show a preview and import summary.
    Done when: imported totals per month match the sheet.
11. **Export Excel / PDF** (Feature 8 part): export filtered
    transactions to `.xlsx` and a PDF statement.
    Done when: the export opens in Excel and matches the app's totals.

Phase 2 (after the roadmap above): 12 Loans, 13 Gold holdings and
rates, 14 Daily Activities.
