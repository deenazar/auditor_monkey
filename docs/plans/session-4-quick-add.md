# Session 4 plan: Quick Add

- Roadmap item 4 (Feature 2). Status: **Approved** (owner, 2026-11-12). Built on branch `claude/vigilant-heisenberg-2oik0f`.
- Date: 2026-11-12. Planned by project-manager.
- Suggested branch: `feature/20261112-quick-add` (from `develop`).
- Done when: an entry saves offline in under 100ms and a transfer
  changes both balances but no spending totals.

## 1. Summary
The centre + opens the real Quick Add sheet. It has three tabs: Expense,
Income, Transfer. The number pad is on screen at once, so the first tap
after opening is already a digit. The last-used account and category
(per type) are already picked. When those defaults are right, adding an
expense is **open → type amount → save**. A "Recent" strip repeats a
past entry with one tap (it fills the form; Save still needs one tap).
After saving, the sheet closes and a short toast confirms, with Undo.

**No schema change. No new package.** "Last used", "recent / frequent"
and "recent entries" are SQL queries on `transactions`. Writes use the
existing `TransactionsRepository.create` (and `softDelete` for Undo).

### In scope
Quick Add sheet (3 tabs, number pad, amount display, category chips with
colour groups, account / From / To pickers, date, note, recent strip,
save, toast with Undo), its read queries and Riverpod state, category
colour-group colours (DESIGN.md addition), group tints on statement rows
(the open item from session 3), widget, golden and performance tests.

### Out of scope (later sessions)
Transactions list, edit screen, delete screen (session 5), dashboard
(6), budgets and budget alerts (7), loans screens (Phase 2), category
add / edit / archive UI, account archive UI, sync. No new routes: Quick
Add stays a modal sheet opened from the bottom bar.

## 2. Data and logic (no schema change)

