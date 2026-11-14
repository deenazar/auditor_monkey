# Session 6 plan: Dashboard

- Roadmap item 6 (Feature 4). Status: **Approved 2026-11-14, built**.
- Date: 2026-11-13. Planned by project-manager.
- Suggested branch: `feature/20261113-dashboard` (from `develop`).
- Done when: every number matches the hand-checked test month (section 5).
- No schema change. No new package (fl_chart 1.3.1 and flutter_svg are
  already in).

## 1. Summary
The Dashboard **is the Home tab, extended**. We do not build a second
screen.

Why:
- DESIGN.md Navigation already names slot 1 "Home (dashboard)".
- FEATURES.md says "App opens to Dashboard".
- Home already shows Net Worth, this month's spending and recent
  transactions.
- Home is the Quality bar, so the new parts sit inside the screen that
  sets the bar.

Insights (the chart-pie tab) stays a placeholder. Its purpose is still
open (DECISIONS 2026-11-12).

New on Home:
- Three month tiles: Budget, Remaining, Income.
- An account balance doughnut.
- A Top 3 spending card.
- Recent transactions cut to 5 rows plus "See all".

The hero (Net Worth) and the lime card (This Month Spent) stay where
they are.

### Dependency on Transactions (Session 5, merged by PR #18)
Checked on 2026-11-13 against the merged code (T0 is done):

- **No changes under us:** the merge did not touch `TransactionEntry`,
  `transactions_dao.dart` or `lib/features/home`. Every number still
  comes from develop's `expenseTotal`, `incomeTotal`,
  `expenseByCategory(limit)`, `watchBalances`, `watchNetWorth` and
  `budgetsForMonthProvider`.
- **Same rules as the Transactions tab:** `monthSummarySql` counts only
  live `expense` / `income` rows, leaves out loan-linked rows
  (`loan_id IS NULL`) and uses the whole calendar month. So the
  Dashboard's Spent / Income equal the Transactions tab's Spent /
  Income for the same month (no filter). T3 adds a test that checks
  this on the test month.
- **Drill-downs (no new routes):** set `transactionFilterProvider`
  with `setFacets(TransactionFilter(from:, to:, types:, categoryIds:))`,
  then go to `AppRoutes.transactions`:
  - "See all" → `clear()`, then open the tab.
  - Spent tile → this month + `expense`.
  - Top category row → this month + `expense` + that category.
- **Recent rows:** a tap opens `AppRoutes.transactionDetail(id)` (the
  new detail screen). Swipe edit / delete + Undo reuse the
  Transactions `TransactionActions`, so Home and Transactions act the
  same.
- **Reuse, don't copy:** no second copy of the month SQL. If T2 needs a
  one-read snapshot, it calls the existing DAO methods inside one read
  transaction.
- **Q1 warning:** if the owner picks "leave loan categories out
  everywhere", `monthSummarySql` must change too (it only skips
  loan-linked rows today), or the two tabs show different Spent.

## 2. Number rules (exact)
Notation:
- `M` = the current month `YYYY-MM`, from `currentMonthProvider`.
- `M.start` = `M-01`, `M.end` = the last day (`monthRange(M)`).
- "Live" = `deleted_at IS NULL`.
- "Loan row" = `loan_id IS NOT NULL`.

