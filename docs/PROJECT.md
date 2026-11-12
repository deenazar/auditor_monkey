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
Source: `docs/design/reference.png` (the owner's reference screenshot).
Style: light, fresh and flat. Mint-green and soft-yellow blocks on
white, dark-green text, rounded shapes, thin outline icons, no heavy
shadows. Light theme only in Phase 1 (see "Unclear in the reference").

Hex values were sampled from the image. Sizes are converted from image
pixels to Flutter logical pixels (the phone in the image is about 472px
wide, so 1px in the image is about 0.83pt) and then rounded to the 4pt
grid.

### Colour palette
| Token | Hex | Use |
|-------|-----|-----|
| `background` | `#FFFFFF` | Screen background |
| `canvas` | `#F5F5F5` | Behind sheets and dialogs; app background behind the bottom bar on Android |
| `tile` | `#F7F7F7` | Small stat tiles (Spendings / Savings style) |
| `primary` (mint) | `#70D0B2` | Hero header, main card, active chart series, progress fill |
| `primaryLight` | `#8CD6A6` | Top of the area-chart gradient |
| `primaryDeep` | `#476E61` | Dark side-tab on cards, selected chip, pressed state |
| `accentText` | `#2A8466` | Green text on white: small titles ("Your Wallet" style), links, income amounts |
| `lime` | `#E4E782` | Summary card that overlaps the hero; second chart series |
| `sun` (yellow) | `#FDD85C` | Third chart series, highlights, notification dot area |
| `notifDot` | `#DCE91D` | Unread badge dot |
| `ink` | `#1E3B31` | Main text and big numbers (dark green, not black) |
| `inkMuted` | `#5F7670` | Secondary text: sub-labels, dates, amounts in lists |
| `iconInactive` | `#868E8B` | Inactive nav icons |
| `divider` | `#ECEFEE` | Hairline dividers, chart grid lines |

Status colours (tuned to sit with the palette):

| Token | Hex | Use |
|-------|-----|-----|
| `success` | `#3FA37F` | Budget under 80% (bars and icons) |
| `warning` | `#F2B84B` | Budget at 80% or more (bars and icons) |
| `danger` | `#C2453A` | Budget over 100%, delete, errors (also used as text) |

Amounts: expenses shown in `ink` with a minus sign (as in the
reference); income in `accentText` with a plus sign; transfers in
`inkMuted` with a ⇄ icon.

### Account colours (tuned to the palette)
| Account | Colour | Hex | Text on it |
|---------|--------|-----|------------|
| Axis | Yellow | `#FDD85C` (the reference's yellow) | `ink` |
| SBI | Magenta | `#C2457F` (softened, a little dusty) | white |
| SCB | Green | `#4CB58E` (deeper than mint so it does not merge with the brand colour) | `ink` |
| Hand | Orange | `#F59E5B` (warm, soft) | `ink` |
| Food Card | Lime (suggested) | `#C9D86A` | `ink` |
| Outside | Sky blue (suggested) | `#6BB8E0` | `ink` |
| PF | Deep green (suggested) | `#476E61` | white |

Each pair passes WCAG AA for normal text (4.5:1 or better).

### Typography
- Font: a rounded geometric sans. Assumed **Outfit** (free, Google
  Fonts), the closest free match; see "Unclear in the reference".
- Amounts always use tabular figures (fixed-width digits), so animated
  numbers do not jump.

| Style | Size / weight | Example from reference |
|-------|---------------|------------------------|
| `displayAmount` | 40 / Light 300 | Big balance "1,268.43" |
| `displayTitle` | 32 / Regular 400 | "Your cards" |
| `headline` | 22 / Medium 500 | Stat on summary card "+12%" |
| `title` | 18 / Medium 500 | Greeting "Hello Jason" (name in SemiBold 600), section "Last Transaction" |
| `bodyStrong` | 15 / SemiBold 600 | List item name |
| `body` | 15 / Regular 400 | List date, normal text |
| `caption` | 13 / Regular 400 | Sub-labels ("Spendings", list amount) |
| `overline` | 11 / Medium 500, all caps, letter-spacing 2.5 | "AVAILABLE FUNDS", "SPENDINGS" |

- The ₹ sign is drawn lighter and smaller than the digits (about 75%
  size, Light weight), as the $ is in the reference.

### Spacing and layout
- 4pt grid: 4, 8, 12, 16, 20, 24, 32, 40.
- Screen side padding 24pt (the reference shows about 40pt, which is
  too wide for ₹ amounts on small phones).
- Space between list rows 20pt; between sections 32pt.
- Content is centred in hero headers and page titles; lists are left
  aligned with the date or amount right aligned.

### Shapes, cards and shadows
- Corner radius: hero header 32pt (bottom corners), cards and summary
  card 20pt, stat tiles 20pt, chips and buttons 999 (pill), avatars
  circle, chart bars fully rounded.
- Cards are flat colour blocks with no border.
- Shadows: none on cards. One very soft shadow only for things that
  float above content (Quick Add button, bottom sheets):
  `0 4 16 rgba(30,59,49,0.12)`.
- Signature layering: a summary card (lime) overlaps the bottom edge of
  the mint hero header by about half its height.
- Account cards: horizontal carousel. The current card is full width;
  the next card peeks in from the right edge (about 24pt) in its own
  colour. A dark side-tab (`primaryDeep`) on the left shows the account
  name in vertical text.

### Icons
- Thin outline icons, about 1.5pt stroke, rounded ends: **Lucide**
  (`lucide_icons_flutter`). 24pt in the nav bar, 20pt inline.
- Active icon in `primary` (filled background is not used); inactive in
  `iconInactive`.
- Category chips use a small coloured dot or outline icon, never emoji.

### Charts (fl_chart)
- **Area chart** (balance over time): smooth curved line, 2pt, white
  when on the mint hero (`ink` when on white); fill is a vertical
  gradient from `primaryLight` to transparent; a small filled dot marks
  the latest point; no axes or grid on the hero.
- **Doughnut** (account balances, category share): thick ring (about
  25% of the radius), segments with rounded ends and a small gap,
  white centre with the key number in `ink`. Series order: mint, lime,
  yellow, then account colours.
- **Bar chart** (income vs expense, savings): thin pill-shaped vertical
  bars (6pt wide, fully rounded), bars may be centred around a middle
  line as in the "Savings" tile; mint for income, yellow for expense.
- Charts animate in on first show (400ms ease-out) and animate between
  values when data changes.

### Navigation
- Bottom bar: white, no labels, 5 slots, icons only:
  Home (dashboard), Insights (charts), **Quick Add +** (centre),
  Transactions, Accounts.
- In the reference the centre slot is the profile photo. We replace it
  with the Quick Add button: a mint circle (56pt) with a white + icon
  and the soft float shadow. Profile and settings move to an avatar
  in the top bar of Home.
- Screens open with a small green overline-style title and a large
  `displayTitle` ("Your Wallet" / "Your cards" pattern).

### Screen patterns
- **Home / Dashboard**: mint hero header (greeting, bell with dot,
  overline label, big total, area chart) → overlapping lime summary
  card (e.g. This Month Spent and Budget remaining) → stat tiles →
  "Recent transactions" list.
- **List rows**: leading circle (category or account icon on a tinted
  circle; the reference shows a photo), title + amount below in
  `caption`, date on the right.
- **Stat tiles**: `tile` background, overline label at top centre, one
  chart or number centred.

### Motion
- Smooth and subtle, 150–300ms, ease-out to enter, ease-in to leave.
- Numbers roll/count to new values (balances, totals, percentages).
- Charts draw in and morph between values.
- Card carousel snaps with a soft spring; list rows slide and fade on
  insert/delete.
- Respect the phone's "reduce motion" setting (show final values
  instantly).

### Accessibility
- Text contrast WCAG AA. The reference puts white text on mint
  (`#FFFFFF` on `#70D0B2` is only 1.85:1, which fails). We use `ink`
  text on mint instead (6.6:1); white is used only on `primaryDeep`
  and SBI/PF cards.
- Tap targets at least 44pt. Supports large text sizes without
  cutting off amounts.

### Unclear in the reference (and what we assumed)
1. **Font name**: not stated. Looks like a geometric rounded sans
   (Gilroy / Sofia Pro style, which are paid). Assumed **Outfit** as a
   free close match. Owner can swap it in one place (theme).
2. **Exact colours**: the image is compressed, so edges are blurred.
   Hex codes are the most common pixel values inside each flat block;
   text colours are estimated from the darkest pixels and rounded to
   one dark green (`ink`) and one muted green (`inkMuted`).
3. **White text on mint** fails contrast; switched to dark text (see
   Accessibility).
4. **Dark mode**: the reference only shows a light theme. Assumed light
   only for Phase 1; dark mode can be added later from the same tokens.
5. **Centre nav slot**: the reference has a profile photo; we need a
   Quick Add + button there (Feature 2). Profile moved to Home's top bar.
6. **Red / amber / income colours**: not in the reference. Added
   `success`, `warning`, `danger` tuned to the palette.
7. **Accounts beyond the four named**: colours for Food Card, Outside
   and PF are suggestions.
8. **Photos and avatars**: the reference shows people photos in
   transactions. A personal tracker has categories, not people, so
   rows use category icons on tinted circles.
9. **What the yellow sliver and "42" on the card mean**: read as "the
   next card peeking in" and "a small badge" (e.g. number of
   transactions this month). Assumed decorative patterns only.
10. **Exact sizes**: measured from a mock-up image, not a design file,
    so they are approximate and rounded to the 4pt grid.

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
| design-taste | `h3nryprod01/design-taste` | UI design quality and reviews. Its web-only checks (CSS, `scripts/preflight.mjs`) do not apply to Flutter; the Design section above wins on colours, fonts and brand. |

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

1. **Project setup**: Flutter app, Riverpod, go_router, theme (light
   mint palette and tokens from the Design section, Outfit font,
   account colours, Lucide icons), central logger, paise formatting helper,
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