### 2.1 Checks against the v1 schema
| Need | Answer |
|------|--------|
| Last-used account / category per type | Newest live row of that type by `created_at` (entry time, not the entry's date). Query, not stored. No prefs, no new table. |
| Recent / frequent categories | One grouped query: uses and last use per category, per type. Query, not stored. |
| Recent entries to repeat | Newest live rows by `created_at`, de-duplicated in Dart. Query, not stored. |
| Save | Existing `TransactionsRepository.create(TransactionDraft)`. It validates and checks references inside one DB transaction. |
| Undo | Existing `TransactionsRepository.softDelete(id)`. |
| Balances shown in the account picker | Existing `accountBalancesProvider` (live stream). |
| Category colour groups | Already stored (`categories.colour_group`, 10 names). Only colours are new (sec. 9). |

**Why not shared_preferences for "last used":** a pref can disagree with
the data (deleted entry, archived account, restore from backup, a second
phone after sync). A query on live rows is always right, needs no new
package and syncs for free. Cost: a few ms per open (measured, sec. 5).

### 2.2 The "recent window"
All Quick Add queries only look at live rows with
`date >= today - 90 days` (future-dated rows included). This range uses
the existing `ix_tx_date` index, so the queries stay fast with 20,000+
rows. Older history does not affect suggestions. Loan-linked rows
(`loan_id IS NOT NULL`) are left out everywhere in Quick Add, because
Quick Add cannot create a loan link (repeating one would drop the link).

### 2.3 New queries (senior-dev)
New file `lib/core/database/daos/transactions_quick_add_queries.dart`:
an `extension QuickAddQueries on TransactionsDao` (no code generation;
keeps `transactions_dao.dart` under 300 lines). `?since` = cutoff date.

1. **Last used per type** (called 3 times, once per type):
   ```sql
   SELECT account_id, to_account_id, category_id FROM transactions
    WHERE type = ?1 AND deleted_at IS NULL AND +loan_id IS NULL
      AND date >= ?2
    ORDER BY created_at DESC, id DESC LIMIT 1
   ```
2. **Category usage per type**:
   ```sql
   SELECT category_id, COUNT(*) AS uses, MAX(created_at) AS last_used
     FROM transactions
    WHERE type = ?1 AND deleted_at IS NULL AND +loan_id IS NULL
      AND date >= ?2
    GROUP BY category_id
   ```
   (`type` is `expense` or `income`; transfers have no category.)
3. **Recent entries** (all types):
   ```sql
   SELECT * FROM transactions
    WHERE deleted_at IS NULL AND +loan_id IS NULL AND date >= ?1
    ORDER BY created_at DESC, id DESC LIMIT 50
   ```

New read-only repository `lib/features/quick_add/data/quick_add_repository.dart`
(`QuickAddRepository(RepositoryContext)`), method
`Future<QuickAddHints> loadHints({required String today})`: checks the
date, runs the 5 queries in ONE read transaction (consistent snapshot),
maps to domain types, logs `quick_add loadHints ok` with timing only.
Failures come back as the usual `DataFailure`.

Domain types in `lib/features/quick_add/domain/quick_add_hints.dart`:
`QuickAddHints { Map<TransactionType, LastUsedPick> lastUsed;
Map<TransactionType, List<CategoryUsage>> usage; List<TransactionEntry>
recent; }`.

### 2.4 Defaults (pure Dart, `quick_add_defaults.dart`)
Inputs: hints, offered accounts, offered categories. "Offered" =
live and **not archived**; for categories also not one of the 4 loan
categories if owner question Q1 is answered "hide" (sec. 8).

| Type | Account | Category / To |
|------|---------|---------------|
| Expense | Last expense's account if offered, else first offered account by sort order | Last expense's category if offered, else first suggested, else first by sort order |
| Income | Last income's account if offered, else first offered account | Same rule with income categories |
| Transfer | From = last transfer's From if offered, else the expense default account | To = last transfer's To if offered and ≠ From, else the first offered account ≠ From |

Fewer than 2 offered accounts → Transfer is disabled (sec. 3, Q-T1).

### 2.5 Category order (pure Dart, `category_order.dart`)
Per kind: **suggested** first (max 6): the last-used category, then by
`uses` (desc), then `last_used` (desc), then sort order, then id. Then
every other offered category by sort order (the seed order already
groups them by colour group). Ties are fixed, so goldens are stable.

### 2.6 Recent entries strip (pure Dart, `recent_entries.dart`)
From the 50 rows: keep rows whose account, To account and category are
all offered; remove repeats of the same (type, amount, account, To,
category, note), keeping the newest; take the first 6. Tapping one
fills type, amount, account, To, category and note. **The date stays
the form's date (default today).** It does not save by itself; Save is
one more tap. (Auto-save on one tap would make accidental entries too
easy.)

### 2.7 Amount input (pure Dart, `amount_input.dart`)
The number pad edits a small text buffer. Paise come only from
`parseRupeesToPaise` (integer maths). **No `double` anywhere.** Nothing
is ever rounded: input that would need rounding is refused.

| Action | Rule |
|--------|------|
| Digit | Added unless: more than 2 decimals (refused, hint "Only 2 decimal places"), or the value would pass `maxPaise` (refused, hint "Maximum is ₹10,00,00,00,00,000.00"). A lone leading `0` is replaced (`0` then `5` → `5`). |
| `.` | `.` on empty → `0.`. A second dot is ignored. |
| Backspace | Removes the last character. Long press clears all. |
| Paste (long press the amount) | Clipboard text through `parseRupeesToPaise` (accepts `₹`, Indian or Western commas, leading zeros). Invalid → hint "That isn't a valid amount", buffer unchanged. Valid → buffer set to the plain form, e.g. `1,23,456.5` → `123456.5`. |
| Display | Live Indian grouping of what is typed, trailing dot and decimals kept as typed (`1,250.5`, `12.`). Empty shows `₹0` in `inkMuted`. |
| To paise | Trailing dot removed, then `parseRupeesToPaise`. `0`, `0.00`, empty → not savable (Save disabled, no red error). |
| Hardware keyboard | `0-9`, `.`, Backspace, Enter (= Save) work too. |

### 2.8 State (Riverpod, plain providers, current API)
- `quickAddDataProvider` (`FutureProvider.autoDispose`): offered
  accounts (from `AccountsRepository`), offered categories per kind
  (from `CategoriesRepository`), `QuickAddHints`, and the resolved
  defaults and orders (sec. 2.4-2.6). Loaded once per open.
- `quickAddProvider` (`NotifierProvider.autoDispose<QuickAddNotifier,
  QuickAddState>`): what the user did in this sheet.
  `QuickAddState { type; AmountInput amount; String date; String note;
  Map<TransactionType, Picks> picks; amountHint; SaveStatus status
  (idle / saving / failed / done); saveError; savedId }`.
  `Picks` holds only the user's own choices (`accountId`, `toAccountId`,
  `categoryId`, all nullable). What the screen shows = pick ?? default.
  So defaults that arrive a few ms after the pad is used never overwrite
  a user choice, and the pad works before the data is loaded.
- Amount, date and note are shared by the 3 tabs. Picks are kept per
  type, so switching tabs and back restores them.
- Today's date is read from `clockProvider` when the notifier is built
  (each open), not from the cached `todayProvider`, so a sheet opened
  after midnight shows the new day.
- Methods: `setType`, `pressDigit`, `pressDot`, `backspace`, `clear`,
  `paste`, `pickCategory`, `pickAccount`, `pickFrom`, `pickTo`
  (picking To = From swaps them), `swapAccounts`, `setDate`,
  `setNote`, `applyRecent(entry)`, `save()`.