| # | Number | Rule |
|---|--------|------|
| 1 | **This Month Spent** | SUM(amount) of live `expense` rows, not loan rows, with `date` from `M.start` to `M.end` (see Q2). Transfers never count (only `expense` is summed). Refunds do not lower it (Q4). |
| 2 | **Budget** | SUM(amount) of live budgets where `month = M`. 0 budgets = "No budget yet" (not ₹0.00). |
| 3 | **Remaining** | Budget − This Month Spent. Can be negative: shown in `danger` as "−₹…" with "over budget". With no budget: shows "—" and "Set a budget (coming soon)". See Q3. |
| 4 | **Income** | SUM(amount) of live `income` rows, not loan rows, in `M`. Refunds count here (Q4). |
| 5 | **Net Worth** | Sum of every live account's balance, archived included, cards negative. Balance = opening + income − expense − transfers out + transfers in, over **all** live rows of any date, loan rows included. This is the existing `netWorthProvider`, so it matches the Accounts screen. Gold and loan outstanding are not added (Q5). |
| 6 | **Doughnut slices** | From `accountBalancesProvider`. One slice per live account with balance **> 0**, archived included (they count in net worth). Zero balances: no slice. Negative balances (cards): no slice, shown in a line under the ring, "Owed −₹…" (sum of the negatives). Biggest first, ties by sort order then name. **Max 5 slices**: with more than 5 positive accounts, the 4 biggest + "Other" (sum of the rest). Colour: the account's colour token; "Other" uses `iconInactive`. Centre: "ASSETS" + the sum of the slices. Percent per slice = share of assets, whole %, largest-remainder method so they add to 100. A real share under 1% shows "<1%". |
| 7 | **Top 3 categories** | Live `expense` rows in `M`, not loan rows, grouped by `category_id`, biggest first, ties by `category_id` (the existing SQL). Also leave out the 4 loan category ids (Q1). Show the first 3. Each shows its amount and its share of This Month Spent, whole % rounded half up in integer maths. |
| 8 | **Recent** | The 5 newest live rows of **all** types (transfers and loan rows included; this is a list, not a sum). Order: `date DESC, created_at DESC, id DESC` (the existing `page`). Future-dated rows are included and show their date (Q6). |
| 9 | Saved % (lime card, existing) | `round((Income − Spent) × 100 / Income)`. Hidden when Income is 0. Unchanged, except it now uses the full month (Q2). |
| 10 | Mascot mood (existing) | Now gets the real budget total (`mood(budgetTotal)`, it was `mood(0)`). Plan = Budget if > 0, else Income. |

Other rules:
- **Month boundary / timezone:** dates are stored as the phone's local
  calendar date (`YYYY-MM-DD` text, DECISIONS 2026-11-12), so the month
  is a text prefix. Nothing is converted between time zones.
  "Today" comes from the phone clock (`todayProvider`). The screen
  re-reads it on resume, so it rolls over at midnight and on the 1st
  (small fix: `todayProvider` refreshes when the app resumes).
- **Currency:** INR only. Money is integer paise and is never rounded;
  `formatPaise` is used for display.
- **One snapshot:** spent, income, budget, top 3 and recent are read in
  ONE read transaction, so they always agree. The provider reloads
  when transactions, accounts, categories **or budgets** change.
  Today's change signal does not watch `budgets`; T2 adds it.
- **Overflow:** any `OverflowFailure` shows "A balance is too large to
  show" on that card only.

## 3. Screen
Layout, top to bottom:
1. **Hero** (existing): NET WORTH rolls, area chart, monkey, parallax
   blobs.
2. **Lime card** (existing, tilts): THIS MONTH SPENT + saved %.
3. **Month tiles** (new): one row of 3 compact tiles, Budget /
   Remaining / Income.
   - Tilt3D, SpringPress, haptic.
   - RollingAmount with keys `dash:budget`, `dash:remaining`,
     `dash:income`.
   - Amounts scale down at large text and never clip.
   - Long-press preview shows the sum, e.g. "₹13,000.00 budget −
     ₹31,300.50 spent".
4. **Spendings / Savings tiles** (existing). Kept; Q7 asks whether to
   drop them.
5. **Goal banner** (existing, when shown).
6. **"Where your money is"** (new): doughnut card.
   - Draws in with a sweep (`chartDraw` 900ms) and morphs on change
     (`durationChart`).
   - Tap a slice: it pops out 6pt with a selection haptic, the centre
     label swaps to that account, and the monkey looks at it.
   - Tap the same slice again: opens `/accounts/:id` (3D page turn,
     card Hero).
   - Legend rows below with dot, name, amount and %.
   - The card tilts.
