# Motion & illustration pass: every screen at the Home dashboard's level

Owner request (2026-11-13): bring every screen, sheet, dialog and state up
to the Home dashboard's quality bar. Rule from now on (DESIGN.md and
CLAUDE.md): **every new screen must ship with illustration, motion and
interaction at the Home dashboard's level.**

The five columns are the owner's checklist:

- **Illustration**: an original vector illustration or an animated
  mascot moment.
- **Motion**: staggered entrance, number roll-ups, animated header
  blobs, Hero transitions, shimmer while loading.
- **3D**: tilt on touch, parallax on scroll, 3D page / step
  transitions, layered depth shadows.
- **Interaction**: haptics, springy buttons, swipe actions on rows,
  long-press previews.
- **Mascot reacts**: the Auditor Monkey reacts to what the user does on
  that screen.

Shared for all screens:

- Pushed pages swing in with a 3D Y-axis turn while the page beneath
  recedes.
- Every bottom sheet rises on the springy sheet curve with a haptic
  (`showWowSheet`).
- Every loading block shimmers.
- Reduce motion turns all movement off; haptics, moods and speech stay.

## Screens

| ✓ | Screen | Illustration | Motion | 3D | Interaction | Mascot reacts |
|---|--------|--------------|--------|----|-------------|---------------|
| ✅ | **Home** (the bar) | 2.5D monkey in hero; `success_goal` card | Blob hero, roll-ups, chart draws in, stagger, shimmer | Tilt summary / tiles / goal card, parallax hero, layered shadows | Swipe-delete + Undo, long-press preview, pull-to-refresh, haptics | Save, over plan, back on track, goal + confetti, refresh, delete, follows finger, sleeps late |
| ✅ | Start (opening) | Monkey "Opening your books…" (slow starts) | Ring fades in | — (no content) | — | Says hello |
| ✅ | Start (error) | Worried monkey moment | Stagger title / text / button | — | Springy retry, warning haptic | Nods sad, "Let's try that again" |
| ✅ | Wizard: welcome | Living hero + waving monkey | Blob header | 3D step turn | Springy button | Waves, follows finger |
| ✅ | Wizard: pick accounts | `wizard_pick` + monkey moment | Stagger tiles | Tiles tilt, 3D step turn | Haptic per pick, springy "Add another" | Hops on pick, shakes on unpick |
| ✅ | Wizard: add / edit account sheet | Live preview card + monkey | Stagger, springy sheet | Preview tilts, layered shadow | Haptics on type / colour, warning on invalid | Perks up typing, hops / spins on picks, nods on errors |
| ✅ | Wizard: opening balances | `wizard_balances` + monkey moment | Stagger rows | 3D step turn | Haptics on keys | Perks up while typing |
| ✅ | Wizard: review | Celebrating monkey (dance + stars) | Net worth rolls, stagger | Mini cards tilt, layered shadows | Springy "Create accounts" | Dances "Looks great!"; nods if save fails |
| ✅ | Wizard: done | Confetti burst + success haptic | Confetti | 3D tumble pieces | Success haptic | Celebrates |
| ✅ | Wizard: save error | Error card shakes in | Shake | — | Warning haptic | Nods sad |
| ✅ | Accounts list | Living header with monkey | Blob header, net worth rolls, stagger, shimmer loading | Cards tilt + layered shadows, parallax title, Hero into statement | Swipe right = preview, swipe left = open, long-press preview, pull-to-refresh, haptics | Waves; hops on new account; looks as cards change; spins on refresh |
| ✅ | Accounts: empty | `empty_accounts` pops in | Stagger | Depth pop-in | Springy button | — (illustration state) |
| ✅ | Accounts: error | Worried monkey moment | Stagger | — | Springy retry | Nods sad |
| ✅ | Add account sheet | Live preview card + monkey | Springy sheet, stagger | Preview tilts | Haptics | Perks up, hops, "New account added!" |
| ✅ | Account detail (statement) | Monkey in top bar; `empty_statement` + waving monkey when empty | Balance rolls, Hero arrival, chart bars draw in, stagger, shimmer loading | Balance card + chart tile tilt, layered shadow, 3D page turn | Swipe-delete + Undo, long-press row preview, pull-to-refresh, haptics | Checks on edit save, shakes on delete, spins on refresh |
| ✅ | Edit account sheet | Live preview card + monkey | Springy sheet, stagger | Preview tilts | Haptics, warning on invalid | Perks up / nods; "Saved!" on the statement |
| ✅ | Statement: not available | Worried monkey moment | Stagger | — | Springy "Back to Accounts" | Nods "Hmm, can't find it" |
| ✅ | Statement: error | Worried monkey moment | Stagger | — | Springy retry | Nods sad |
| ✅ | Quick Add: expense | Header monkey | Amount rolls, stagger middle, shimmer loading, springy sheet | Amount turns over in 3D on type change | Haptic on every key / chip / tab / pill, springy keys | Perks up typing, nods on refused amount, hops on save |
| ✅ | Quick Add: income | Same | Same | Same | Same | Spins "Money in!" |
| ✅ | Quick Add: transfer | Same | Same | Same | Same + warning haptic if transfer is off | Spins "Moving money" |
| ✅ | Quick Add: note sheet | Monkey moment | Springy sheet | — | Haptics | Writes along while you type |
| ✅ | Quick Add: account picker sheet | — (list sheet) | Springy sheet, stagger rows | Rows tilt | Haptic per pick | — |
| ✅ | Quick Add: all categories sheet | Category icons | Springy sheet, stagger groups | — | Haptic per chip | — |
| ✅ | Quick Add: date picker dialog | — | Material dialog motion | — | Haptic on open and pick | — |
| ✅ | Quick Add: saved toast | Drawn success check | Check draws in, slide | — | Success haptic, Undo | Monkey hops on Home |
| ✅ | Quick Add: save error | Error card shakes in | Shake | — | Warning haptic | Header monkey nods |
| ✅ | Quick Add: load error | Worried monkey moment | Stagger | — | Springy retry | Nods sad |
| ✅ | Settings (new) | Living header + monkey; About card with monkey | Blob header, stagger rows | Rows tilt, parallax title, 3D page turn | Swipe right = run, long-press preview, haptics, springy | Waves; dances + confetti on "Say hi"; spins / nods for motion |
| ✅ | Demo data sheet | Monkey moment | Springy sheet, stagger | — | Springy button, haptics | Says hello; confetti when demo data loads |
| ✅ | Insights (placeholder) | `empty_insights` pops in + header monkey | Blob header, stagger | Parallax title | Haptics on nav | Waves |
| ✅ | Transactions (placeholder) | `empty_transactions` pops in + header monkey | Blob header, stagger | Parallax title | Haptics on nav | Waves |
| ✅ | Home: empty | `empty_home` pops in | Stagger | Depth pop-in | — | Hero monkey stays |
| ✅ | Bottom bar | — | Springy indicator | — | Haptic per tab, springy Quick Add | — |
| ✅ | Long-press preview (all) | Content card | Spring scale-in | Blur + layered shadow | Success haptic | — |
| ✅ | Dashboard (Home, session 6) | Hero monkey; `empty_top_spending` for a month with no spending; doughnut empty mascot moment ("Add an account balance to see it here") | Stagger across sections, all amounts roll, doughnut sweeps in and morphs, Top 3 bars grow, shimmer skeletons | Month tiles (one row), doughnut card and Top 3 card tilt with layered shadows; hero parallax; the statement opens in the Accounts tab with its page turn | Haptic on taps, springy tiles and "See all", slice select, long-press previews, swipe-delete + Undo, pull-to-refresh | Worried when over budget, "Back on track!"; looks at the tapped slice and says e.g. "PF holds 50%"; hops on save; spins on refresh |
| ✅ | Dashboard: section error | Worried mascot moment (that card only) | — (shows at once) | — | Springy "Try again" | Worried look |
| ✅ | Dashboard: only negative balances | Mascot moment "Only debts for now" | Stagger | Card tilts | — | Idle |

"—" means the item does not fit that screen. For example, a list sheet
has no hero to show a mascot in.

## Tests

- Kit: swipe actions (keep vs remove), `DepthTurn`, `ShakeIn`, sheets at
  once with reduce motion; earlier wow toolkit tests.
- Settings: rows and monkey, licences page, long-press preview.
- Statement: monkey, tilts and preview; swipe-delete + Undo on a real
  database.
- Updated: error states now show the mascot; the page transition test
  allows the 3D turn; `StaggeredEntrance` keeps semantics while fading.
- Goldens regenerated (Linux, Flutter 3.47.9).
