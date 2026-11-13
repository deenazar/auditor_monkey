# Design polish plan (before session 5)

- **Owner pre-approved: build starts immediately.** No approval wait.
- Date: 2026-11-13. Planned by project-manager.
- Suggested branch: `feature/20261113-design-polish` (from `develop`).
- DESIGN.md updated first (Motion, Motion patterns, Illustrations,
  Mascot, Demo data, Accessibility). DESIGN.md wins over this plan.
- **No schema change** (`schemaVersion` stays 1). Nothing from later
  sessions: no dashboard numbers, budgets or transactions list.

## Goal
Make the existing screens (Home, Accounts, statement, wizard, Quick Add,
shell) feel alive and friendly: purposeful motion, original
illustrations, a 3D Auditor Monkey, and demo data for testing the look.

## Scope
1. **Motion**: new tokens + patterns (DESIGN.md Motion): card entrance
   with stagger, balance roll-up, Quick Add spring open, save success
   check, tab fade-through, shared-axis page push, reduce-motion and
   60fps rules.
2. **Illustrations**: 10 SVGs + `mascot_poster.svg` in
   `assets/illustrations/`, `flutter_svg`, used in empty / error states
   and the wizard.
3. **3D mascot**: `flutter_3d_controller` + `visibility_detector`;
   `MascotView` on Home and wizard; placeholder `assets/3d/monkey.glb`
   made by `tool/make_placeholder_glb.py`.
4. **Demo data** (debug / profile only): separate DB file
   `auditor_monkey_demo.sqlite`, marker file, load / clear actions,
   "Demo data" ribbon in the shell.

Out of scope: new screens, schema change, dashboard numbers, budgets,
transactions list, dark mode.

## Tasks (parallel)
### senior-dev
| ID | Task | Acceptance |
|----|------|------------|
| S1 | `AppMotion` tokens (`durationStagger`, `staggerMaxItems`, `cardEnterOffset`, `pageSlideOffset`, `sheetSpring`, `tabFadeScaleFrom`, `successPopFrom`); shared `StaggeredEntrance` / `CardEntrance` widget; go_router page transitions (tab fade-through, shared-axis push) | All via `AppMotion.resolve`; reduce motion = no move / scale / stagger / spring; only opacity + transform; `RepaintBoundary` around animated parts |
| S2 | Quick Add spring open (`sheetSpring`); toast success check (draw + pop) | Pad takes taps on frame 1; open budget test still green; check drawn `durationSlow` |
| S3 | `RollingAmount` first-show rule: per-screen "seen this launch" flag (in-memory provider), roll from 0 first time, then old → new | Second visit does not roll from 0; reduce motion = final value |
| S4 | Mascot: add `flutter_3d_controller`, `visibility_detector`; `MascotView(state, size)` with lazy start after first frame, pause/unmount off-screen and in background, poster fallback (loading, error, tests, reduce motion), tap → `happy` once + light haptic, missing clip → `idle` | Never blocks first frame; semantics label per DESIGN.md; a test-mode flag forces the poster |
| S5 | `tool/make_placeholder_glb.py` (low-poly monkey head, 5 named clips) + generated `assets/3d/monkey.glb`; CI test: glb exists, under 3 MB, has the 5 clip names | Script runs with plain Python 3, no network |
| S6 | Demo data: separate DB file + marker file, `DemoModeController` (load / clear), guarded by `!kReleaseMode`, seed of realistic entries via existing repositories; entry point in a debug-only menu | Real DB untouched; clear deletes demo file and reopens the real one; release build has no demo code path |

### junior-dev
| ID | Task | Acceptance |
|----|------|------------|
| J1 | Draw 11 SVGs (10 listed + `mascot_poster`), palette tokens only | Each < 8KB; no gradients, no text; a test checks size and that every fill / stroke hex is a DESIGN.md token |
| J2 | `AppIllustration(name)` widget (`flutter_svg`, size rule 160 / 120, wizard 200 / 160, `ExcludeSemantics`); use it in existing empty / error states and wizard steps | Replaces `iconLarge` icons where an illustration exists |
| J3 | Apply card entrance + stagger to Home, Accounts carousel group, statement first page, wizard steps | Max 8 staggered; no list layout animation |
| J4 | `DemoRibbon` in the shell (uses S6 state) | `warning` fill, `ink` text, pinned top |
| J5 | Place `MascotView` on Home (160) and wizard (180) with each screen's state (Home `idle`, wizard `idle` → `celebrating` on done) | Uses S4 API; Home layout unchanged otherwise |

Order: S1, S4, S5, S6, J1 start together. S2, S3 after S1. J2 after J1.
J3 after S1. J4 after S6. J5 after S4. Then qa-reviewer.

## Tests
**Widget**
- Reduce motion: entrance, tab change, page push, sheet open, success
  check all have zero movement / scale; numbers show final value; mascot
  shows the poster.
- Stagger: item 9+ start with item 8; delays 40ms apart.
- RollingAmount: rolls from 0 on first show, from old value after.
- Quick Add: pad digit tap works during the spring (frame 1).
- Mascot: poster before first frame and in tests; tap → `happy` request
  + haptic; off-screen → paused; semantics label present.
- Illustrations: excluded from semantics; 120pt at text scale 1.5.
- Demo: ribbon shows only in demo mode; clear switches back to the real
  DB file; real DB rows unchanged after load + clear.
- Asset tests: SVG < 8KB and palette-only; `monkey.glb` < 3 MB with 5
  clip names.

**Golden** (Linux, final frame, reduce motion off, poster for mascot)
`home_with_mascot.png`, `accounts_empty_illustration.png`,
`statement_empty_illustration.png`, `error_generic.png`,
`wizard_welcome.png`, `wizard_done.png`, `quick_add_saved_toast.png`
(updated: check), `demo_ribbon.png`, `illustrations_all.png`.
Existing goldens updated only where the empty / error icon became an
illustration.

## Risks
| Risk | Mitigation |
|------|------------|
| WebView memory and first-load cost of the 3D view | Lazy start after first frame, only on-screen, unmount off-screen, poster first |
| WebView cannot render in widget tests / goldens | Test flag forces poster; goldens use poster |
| Spring makes Quick Add feel slower | Usable from frame 1; budget is first frame, not settle |
| Jank from many animations | 60fps rule; profile-mode check on a real phone by qa-reviewer |
| Demo data mixing with real data | Separate file, ribbon, release builds tree-shake it |
| Owner's real model breaks the app | Exact model requirements in DESIGN.md, CI size / clip test, missing clip → `idle`, error → poster |

## Docs after build (project-manager)
FEATURES.md (design polish section), CHANGELOG.md, DECISIONS.md (build
choices), DESIGN.md (any token changes found in build).