7. **"Top spending"** (new): 3 rows.
   - Category icon circle, name, amount, % and a pill bar that grows
     in, staggered.
   - Tap opens Transactions filtered by month + category.
   - Long-press preview.
8. **"Recent transactions"**: 5 rows (swipe edit / delete + Undo,
   long-press; tap opens the detail screen) plus a "See all" text
   button that opens the Transactions tab with no filter.

Quality bar checklist (adds rows to `motion-illustration-pass.md`):

| Area | Dashboard |
|------|-----------|
| Illustration | Hero monkey (existing). New SVG `empty_top_spending` (under 8KB, palette only) for a month with no spending. Doughnut empty state uses a `MascotMoment` ("Add an account balance to see it here"). Section errors use a worried mascot moment. |
| Motion | Staggered entrance across all sections. All amounts roll. Doughnut sweeps in and morphs. Top 3 bars grow. Shimmer skeletons while loading. |
| 3D | Tiles, doughnut card and top 3 card tilt with layered shadows. Hero parallax (existing). 3D page turn into the statement. |
| Interaction | Haptic on every tap. Springy tiles and "See all". Slice select. Long-press previews. Swipe-delete + Undo. Pull-to-refresh (existing). |
| Mascot | Worried when Remaining turns negative, "Back on track" when it recovers. Looks at the tapped slice and says e.g. "PF holds 50%". Hops on a save (existing). Spins on refresh (existing). |

Reduce motion: no sweep, grow, tilt or stagger; final values at once.
Haptics, moods and speech stay.

States:

| State | What shows |
|-------|------------|
| Loading | Each section's skeleton shimmers. Hero and lime card as today. |
| Empty month (no entries in `M`) | Spent ₹0.00, Income ₹0.00, top 3 empty state, doughnut still shows balances. |
| No accounts | Can't happen (setup redirect). Handled anyway: doughnut mascot moment. |
| No budget | Budget "No budget yet"; Remaining "—". |
| Over budget | Remaining `danger` "−₹…", mascot worried. |
| Only negative balances | Ring hidden, "Owed −₹…" line + mascot moment. |
| Section error | That card shows a worried mascot + "Try again". Others still work. Full-screen error only if the main summary fails (existing). |

## 4. Tasks

