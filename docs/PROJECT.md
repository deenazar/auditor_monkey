# Auditor Monkey

## Overview
Auditor Monkey is a personal expense tracker. It lets the owner record
daily spending and see where the money goes each month: a monthly total,
a breakdown by category, and filters to dig into the details.

- Currency: Indian Rupee (₹, INR), shown in Indian number format
  (e.g. ₹1,23,456.00).
- Categories (fixed): Food, Travel, Bills, Shopping, Other.

## Users
- One user: the owner, for personal use.
- No login, no accounts, no sharing.
- Used mostly on a phone browser, sometimes on desktop.

## Features
Must-have:
1. **Add expense**: amount (₹, required, greater than 0), category
   (one of the five), date (defaults to today), note (optional).
2. **Edit and delete expense**: change any field of a saved expense, or
   delete it (with a confirmation step).
3. **Expense list**: saved expenses for a month, newest first.
4. **Monthly summary**: total spent in the selected month, shown big.
5. **Category pie chart**: share of the month's spending per category.
6. **Filter by month and category**: pick a month and, optionally, one
   category. The list, total and chart all follow the filters.

Later:
7. **Monthly budget limits with alerts**: set a monthly limit and get a
   warning when spending gets near it or goes over.
8. **Export to Excel**: download expenses as an `.xlsx` file.

## Out of scope
- Login, user accounts, multiple users.
- Cloud sync, backup or a server/database (data lives only in this
  browser; clearing browser data deletes it).
- Income tracking, bank or UPI imports, receipts or photos.
- Custom categories and currencies other than INR.
- Native mobile apps (it is a mobile-friendly web app).

## Tech stack
Company default, no changes:
- React + Vite + TypeScript
- Tailwind CSS with the company "Warm Paper" design system
  (tokens in `src/styles/tokens.css`), icons from `lucide-react`
- Vitest for tests
- Storage: browser `localStorage`, behind a small storage module in
  `src/lib/` so it can be swapped later
- Must work well at 360px phone width

## Roadmap
One feature per session, in this order. Each session follows the
feature-workflow skill (plan → owner approval → build → review → PR).

1. **Project setup** (groundwork, no feature numbers)
   Goal: Set up Vite + React + TypeScript + Tailwind + Vitest. Add the Warm Paper tokens (`src/styles/tokens.css`), fonts, `lucide-react`, the base UI parts (Button, Card, Input, Modal), and the page shell with a page title. Add the shared `Expense` type in `src/types/`, the localStorage storage module, and the helpers for ₹ amounts in Indian format and for dates in `src/lib/`.
   Done when: `npm run build` and the tests pass, the empty page shell looks right at 360px, and the tests show ₹123456 formatted as "₹1,23,456.00".

2. **Add expense + Expense list** (Features 1, 3)
   Goal: Add an expense (amount, category, date, note) and see it right away in a list of this month's expenses, newest first. These two ship together because a saved expense you cannot see cannot be checked.
   Done when: an added expense shows at the top of the list and is still there after a page reload, an amount of 0 or less is rejected, and an empty month shows a friendly message with an "Add expense" button.

3. **Edit and delete expense** (Feature 2)
   Goal: Change any field of a saved expense, or delete it after a confirmation step.
   Done when: an edited expense shows the new values after a reload, and a delete only happens after you confirm it.

4. **Monthly summary** (Feature 4)
   Goal: Show the total spent this month as a big number in JetBrains Mono at the top.
   Done when: the total equals the sum of the month's expenses and updates right away after any add, edit or delete.

5. **Category pie chart** (Feature 5)
   Goal: Show a pie chart of how much of the month's spending went to each category. A chart library needs to be picked and logged in `docs/DECISIONS.md`.
   Done when: the slices match each category's share of the total, the chart is readable at 360px, and an empty month shows a friendly message instead of a chart.

6. **Filter by month and category** (Feature 6)
   Goal: Pick any month and, if you want, one category. The list, the total and the chart all follow the filters.
   Done when: changing the month or category updates the list, total and chart together, and clearing the category shows all five categories again.

7. **Monthly budget limit with alerts** (Feature 7, later)
   Goal: Set a monthly spending limit, saved in localStorage, and show a warning when spending gets near it or goes over.
   Done when: a warning shows near the limit (the "near" level, for example 80%, is decided and logged first), a danger alert shows once spending goes over, and the limit is kept after a reload.

8. **Export to Excel** (Feature 8, later)
   Goal: Download expenses as an `.xlsx` file. An xlsx library needs to be picked and logged in `docs/DECISIONS.md`.
   Done when: clicking Export downloads an `.xlsx` file that opens in Excel with the correct date, category, amount and note for each expense.