### 2.9 Validation (`quick_add_validator.dart`, UI side; repository checks again)
| Field | Rule | Message |
|-------|------|---------|
| Amount | 1 paisa to `maxPaise`, at most 2 decimals | Save disabled while 0 / empty; hints above for the rest |
| Category (expense / income) | Required; must be offered and of the same kind as the type | "Pick a category." (repo: `kindMismatch`) |
| Account / From | Required, offered | "Pick an account." |
| To (transfer) | Required, offered, ≠ From | "Pick two different accounts." (the picker also prevents it) |
| Note | Optional; trimmed; ≤ 200 characters; no control characters; single line | Counter shows from 180; "Use 200 characters or fewer." |
| Date | Valid `YYYY-MM-DD`; from 1900-01-01 (DB rule); **at most 31 days after today** | "Pick a date up to 31 days ahead." (the picker's last date is today + 31) |

The 31-day rule is a Quick Add rule only (the repository and later Excel
import keep the DB rule). It allows next month's planned rent or EMI and
blocks typos like 2062.

### 2.10 Save flow
1. Save tap → `save()`. If `status == saving` or `done`, return at once
   (set **before** any `await`, so a double tap cannot start two saves).
   `PrimaryButton` also ignores taps while `loading`.
2. Validate (sec. 2.9). Invalid → field hint, no DB call.
3. Build `TransactionDraft` (transfer: `categoryId = null`,
   `toAccountId` set; expense / income: `toAccountId = null`) →
   `TransactionsRepository.create`.
4. Success → `status = done`, `savedId` set; the sheet closes
   (`durationMedium`, `curveExit`) and the shell shows the toast:
   "Expense saved · ₹250.00" with **Undo** for 4s. Undo calls
   `softDelete(savedId)` and then shows "Entry removed". Balances update
   live through the existing streams.
5. Failure → `status = failed`, `saveError = failure.message`; every
   field is kept; Save is active again.

Closing the sheet (×, swipe down, Android back) drops the draft without
asking: speed first, and the draft is at most a few taps.

### 2.11 Logging (tag `quick_add`)
`info`: sheet opened (exists), save started (type only), save done
(type + time in ms), save failed (failure code), undo done / failed.
`debug`: tab changed, recent entry used (index only), hints loaded
(counts + ms). The repository already logs the first 8 characters of the
id. **Never** amounts, notes, account or category names, dates or the
clipboard text. A test checks this with `MemoryLogSink`.

## 3. Screens and states

All values come from `lib/shared/theme` tokens (`AppColors`,
`AppTextStyles`, `AppSpacing`, `AppRadius`, `AppSizes`, `AppMotion`,
`AppShadows`). Side padding `space6` (24). Every animation goes through
`AppMotion.resolve` (zero with reduce motion: fades only, no movement).
Sheet: white `background`, `radiusCard` top corners (`AppRadius.sheet`),
`shadowFloat`, `canvas` scrim, opened with the existing `durationMedium`
/ `curveEnter`, closed with `curveExit`.

### 3.1 Layout (top to bottom)
| Part | Pinned? | Content |
|------|---------|---------|
| Header | top | Close (Lucide `x`, 44 target, `ink`) left; type tabs centred |
| Amount | top | ₹ + amount in `displayAmount` (₹ smaller per DESIGN), centred; hint line under it in `caption` (`danger` for refusals) |
| Recent | scrolls | `overline` "RECENT", one horizontal row of recent chips. Hidden when there are none |
| Category / accounts | scrolls | Expense / income: `overline` "CATEGORY", one horizontal row: "All" chip (Lucide `layout-grid`) then category chips, suggested first. Transfer: From pill, swap button (Lucide `arrow-left-right`, 44), To pill |
| Details | scrolls | One horizontal row of pills: account pill (expense / income only: colour dot + name + `chevron-down`), "Today", "Yesterday", calendar pill (Lucide `calendar`; shows the picked date, e.g. "3 Nov", when not today / yesterday), note pill (Lucide `sticky-note`, "Add note" or the note's first words) |
| Number pad | bottom | 4 rows × 3 keys: 1-9, `.`, 0, backspace (Lucide `delete`) |
| Save | bottom | `PrimaryButton` "Save expense" / "Save income" / "Save transfer"; save error card sits just above it |

The middle part scrolls when space is short (small phones, text scale
2.0); header, amount, pad and Save stay visible.

### 3.2 Screen / state list
| ID | Screen / state | What it shows | Tokens / motion |
|----|----------------|---------------|-----------------|
| Q1 | Sheet: loading data | Pad, amount and tabs work at once. Recent and category rows show `SkeletonBlock` pills; Save disabled. Data normally arrives before the open animation ends | `tile` skeletons, fade in `durationFast` |
| Q2 | Expense: empty (default open) | Expense tab selected, `₹0` in `inkMuted`, recent strip, suggested category selected, last-used account, "Today" selected, Save disabled | Selected chip `primaryDeep` + `onDark` label; unselected `tile` + `ink` |
| Q3 | Expense: typing | Amount in `ink`, e.g. `₹1,250.5`; Save enabled "Save expense" | Key press: key scales `pressScale` and fills `navIndicator`, `durationFast`; light haptic (selection click) |
| Q4 | Amount refused | Third decimal or value over max: amount nudges sideways `space2` and back (`durationMedium`, `curveEnter`), hint in `danger` `caption`; buffer unchanged | Reduce motion: no nudge, hint fades in only |
| Q5 | Income tab | Same layout; income categories; amount shown with `+` in `accentText` once typed; "Save income" | Tab indicator slides `durationFast` `curveEnter`; content cross-fades `durationFast` |
| Q6 | Transfer tab | From / To pills (colour dot, name, balance in `caption`) with swap button; no category row; amount in `inkMuted` with ⇄ (Amounts table); "Save transfer" | Swap icon turns 180°, `durationMedium`; reduce motion: no turn |
| Q7 | Transfer disabled (fewer than 2 accounts) | Transfer segment label `iconInactive`; tapping it shows `caption` "Add a second account to move money between accounts." under the tabs (stays on the current tab) | Hint fades `durationFast` |
| Q8 | Recent entry applied | Tab switches to the entry's type, amount rolls to the entry's amount, its category / accounts / note selected, date unchanged | `RollingAmount` `durationSlow`; reduce motion: instant |
| Q9 | Saving | Save shows the ring, taps ignored, everything else read-only | `PrimaryButton` loading (`ink` ring on `primary`) |
| Q10 | Save error | Card above Save: Lucide `triangle-alert` in `danger` + message from the failure (e.g. "That account is not available."); fields kept; Save active | `tile` card, `radiusCard`, fade in `durationFast` |
| Q11 | No categories for this type | Category row replaced by `caption` "No expense categories to pick." Save disabled. (Only if all are archived / deleted; no category UI exists yet) | `inkMuted` |
| Q12 | Data load error | Inside the sheet: `ErrorState` "We couldn't load your accounts." + "Try again" (re-runs `quickAddDataProvider`) | `danger` icon `iconLarge` |
| Q13 | Saved (success) | Sheet closes; toast at the bottom of the shell above the nav bar: "Expense saved · ₹250.00" + "Undo". After Undo: "Entry removed" | Toast per sec. 9: slides up `space4` + fade `durationMedium` `curveEnter`, leaves with fade `durationFast` `curveExit`; reduce motion: fade only |
| P1 | Account picker sheet | Title `title` "Pick account" (transfer: "From" / "To"); rows: colour dot, name `bodyStrong`, balance `caption` (from `accountBalancesProvider`), `primaryDeep` check on the selected one; in the To picker the From account is shown disabled | List row pattern, `listRowGap`; selectable tile style |
| P2 | All categories sheet | Title "Categories"; sections per colour group (`overline` "ESSENTIALS", "FOOD", …), each a `Wrap` of category chips; selected chip marked | Section gap `space6`; chips as above |
| P3 | Note sheet | `AppTextField` (autofocus, single line, 200 max, counter from 180), "Done" `PrimaryButton`; keyboard "done" closes it | Text field rule (fill `tile`, focus 2pt `primaryDeep`) |
| P4 | Date picker | Material date picker themed with tokens: `primaryDeep` selected day + `onDark`, `ink` text, `radiusCard`; range 1900-01-01 to today + 31 | `DatePickerThemeData` in `app_theme.dart` |
| Q14 | Large text (2.0) | Middle part scrolls; amount scales down (FittedBox) and never clips; pad keys keep 44+ targets | — |

### 3.3 User flows and tap count (defaults right)
| Flow | Steps | Taps |
|------|-------|------|
| Expense, usual category and account | + → type amount → Save | **3 steps** (2 taps + the digits) |
| Expense, other category | + → amount → category chip → Save | 4 steps |
| Expense, yesterday | + → amount → "Yesterday" → Save | 4 steps |
| Income | + → Income tab → amount → Save | 4 steps |
| Transfer, usual From / To | + → Transfer tab → amount → Save | 4 steps |
| Transfer, other accounts | + → Transfer → amount → From → pick → To → pick → Save | 8 steps (swap button covers the common "reverse" case in 1 tap) |
| Repeat a recent entry | + → recent chip → Save | **3 taps** |
| Undo a mistake | Undo in the toast | 1 tap |

### 3.4 Accessibility
Tap targets ≥ 44 (pad keys 56 tall, chips and pills 44). Keys have
labels ("1", "point", "delete"; long press "clear all"). The amount is a
live region read as "₹1,250.50". Tabs use `selected` semantics; the
disabled Transfer tab reads "Transfer, needs two accounts". All text
pairs use DESIGN.md pairs already checked (`ink` on white / `tile`,
`onDark` on `primaryDeep` about 5.7:1, `danger` text on white).

## 4. Tasks

Skills on every task: feature-workflow, validation, logging, security,
performance; UI tasks also ui-ux-motion, flutter-mobile-design,
design-taste; tests qa-testing. All new files under
`lib/features/quick_add/` unless stated.

### senior-dev
| ID | Task | Files (main) | Acceptance |
|----|------|--------------|------------|
| S1 | Quick Add queries (sec. 2.3) + `QuickAddRepository.loadHints` + `QuickAddHints` types | `core/database/daos/transactions_quick_add_queries.dart`, `data/quick_add_repository.dart`, `domain/quick_add_hints.dart` | One read transaction; deleted, loan-linked and out-of-window rows left out; future rows included; ties fixed (`created_at`, `id`); query plan uses `ix_tx_date`; logs counts + ms only |
| S2 | Pure domain: `AmountInput`, defaults resolver, category order, recent de-dup, validator incl. 31-day date rule (sec. 2.4-2.7, 2.9) | `domain/amount_input.dart`, `domain/quick_add_defaults.dart`, `domain/category_order.dart`, `domain/recent_entries.dart`, `domain/quick_add_validator.dart` | No `double`; every case in sec. 5 passes; no Flutter imports |
| S3 | `quickAddDataProvider` + `QuickAddNotifier` / `QuickAddState` (sec. 2.8, 2.10, 2.11), Undo helper | `application/quick_add_data_provider.dart`, `application/quick_add_notifier.dart`, `application/quick_add_state.dart`, `application/quick_add_undo.dart` | Pad works before data; user picks never overwritten by defaults; double save impossible (also with two un-awaited `save()` calls); state kept on failure; logs clean |
| S4 | Sheet frame and save integration: replace the placeholder; pinned header / amount / pad / Save, scrolling middle; close on success; toast via the shell's `ScaffoldMessenger`; hardware keys; Android back closes | `presentation/quick_add_sheet.dart`, `app/app_shell.dart` (toast host only) | Opens with existing motion; one save → sheet closed + toast; Undo removes the entry and balances return |
| S5 | Tokens in code (sec. 9): `AppSizes` additions, `AppMotion.toastDuration`, category group colour map, chip / segmented / key / toast styles, `DatePickerThemeData` and `SnackBarThemeData` in the theme | `shared/theme/app_sizes.dart`, `shared/theme/app_motion.dart`, `shared/theme/category_colours.dart`, `shared/theme/app_theme.dart` | No hex outside `app_colors.dart`; every group maps; theme test |
| S6 | Statement rows get the category colour group: add `c.colour_group` to `statementPageSql`, `StatementLine.categoryColourGroup` | `core/database/daos/transactions_dao.dart`, `features/transactions/domain/statement_line.dart`, `features/transactions/data/transactions_repository.dart` | Existing statement tests pass; unknown group → `other` |
| S7 | Money acceptance, performance and query plan tests (sec. 5.4, 5.5) | `test/features/quick_add/quick_add_money_test.dart`, `test/features/quick_add/quick_add_performance_test.dart`, `test/core/database/query_plan_test.dart` | See sec. 5 |

### junior-dev
| ID | Task | Files (main) | Acceptance |
|----|------|--------------|------------|
| J1 | `NumberPad` + `NumPadKey` (press scale + fill, haptic, semantics, long-press backspace = clear) | `presentation/widgets/number_pad.dart`, `presentation/widgets/num_pad_key.dart` | 56 tall keys, `radiusField`, `tile` fill, `headline` digits; reduce motion: no scale |
| J2 | `AmountDisplay` (grouped live text, ₹ small, colour / sign per type, refuse nudge, hint line, long-press paste menu, roll on recent) | `presentation/widgets/amount_display.dart` | Uses `AmountText` styles / `RollingAmount`; never clips at 2.0 |
| J3 | `TypeTabs` segmented control (sliding indicator, disabled Transfer + hint) | `presentation/widgets/type_tabs.dart` | Sec. 9 segmented rule; `selected` semantics |
| J4 | `CategoryIconCircle` (shared), `CategoryChip`, `CategoryChipRow` ("All" + suggested first), `AllCategoriesSheet` grouped by colour group | `shared/widgets/category_icon_circle.dart`, `presentation/widgets/category_chip.dart`, `presentation/widgets/category_chip_row.dart`, `presentation/widgets/all_categories_sheet.dart` | Group tints from S5; selected chip style; sections in group order |
| J5 | `AccountPill` + `AccountPickerSheet`, `TransferAccountsRow` (From / swap / To), `DateChips` (Today / Yesterday / calendar → date picker), `NotePill` + `NoteSheet` | `presentation/widgets/account_pill.dart`, `.../account_picker_sheet.dart`, `.../transfer_accounts_row.dart`, `.../date_chips.dart`, `.../note_sheet.dart` | To picker disables From; date range enforced; note counter + error |
| J6 | `RecentEntriesStrip` + `RecentEntryChip` (icon circle, name or "SBI → Axis", amount `caption`) | `presentation/widgets/recent_entries_strip.dart` | Hidden when empty; tap calls `applyRecent` |
| J7 | Assemble states Q1-Q14 in the sheet body; save error card; `QuickAddToast` content; statement row tint (uses S6) | `presentation/quick_add_body.dart`, `presentation/widgets/save_error_card.dart`, `presentation/widgets/quick_add_toast.dart`, `features/accounts/presentation/widgets/statement_row.dart` | Widget + golden tests of sec. 5 pass |

Order / parallel: S1, S2, S5, J1, J2, J3 start together. S3 after S1 +
S2. J4, J5, J6 after S5 (stub the notifier API from S3's signatures
first). S4 after S3. J7 after S4 and J1-J6. S6 any time; its statement
row part in J7. S7 after S3 (money, perf) and S4 (widget timing). Then
qa-reviewer (code-review + qa-testing).

## 5. Tests

### 5.1 Unit (pure)
- **AmountInput / paise** (table test, every row checks the exact int):
  `"12.3"` → 1230; `"12.30"` → 1230; `"0.01"` → 1; `".5"` → `"0.5"` → 50;
  `"0"`, `"0.0"`, `"0.00"`, `""` → not savable; `"12."` → 1200;
  third decimal (`"12.345"`) refused, buffer stays `"12.34"`;
  `"1000000000000"` and `"1000000000000.00"` → `maxPaise`;
  `"1000000000000.01"` refused; 14th integer digit refused; leading
  zeros (`0` then `5` → `"5"`, paste `"007.50"` → 750); second dot
  ignored; backspace and clear; paste `"1,23,456.50"` → 12345650,
  `"123,456.5"` → 12345650, `"₹500"` → 50000, `"1,2,3"`, `"-5"`, `"abc"`,
  `"1.234"`, `"0,123"` refused; display grouping (`"1250.5"` →
  `1,250.5`, `"12345678"` → `1,23,45,678`). A grep test confirms no
  `double` in `lib/features/quick_add/domain` and `application`.
- **Defaults**: each type with and without history; last-used account
  archived / deleted → fallback; To = From → next account; one account
  → transfer unavailable; loan categories hidden (if Q1 = hide).
- **Category order**: last-used first, then uses, last use, sort order;
  max 6 suggested; archived / deleted / other-kind left out; tie order.
- **Recent de-dup**: identical entries collapse to the newest; max 6;
  entries with archived account or category skipped; date never copied.
- **Validator**: each rule in sec. 2.9 incl. today + 31 ok, today + 32
  refused, 1899-12-31 refused, note 200 ok / 201 refused, control
  character refused.

### 5.2 Unit (in-memory DB via `TestEnv`, fixed clock)
- **Queries**: last used per type ignores deleted, loan-linked and
  out-of-window rows and picks by `created_at` (a back-dated entry made
  last still wins); usage counts and last use per category; recent
  entries order; future-dated rows included.
- **Notifier**: key flow → draft; tab switch keeps amount / date / note
  and per-type picks; defaults arriving late never replace a pick;
  `applyRecent`; swap; picking To = From swaps; save success / failure
  keeps fields; **two `save()` calls without await → one row**.
- **Logs**: a full expense, income, transfer, failed save and undo write
  no amounts (`250`, `25000`), notes, names or dates (`MemoryLogSink`).

### 5.3 Money correctness (S7, through the notifier and repository)
Accounts Hand (opening ₹1,000.00), SBI (₹5,000.00), Axis (₹0.00).
After each save, check `accountBalancesProvider`, `netWorthProvider`,
`expenseTotal`, `incomeTotal`, `expenseByCategory` and
`monthlyTotalsForAccount` against hand-computed integers:
- Expense ₹250 on Hand: Hand −25000; net worth −25000; expense total
  +25000; category total +25000; income unchanged.
- Income ₹1,200.50 on SBI: SBI +120050; net worth +120050; income total
  +120050; expense unchanged.
- **Transfer ₹2,000 SBI → Axis: SBI −200000 and Axis +200000 (both
  sides); net worth unchanged; expense total, income total, expense by
  category and both accounts' monthly totals unchanged.**
- 10 expenses of ₹0.01 → balance exactly −10 paise (no drift).
- Max amount `maxPaise` saves and shows exactly.
- Undo of each type → all numbers back to before.
- Reload: close and reopen a file DB (as session 3's S8) → same numbers.

### 5.4 Performance (S7; tag `perf`, runs in normal CI)
- **Save**: in-memory DB with 20,000 rows; 20 saves through
  `QuickAddNotifier.save()` (validation + repository); print p50 / p95;
  **gate: fail only if p50 > 250ms; print the real p50 / p95 and record them (target 100ms).**
- **Open data**: `quickAddDataProvider` with 20,000 rows; 10 runs;
  print p50 / p95; **gate: fail only if p50 > 250ms; print and record the real numbers (target 100ms)** (leaves room in the 300ms open
  budget, which also covers the 250ms sheet animation running at the
  same time).
- Query plan test: the 5 Quick Add queries use `ix_tx_date`.
- Manual (qa-reviewer, profile mode on a real Android phone): tap + to
  pad usable and data shown < 300ms in the DevTools timeline; record it
  in the PR.

### 5.5 Widget tests (in-memory DB, `FakeClock`, `test/support/*` helpers)
- Opens from the + button; pad works before data arrives.
- Happy paths: expense in 3 steps, income, transfer, repeat recent.
- Save disabled for empty / zero; refused digits show hints.
- Double tap Save → one row; sheet closes once; toast shows; Undo works.
- Save error card on a forced failure (account deleted mid-way); fields
  kept.
- Transfer disabled with one account + hint; To picker disables From;
  swap.
- Date chips; date picker range; note sheet limits.
- Hardware keys; Android back closes; reduce motion → zero durations.
- Text scale 2.0: no overflow; keys ≥ 44.
- Existing app, accounts and statement tests still pass.

### 5.6 Goldens (tag `golden`, Linux only, setup from session 3)
Folder `test/features/quick_add/presentation/goldens/`:
`quick_add_loading.png`, `quick_add_expense_empty.png`,
`quick_add_expense_typing.png`, `quick_add_amount_refused.png`,
`quick_add_income.png`, `quick_add_transfer.png`,
`quick_add_transfer_disabled.png`, `quick_add_recent_applied.png`,
`quick_add_saving.png`, `quick_add_save_error.png`,
`quick_add_no_categories.png`, `quick_add_load_error.png`,
`quick_add_saved_toast.png`, `quick_add_account_picker.png`,
`quick_add_all_categories.png`, `quick_add_note_sheet.png`,
`quick_add_date_picker.png`, `quick_add_textscale2.png`,
`category_chips_all_groups.png` (10 groups, selected and not).
Updated: `test/features/accounts/presentation/goldens/statement_data.png`
(group tints). Fixed seed: 7 preset accounts, fixed-id entries, clock
2026-11-12. All attached to the PR.

## 6. qa-reviewer checklist
- [ ] **DESIGN.md token check**: no hex outside `app_colors.dart`; no
      raw sizes, durations or curves in `lib/features/quick_add` (grep
      for `Color(0x`, `Duration(`, `EdgeInsets.all(<number>` etc.);
      every value maps to a DESIGN.md name, incl. the sec. 9 additions.
- [ ] Motion: every animation uses `AppMotion.resolve`; reduce motion
      gives fades only (no nudge, slide, scale or turn).
- [ ] **Money check**: no `double` in Quick Add money code; paise only
      from `parseRupeesToPaise`; sec. 5.3 numbers hand-checked; transfer
      changes both balances and no spending / income / category /
      monthly totals; nothing rounded, >2 decimals refused.
- [ ] Double save impossible (tap and code paths).
- [ ] Validation table (sec. 2.9) covered in UI and repository.
- [ ] Logs: no amounts, notes, names, dates or clipboard text.
- [ ] No schema change (`schemaVersion` still 1, no new dump), no new
      package in `pubspec.yaml`.
- [ ] Nothing from later sessions (no list, edit, delete screen,
      dashboard, budgets).
- [ ] Performance gates pass; manual open timing recorded.
- [ ] Accessibility: 44 targets, semantics labels, text scale 2.0.
- [ ] All goldens present, reviewed by eye, attached to the PR.
- [ ] `dart format`, `flutter analyze --fatal-infos`, `flutter test`
      green.

## 7. Low-risk decisions (also logged in DECISIONS.md)
1. "Last used" and "recent / frequent" are SQL queries on live
   transactions. No prefs, no new table, no new package.
2. Quick Add queries look at entries dated in the last 90 days (future
   dates included), by entry time (`created_at`); loan-linked entries
   are left out.
3. Archived accounts and categories are not offered in Quick Add.
4. The sheet always opens on Expense. Amount, date and note are shared
   by the tabs; account / category picks are kept per tab.
5. Defaults: last-used per type, with fallbacks (sec. 2.4). Transfer
   needs 2 offered accounts; otherwise the tab is disabled with a hint.
6. Category order: up to 6 suggested (last used, then most used), then
   the rest in sort order. One scrolling row plus an "All" sheet grouped
   by colour group.
7. Recent strip: up to 6 distinct recent entries of all types. A tap
   fills the form (type, amount, accounts, category, note), keeps the
   form's date and does not save by itself.
8. Number pad is always on screen (no system keyboard for the amount).
   Refused input never rounds; it shows a hint. Paste by long press.
9. Date rule in Quick Add: up to 31 days after today; quick "Today" and
   "Yesterday" chips plus a date picker.
10. After save the sheet closes and a toast shows for 4s with Undo
    (soft delete through the existing repository). No "add another"
    mode. Closing the sheet drops the draft without asking.
11. Today's date is read from the clock on each open.
12. Category colour groups map to existing colour tokens (sec. 9);
    statement rows use the group tint (closes the session 3 open item).
13. New DESIGN.md sizes, rules and motion token in sec. 9.
14. Speed targets (save < 100ms, open data < 100ms on 20,000 rows) are
    test gates on the median, with numbers printed. This differs from
    the session 2 "timings record only" rule because they are this
    session's "done when"; the margins are large.

## 8. Owner questions (hard to undo / money storage)

**Owner answers (2026-11-12):**
- Q1: **(a)** Hide the 4 loan categories in Quick Add for now. Do NOT
  change how they count in totals.
- Undo in the toast: **keep**.
- Speed tests: **fail only above 250ms (p50)**, and print / record the
  real numbers. Target stays 100ms.

- **Q1. Loan categories in Quick Add.** The seed has 4 loan categories
  (Loan Given, Loan Repayment, Loan Received, Loan Repayment Received).
  Quick Add cannot link an entry to a loan (loan screens are Phase 2).
  An entry saved with a loan category but **no loan link counts as
  normal spending or income** (budgets, top categories, dashboard).
  Fixing those rows later needs a data fix. Options:
  (a) Hide the 4 loan categories in Quick Add until loan screens exist.
  Lending can be recorded as a transfer to the "Outside" account
  meanwhile (it then stays out of spending).
  (b) Show them; such entries count as spending / income until Phase 2.
  (c) Show them, and change every spending / income sum to also leave
  out loan categories (changes a session 2 money rule).
  **Recommend (a)**: no wrong totals, nothing to clean up later, easy to
  turn on in Phase 2. The plan is written for (a); (b) is a one-line
  change.

## 9. Schema and DESIGN.md
- **Schema change: none.** `schemaVersion` stays 1. No new index (the
  queries use `ix_tx_date`). No new package.
- **DESIGN.md additions** (low risk, decided by the team; project-manager
  adds them to DESIGN.md when the plan is approved, senior-dev adds them
  to `lib/shared/theme` in S5):

| Token / rule | Value | Use |
|--------------|-------|-----|
| `numPadKeyHeight` | 56 | Number pad key (gap `space2`) |
| `chipHeight` | 44 | Category chips, recent chips, detail pills, tab segments (= the 44 tap target) |
| `chipIconCircle` | 28 | Tinted icon circle inside a chip (icon `iconChip` 16) |
| `toastDuration` (motion) | 4000ms | How long the saved toast (and Undo) stays |
| Choice chip | Not selected: `tile` fill, `ink` label (`body`), icon circle in the group tint. Selected: `primaryDeep` fill, `onDark` label, icon circle `background` with `ink` icon. `radiusPill`. Change `durationFast`, `curveEnter` | Category, recent, detail chips |
| Segmented tabs | `tile` pill track, `chipHeight`; selected segment `primaryDeep` fill + `onDark` `bodyStrong`; others `ink` `body`; disabled `iconInactive`. Indicator slides `durationFast` `curveEnter`; reduce motion: fade | Expense / Income / Transfer |
| Number pad key | `tile` fill, `radiusField`, `headline` `ink` digits, icons 24 `ink`. Pressed: `navIndicator` fill + `pressScale`, `durationFast` | Quick Add pad |
| Refused input | Amount nudges `space2` sideways and back, `durationMedium`, `curveEnter`; hint `caption` in `danger`. Reduce motion: hint fade only | Amount display |
| Toast | `primaryDeep` fill, `onDark` `body` text, action `bodyStrong` `onDark`, `radiusCard`, `shadowFloat`, margin `space6`, sits above the nav bar. In: `space4` slide up + fade `durationMedium` `curveEnter`; out: fade `durationFast` `curveExit` | Save confirmation |
| Category colour groups | Tint = token at 20% opacity behind an `ink` icon. essentials `accountScb`, food `accountHand`, transport `accountOutside`, home `sun`, lifestyle `accountSbi`, health `primaryLight`, family `lime`, finance `accountPf`, other `iconInactive`, income `primary` | Category circles everywhere |

Colour groups reuse existing tokens (no new hex). The stored value is
the group name, so changing a colour later is a one-line change.

## 10. Docs after build (project-manager)
FEATURES.md (Feature 2 and the colour-group gap in the Data model
section), CHANGELOG.md, DECISIONS.md (sec. 7 + owner answer + build
choices), DESIGN.md (sec. 9), DATABASE.md (Quick Add queries and
timings, no schema change).