| # | Task | Owner | Files | Skills | Acceptance |
|---|------|-------|-------|--------|------------|
| T0 | ~~Read the Transactions data layer and list the APIs to reuse~~ **Done 2026-11-13**, see section 1 "Dependency on Transactions" | senior-dev | this plan (note only) | code-review | Done |
| T1 | Pure rules: `DashboardSummary`, `buildBalanceSlices` (positive only, max 5 → 4 + Other, owed sum, largest-remainder %, "<1%"), `topCategoryShares` (half-up %), `remaining` | senior-dev | `lib/features/home/domain/dashboard_summary.dart`, `balance_slices.dart`, `top_categories.dart` + `test/features/home/domain/` | validation, qa-testing, dataviz (doughnut rules) | Unit tests cover every rule in section 2 rows 3, 6, 7, including ties, all-negative, exactly 5 vs 6 accounts, % sum = 100 |
| T2 | Data: `loadDashboardSummary` in one read transaction (spent, income, budget total, top 3, recent 5) for full month `M`; loan-category filter (Q1); budgets added to the change signal; `todayProvider` refresh on resume; logs | senior-dev | `lib/features/home/application/home_providers.dart`, `dashboard_providers.dart`; if new SQL: `lib/core/database/daos/transactions_dashboard_queries.dart` (extension, like Quick Add) | logging, performance, security, validation | Query-plan test: month sums use `ix_tx_date`. Inputs checked (month key, limit 1..500). Logs: `dashboard load ok ms=… rows=…`, never amounts or names |
| T3 | Test month fixture + numbers acceptance test (section 5), on an in-memory DB through the real repositories | junior-dev | `test/support/fixtures/test_month_2026_10.dart`, `test/features/home/dashboard_numbers_test.dart` | qa-testing | Every value in tables 5.3-5.6 asserted to the paisa; the widget shows the same formatted strings; Transactions `monthSummary` (no filter) gives the same Spent / Income |
| T4 | Widgets with fake data: `MonthTiles`, `BalanceDoughnut` (fl_chart `PieChart`, DESIGN.md doughnut style), `TopSpendingCard`, "See all" | junior-dev | `lib/features/home/presentation/widgets/month_tiles.dart`, `balance_doughnut.dart`, `doughnut_legend.dart`, `top_spending_card.dart`, `see_all_button.dart` | ui-ux-motion, dataviz, performance, qa-testing | Quality bar row done; `RepaintBoundary` around ring; only opacity / transform animate; semantics label per slice ("PF, ₹1,00,000.00, 50%"); 44pt targets; large text 2.0 does not clip |
| T5 | Wire into Home: new sections, mascot reactions, slice → statement, drill-downs (after T0), recent 5. Split `home_screen.dart` (already 428 lines) into section widgets | senior-dev | `lib/features/home/presentation/home_screen.dart`, `widgets/home_sections.dart`, `domain/home_summary.dart` | ui-ux-motion, logging, code-review | File under ~300 lines; mascot uses real budget; existing Home tests still pass |
| T6 | Illustration `empty_top_spending.svg`; goldens: data, loading, empty month, no budget, over budget, all negative, section error, text scale 2, slice selected | junior-dev | `assets/illustrations/empty_top_spending.svg`, `test/features/home/presentation/goldens/` | ui-ux-motion, qa-testing | SVG under 8KB, palette only, decorative; goldens on Linux, 0.5% tolerance |
| T7 | Performance test: 20,000 rows, dashboard load median and p95 recorded | senior-dev | `test/features/home/dashboard_performance_test.dart` | performance | See section 6 |
| T8 | QA + code review | qa-reviewer | - | qa-testing, code-review, security | No High / Medium open; numbers test green |
| T9 | Docs: FEATURES.md (Feature 4), DECISIONS.md (answers to Q1-Q8 + build choices), CHANGELOG.md, DESIGN.md (doughnut legend / slice-select rule), `motion-illustration-pass.md` rows | project-manager | docs only | feature-docs | Docs match what was built |

**Runs in parallel:**
- Start together: T1, T3 and T4. T3 uses only existing repository
  writes plus this plan's tables. T4 uses fake data. T6's SVG can start
  as well.
- T2 after T1.
- T5 after T2 and T4.
- T6 goldens and T7 after T5.
- T8, then T9.

## 5. Hand-checked test month: October 2026
Clock fixed at **2026-10-31 12:00 local** (today = the month's last
day, so month-to-date = whole month). `M = 2026-10`. Amounts are in ₹
(paise = ×100).

### 5.1 Accounts
| Account | Type | Opening | Note |
|---------|------|---------|------|
| Hand | cash | 5,000.00 | preset |
| SBI | bank | 50,000.00 | preset |
| Axis | bank | 20,000.00 | preset |
| Food Card | wallet | 3,000.00 | preset |
| PF | pf | 1,00,000.00 | preset |
| Outside | other | 0.00 | preset, never used |
| HDFC Card | card | −3,000.00 | custom ("I owe") |
| Old Wallet | wallet | 500.00 | custom, **archived** |

Loan: "Ravi", lent, principal ₹10,000.00, start 2026-10-12.

Budgets:
- 2026-10: Groceries 6,000.00, Food & Dining 4,000.00, Fuel 3,000.00.
- 2026-10: Rent 10,000.00, **soft-deleted** (must not count).
- 2026-09: Groceries 99,999.00 (other month; must not count).

### 5.2 Transactions (21)
| Id | Date | Type | Amount | Account | Category / To | Counts as |
|----|------|------|--------|---------|---------------|-----------|
| T01 | 2026-09-30 | expense | 1,500.00 | Hand | Groceries | outside month (before) |
| T02 | 2026-10-01 | income | 60,000.00 | SBI | Salary | first day |
| T03 | 2026-10-01 | expense | 15,000.00 | SBI | Rent | first day |
| T04 | 2026-10-03 | expense | 2,450.50 | Hand | Groceries | |
| T05 | 2026-10-05 | transfer | 5,000.00 | SBI | → Hand | transfer |
| T06 | 2026-10-07 | expense | 1,200.00 | Food Card | Food & Dining | |
| T07 | 2026-10-08 | expense | 200.00 | Old Wallet | Tea & Snacks | archived account |
| T08 | 2026-10-09 | expense | 3,200.00 | HDFC Card | Shopping | |
| T09 | 2026-10-10 | income | 1,200.00 | HDFC Card | Refund / Cashback | refund |
| T10 | 2026-10-12 | expense | 10,000.00 | SBI | Loan Given, loan Ravi | loan given |
| T11 | 2026-10-14 | expense | 1,850.75 | Axis | Fuel | |
| T12 | 2026-10-15 | expense | 3,000.00 | Hand | Groceries | |
| T13 | 2026-10-18 | transfer | 3,200.00 | SBI | → HDFC Card | card bill |
| T14 | 2026-10-20 | income | 4,000.00 | SBI | Loan Repayment Received, loan Ravi | loan repayment |
| T15 | 2026-10-22 | expense | 950.00 | Food Card | Food & Dining | |
| T16 | 2026-10-24 | income | 2,500.00 | Axis | Business / Freelance | |
| T17 | 2026-10-26 | expense | 700.00 | Hand | Tea & Snacks | |
| T18 | 2026-10-28 | expense | 1,200.00 | Axis | Food & Dining | |
| T19 | 2026-10-30 | expense | 999.00 | Hand | Groceries | **soft-deleted** |
| T20 | 2026-10-31 | expense | 1,549.25 | Axis | Health & Medicine | last day |
| T21 | 2026-11-01 | expense | 800.00 | SBI | Fuel | outside month (after, future-dated) |

`created_at` follows the id order (T01 oldest), so ties on a date sort
by id.

### 5.3 Top cards
| Card | Arithmetic | Expected |
|------|-----------|----------|
| This Month Spent | T03 15,000.00 + T04 2,450.50 + T06 1,200.00 + T07 200.00 + T08 3,200.00 + T11 1,850.75 + T12 3,000.00 + T15 950.00 + T17 700.00 + T18 1,200.00 + T20 1,549.25. Running: 15,000.00 → 17,450.50 → 18,650.50 → 18,850.50 → 22,050.50 → 23,901.25 → 26,901.25 → 27,851.25 → 28,551.25 → 29,751.25 → 31,300.50. Left out: T01, T21 (other months), T10 (loan), T19 (deleted), T05 and T13 (transfers) | **₹31,300.50** (3130050 paise) |
| Income | T02 60,000.00 + T09 1,200.00 + T16 2,500.00. Left out: T14 (loan) | **₹63,700.00** |
| Budget | 6,000.00 + 4,000.00 + 3,000.00. Left out: deleted Rent budget, the September budget | **₹13,000.00** |
| Remaining | 13,000.00 − 31,300.50 | **−₹18,300.50** (danger, "over budget") |
| Net Worth | Sum of the balances in 5.4: 2,349.50 + 80,000.00 + 17,900.00 + 850.00 + 1,00,000.00 + 0.00 + (−1,800.00) + 300.00 | **₹1,99,599.50** |
| Saved % (lime card) | (63,700.00 − 31,300.50) × 100 / 63,700.00 = 50.86 | **51%** (goal banner shows) |
| Mascot mood | Budget 13,000.00 > 0, so plan = 13,000.00; Spent 31,300.50 > plan | **worried** |

Net Worth cross-check:
- Openings: 5,000 + 50,000 + 20,000 + 3,000 + 1,00,000 + 0 − 3,000 + 500
  = 1,75,500.00.
- Plus all live income: 60,000 + 1,200 + 4,000 + 2,500 = 67,700.00.
- Minus all live expenses: T01 1,500 + 31,300.50 + T10 10,000 + T21 800
  = 43,600.50.
- Transfers add 0.
- 1,75,500.00 + 67,700.00 − 43,600.50 = **1,99,599.50** ✓

### 5.4 Account balances (all live rows, any date)
| Account | Arithmetic | Balance |
|---------|-----------|---------|
| Hand | 5,000.00 − 1,500.00 (T01) − 2,450.50 (T04) + 5,000.00 (T05) − 3,000.00 (T12) − 700.00 (T17); T19 deleted | **2,349.50** |
| SBI | 50,000.00 + 60,000.00 − 15,000.00 − 5,000.00 − 10,000.00 − 3,200.00 + 4,000.00 − 800.00 (T21, future, still counts) | **80,000.00** |
| Axis | 20,000.00 − 1,850.75 + 2,500.00 − 1,200.00 − 1,549.25 | **17,900.00** |
| Food Card | 3,000.00 − 1,200.00 − 950.00 | **850.00** |
| PF | 1,00,000.00 | **1,00,000.00** |
| Outside | 0.00 | **0.00** |
| HDFC Card | −3,000.00 − 3,200.00 + 1,200.00 + 3,200.00 (T13 in) | **−1,800.00** |
| Old Wallet (archived) | 500.00 − 200.00 | **300.00** |

### 5.5 Doughnut
- Positive accounts: 6 (PF, SBI, Axis, Hand, Food Card, Old Wallet).
  That is more than 5, so the slices are the 4 biggest + Other.
- Assets = 1,00,000.00 + 80,000.00 + 17,900.00 + 2,349.50 + 850.00 +
  300.00 = **₹2,01,399.50** (= Net Worth 1,99,599.50 + owed 1,800.00 ✓).
- Owed line: **−₹1,800.00** (HDFC Card).
- Outside (0.00): no slice.

| Slice | Amount | Exact share (amount × 100 / 2,01,399.50) | Floor | Gets +1 from remainder? | Shown |
|-------|--------|------|-------|------|-------|
| PF | 1,00,000.00 | 49.6525 | 49 | yes (3rd biggest remainder, .6525) | **50%** |
| SBI | 80,000.00 | 39.7220 | 39 | yes (.7220) | **40%** |
| Axis | 17,900.00 | 8.8878 | 8 | yes (.8878, biggest) | **9%** |
| Hand | 2,349.50 | 1.1666 | 1 | no (.1666) | **1%** |
| Other (Food Card 850.00 + Old Wallet 300.00) | 1,150.00 | 0.5710 | 0 | no (.5710, 4th) | **<1%** |

The floors add to 97, so 3 points go to the 3 biggest remainders. The
total is 100.

### 5.6 Top 3 categories (of 31,300.50)
| Rank | Category | Arithmetic | Amount | Share (half up) |
|------|----------|-----------|--------|-----------------|
| 1 | Rent | T03 | **15,000.00** | 47.92 → **48%** |
| 2 | Groceries | T04 2,450.50 + T12 3,000.00 (T01 other month, T19 deleted) | **5,450.50** | 17.41 → **17%** |
| 3 | Food & Dining | T06 1,200.00 + T15 950.00 + T18 1,200.00 | **3,350.00** | 10.70 → **11%** |

Not shown:
- Shopping 3,200.00, Fuel 1,850.75, Health 1,549.25, Tea & Snacks
  900.00.
- Loan Given 10,000.00 would be #2 if loans were not left out, so the
  test proves the rule. The refund does not reduce Shopping (Q4).

### 5.7 Recent (5)
In order:
1. T21 (1 Nov, future)
2. T20 (31 Oct)
3. T18 (28 Oct)
4. T17 (26 Oct)
5. T16 (24 Oct)

T19 (30 Oct) is deleted, so it is not shown.

### 5.8 Hero chart and week bars (existing, re-checked)
- 9-day strip, 23 to 31 Oct: 0, 0, 0, 700.00, 0, 1,200.00, 0, 0
  (T19 deleted), 1,549.25.
- Week bars: the last 7 of these.

## 6. Performance target
From PROJECT.md and the performance skill.
- **Data:**
  - Dashboard data (one read transaction, all section-2 numbers) loads
    in **under 300ms** on 20,000 rows.
  - The test records median and p95.
  - It fails only if the median is above 300ms (same style as the
    Quick Add gate).
- **SQL:**
  - Totals come from SQL sums; no transaction rows are loaded into
    memory except the 5 recent ones.
  - Doughnut slices are built in Dart from the balances list (one row
    per account, fewer than 50).
- **Speed and memory:**
  - 60fps: the ring and bars animate only transform / opacity, inside
    a `RepaintBoundary`.
  - Animation never rebuilds the whole screen.
  - The 9 single-day queries move into the same read transaction.
- **Cold start:** under 2s stays (Home is the first tab).
  Real-phone check by the owner.

## 7. Low-risk choices (change on request)
1. The Dashboard = the Home tab; Insights stays a placeholder.
2. Recent shows 5 rows plus "See all" (Home showed 12). The screen is
   longer now.
3. Doughnut: max 5 slices, centre shows Assets, negatives in an "Owed"
   line.
4. Slice: first tap selects it, second tap opens the statement.
5. Month tiles: long-press shows the sum. A tap on Budget does nothing
   until session 7 (it shows "Budgets come in a later update").

## 8. Open questions (owner)
- **Q1 Loan categories without a loan link.** The 4 loan categories
  are hidden in Quick Add, but an Excel import (session 10) could bring
  such rows. Today they count as normal spending.
  - Proposal: leave them out of Spent, Income and Top 3, the same as
    loan rows.
  - This means one shared SQL filter, and the Statement chart changes
    the same way.
  - Option: leave them out of Top 3 only.
- **Q2 "This month" = the whole calendar month or up to today?**
  - Home today sums to **today**.
  - Proposal: the **whole month**, so future-dated entries (Quick Add
    allows +31 days) count, the same as the budgets in session 7.
  - The fixture gives the same answer either way. A second test with
    today = 2026-10-15 will pin your choice.
- **Q3 Remaining.** Proposal: Budget total − **all** spending
  (fixture: −₹18,300.50).
  - Option: compare only with spending in budgeted categories
    (fixture: 13,000.00 − (5,450.50 + 3,350.00 + 1,850.75) =
    **₹2,348.75**).
  - With no budget: proposal "—". Option: Income − Spent, like Home's
    "plan".
- **Q4 Refunds.** Proposal: a "Refund / Cashback" entry stays income
  and does not lower Spent or its category.
  - Option: subtract refunds from Spent. That needs a link to the
    expense category, which we do not have.
- **Q5 Net Worth.**
  - Proposal: sum of account balances only, as on the Accounts screen
    and the hero. Archived accounts and card debt are included.
  - Not added: money lent to people (loan outstanding) and gold value
    (Phase 2 screens).
  - Future-dated entries already count in balances. OK?
- **Q6 Future-dated entries in Recent.** Proposal: show them (they are
  real entries), with their date.
  - Option: show only entries up to today.
- **Q7 Spendings / Savings tiles.** Keep the existing week-bars and
  savings-ring tiles under the new month tiles, or drop them to keep
  the screen short?
- ~~**Q8 Reconcile with main.**~~ Closed: PR #18 merges main into develop. Session 6 starts after it is merged.
