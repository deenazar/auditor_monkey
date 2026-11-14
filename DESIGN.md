# Auditor Monkey Design

Single source of truth for every design token. Code (`lib/shared/theme/`)
must use these names and values; change them here first.

- Reference: [`docs/design/reference.png`](docs/design/reference.png)
- Style: light, fresh and flat. Mint and soft-yellow blocks on white,
  dark-green text, rounded shapes, thin outline icons, no heavy shadows.
- Theme: light only in Phase 1.
- Units: Flutter logical pixels (pt). Sizes were measured from the
  reference (the phone is about 472px wide in the image, so 1px is
  about 0.83pt) and rounded to the 4pt grid.

## Colors

### Base
| Token | Hex | Use |
|-------|-----|-----|
| `background` | `#FFFFFF` | Screen background |
| `canvas` | `#F5F5F5` | Behind sheets and dialogs |
| `tile` | `#F7F7F7` | Small stat tiles |
| `divider` | `#ECEFEE` | Hairline dividers, chart grid lines |

### Brand
| Token | Hex | Use |
|-------|-----|-----|
| `primary` | `#70D0B2` | Mint: hero header, main card, Quick Add button, first chart series, progress fill |
| `primaryLight` | `#8CD6A6` | Top of the area-chart gradient |
| `primaryDeep` | `#476E61` | Card side-tab, selected chip, pressed state |
| `accentText` | `#2A8466` | Green text on white: small page titles, links, income amounts |
| `lime` | `#E4E782` | Summary card overlapping the hero; second chart series |
| `sun` | `#FDD85C` | Highlights; third chart series |
| `notifDot` | `#DCE91D` | Unread badge dot |
| `navIndicator` | `#DDF4EC` | Soft mint pill behind the active nav icon |

### Text and icons
| Token | Hex | Use |
|-------|-----|-----|
| `ink` | `#1E3B31` | Main text, big numbers, text and icons on mint, lime and yellow |
| `inkMuted` | `#5F7670` | Secondary text: sub-labels, dates, list amounts |
| `iconInactive` | `#868E8B` | Inactive nav icons |
| `onDark` | `#FFFFFF` | Text on `primaryDeep`, SBI and PF only |

### Status
| Token | Hex | Use |
|-------|-----|-----|
| `success` | `#3FA37F` | Budget under 80% (bars, icons) |
| `warning` | `#F2B84B` | Budget 80% to 100% (bars, icons) |
| `danger` | `#C2453A` | Budget over 100%, delete, errors (also as text) |

### Amounts
| Kind | Colour | Sign |
|------|--------|------|
| Expense | `ink` | `−` |
| Income | `accentText` | `+` |
| Transfer | `inkMuted` | none, with a ⇄ icon |
| Balance (plain) | `ink` | `−` when negative, none when positive |

### Accounts
| Account | Token | Hex | Text on it |
|---------|-------|-----|------------|
| Axis (yellow) | `accountAxis` | `#FDD85C` | `ink` |
| SBI (magenta) | `accountSbi` | `#C2457F` | `onDark` |
| SCB (green) | `accountScb` | `#4CB58E` | `ink` |
| Hand (orange) | `accountHand` | `#F59E5B` | `ink` |
| Food Card (lime) | `accountFoodCard` | `#C9D86A` | `ink` |
| Outside (sky blue) | `accountOutside` | `#6BB8E0` | `ink` |
| PF (deep green) | `accountPf` | `#476E61` | `onDark` |

The colour picker offers 9 colours. `sun` (`#FDD85C`) is the same yellow as Axis, so it is left out of the picker. It stays a valid token for stored values.

### Category colour groups
Tint = the token at 20% opacity behind an `ink` icon. The stored value
is the group name, so a colour can change in one place.

| Group | Token |
|-------|-------|
| essentials | `accountScb` |
| food | `accountHand` |
| transport | `accountOutside` |
| home | `sun` |
| lifestyle | `accountSbi` |
| health | `primaryLight` |
| family | `lime` |
| finance | `accountPf` |
| other | `iconInactive` |
| income | `primary` |

### Chart series order
`primary`, `lime`, `sun`, then account colours in the order above.

## Typography
- Font family: **Outfit** (Google Fonts).
- Amounts always use tabular figures (`FontFeature.tabularFigures()`).
- The ₹ sign is drawn at about 75% of the digit size, weight Light 300.

| Token | Size | Weight | Line height | Letter spacing | Example |
|-------|------|--------|-------------|----------------|---------|
| `displayAmount` | 40 | Light 300 | 1.1 | 0 | Hero balance |
| `displayTitle` | 32 | Regular 400 | 1.15 | 0 | "Your cards" style page title |
| `headline` | 22 | Medium 500 | 1.2 | 0 | Stat on summary card |
| `title` | 18 | Medium 500 | 1.3 | 0 | Greeting (name in SemiBold 600), section titles |
| `bodyStrong` | 15 | SemiBold 600 | 1.4 | 0 | List item name |
| `body` | 15 | Regular 400 | 1.4 | 0 | Normal text, list dates |
| `caption` | 13 | Regular 400 | 1.35 | 0 | Sub-labels, list amounts |
| `overline` | 11 | Medium 500 | 1.3 | 2.5, all caps | "AVAILABLE FUNDS", tile labels |
| `pageEyebrow` | 18 | SemiBold 600 | 1.3 | 0 | Small green page title ("Your Wallet" style), colour `accentText` |

## Spacing
4pt grid.

| Token | Value |
|-------|-------|
| `space1` | 4 |
| `space2` | 8 |
| `space3` | 12 |
| `space4` | 16 |
| `space5` | 20 |
| `space6` | 24 |
| `space8` | 32 |
| `space10` | 40 |

| Rule | Value |
|------|-------|
| Screen side padding | `space6` (24) |
| Between list rows | `space5` (20) |
| Between sections | `space8` (32) |
| Card inner padding | `space6` (24) |
| Minimum tap target | 44 |

Alignment: hero headers and page titles are centred; lists are left
aligned with the date or amount right aligned.

## Radius
| Token | Value | Use |
|-------|-------|-----|
| `radiusHero` | 32 | Bottom corners of the hero header |
| `radiusCard` | 20 | Cards, summary card, account cards, stat tiles, sheets (top corners) |
| `radiusField` | 12 | Text fields, number-pad keys |
| `radiusPill` | 999 | Chips, buttons, chart bars, progress bars |
| `radiusCircle` | 50% | Avatars, icon circles, Quick Add button |

## Component sizes
| Token | Value | Use |
|-------|-------|-----|
| `accountCardHeight` | 200 | Account carousel card |
| `accountSideTabWidth` | 40 | Card side-tab with the vertical account name |
| `carouselPeek` | 24 | How far the next card peeks in from the right |
| `buttonHeight` | 52 | Primary pill button |
| `fieldHeight` | 52 | Text fields |
| `iconCircle` | 44 | Leading circle in list rows |
| `colourDot` | 20 | Colour dot in rows |
| `colourSwatch` | 32 | Colour swatch in the picker (inside a 44 tap target) |
| `statChartHeight` | 160 | Chart inside a stat tile |
| `iconInline` | 20 | Inline icons (see Icons) |
| `iconChip` | 16 | Icons inside chips |
| `outlineStroke` | 1.5 | Lucide outline icon stroke |
| `iconLarge` | 48 | Icon in empty and error states |
| `progressRing` | 24 | Loading ring |
| `progressStroke` | 2 | Loading ring stroke |
| `fieldLineWidth` | 2 | Focus and error line on text fields |
| `stepDot` | 8 | Wizard step dot; the active dot is a pill `stepDotActiveWidth` 24 wide |
| `skeletonTitleHeight` | 32 | Loading skeleton: title line (height) |
| `skeletonTitleWidth` | 180 | Loading skeleton: title line (width) |
| `skeletonCardHeight` | 120 | Loading skeleton: balance card |
| `chartBarWidth` | 6 | Bar width in the income-vs-expense chart (pill bars) |
| `chartGridLine` | 1 | Chart grid line (`divider`) |
| `numPadKeyHeight` | 56 | Quick Add number pad key (gap `space2`) |
| `chipHeight` | 44 | Category chips, recent chips, detail pills, tab segments (= the 44 tap target) |
| `chipIconCircle` | 28 | Tinted icon circle inside a chip (icon `iconChip` 16) |
| `quickAddSheetHeightFraction` | 0.92 | Share of the available height the Quick Add sheet uses |
| `categoryLabelMaxWidth` | 160 | Longest category name in a chip before it is cut with an ellipsis |
| `recentLabelMaxWidth` | 120 | Longest recent-entry label before it is cut with an ellipsis |
| `notePillMaxWidth` | 200 | Longest note preview in the note pill before it is cut |
| `typeTabInset` | 2 | Inset of the sliding pill inside the Expense / Income / Transfer track |
| `quickAddErrorHeight` | 280 | Height of the Quick Add load-error panel in the scrolling middle |

## Component rules
| Component | Rule |
|-----------|------|
| Account card side-tab | `primaryDeep` tab, `onDark` vertical text. On PF cards the tab is `ink`, because `accountPf` equals `primaryDeep` |
| Text field | Fill `tile`, no border, `radiusField`. Focused: 2pt `primaryDeep` line. Error: 2pt `danger` line and a `caption` message in `danger` |
| Primary button | `primary` pill, `ink` label in `bodyStrong`, `buttonHeight`. Disabled: `divider` fill, `inkMuted` label |
| Selectable tile | Not selected: `tile` fill. Selected: `navIndicator` fill and a `primaryDeep` check icon. No border (flat rule) |
| Loading ring | `progressRing` size, `progressStroke`, colour `primaryDeep` on white (`primary` is only 1.9:1, below the 3:1 rule for graphics); `ink` on mint |
| Choice chip | Not selected: `tile` fill, `ink` label (`body`), icon circle in the group tint. Selected: `primaryDeep` fill, `onDark` label, icon circle `background` with `ink` icon. `radiusPill`, `chipHeight`. Change `durationFast`, `curveEnter` |
| Segmented tabs | `tile` pill track, `chipHeight`; selected segment `primaryDeep` fill + `onDark` `bodyStrong`; others `ink` `body`; disabled `iconInactive`. Indicator slides `durationFast` `curveEnter`; reduce motion: fade |
| Number pad key | `tile` fill, `radiusField`, `numPadKeyHeight`, `headline` `ink` digits, icons 24 `ink`. Pressed: `navIndicator` fill + `pressScale`, `durationFast` |
| Refused input | Amount nudges `space2` sideways and back, `durationMedium`, `curveEnter`; hint `caption` in `danger`. Reduce motion: hint fade only |
| Toast | `primaryDeep` fill, `onDark` `body` text, action `bodyStrong` `onDark`, `radiusCard`, flat (elevation 0, as built in session 4), margin `space6`. Save toasts lead with the drawn success check (Motion patterns, `onDark` stroke, 24pt circle), above the nav bar, stays `toastDuration`. In: `space4` slide up + fade `durationMedium` `curveEnter`; out: fade `durationFast` `curveExit`. Reduce motion: fade only |
| Wizard step change | 24pt (`space6`) slide plus fade, `durationMedium`, `curveEnter` in and `curveExit` out. Reduce motion: fade only |

## Elevation and shadows
| Token | Value | Use |
|-------|-------|-----|
| `elevationNone` | none | All cards and tiles (flat colour blocks, no border) |
| `shadowFloat` | `0 4 16 rgba(30,59,49,0.12)` | Quick Add button, bottom sheets, menus |

## Icons
- Set: **Lucide** (`lucide_icons_flutter`), outline, about 1.5pt
  stroke, rounded ends.
- Sizes: 24 in the nav bar, 20 inline, 16 inside chips.
- Active nav icon: `ink`, on a `navIndicator` pill. Inactive: `iconInactive`.
  On mint: `ink`.
- Never emoji as icons. Category rows use an outline icon on a tinted
  circle (category colour at 20% opacity).

## Charts (fl_chart)
| Chart | Style |
|-------|-------|
| Area (balance over time) | Smooth curve, 2pt line (`onDark` on the mint hero, `ink` on white); fill is a vertical gradient `primaryLight` → transparent; filled dot on the latest point; no axes or grid on the hero |
| Doughnut (balances, category share) | Ring thickness about 25% of the radius, rounded segment ends, 2pt gaps, key number centred in `ink` |
| Bars (income vs expense, savings) | Pill bars 6pt wide, fully rounded; may be centred on a middle line; `primary` for income, `sun` for expense |
| Progress (budgets) | Pill bar 8pt tall on `divider`; fill `success` / `warning` / `danger` |

### Balance doughnut: legend and slice select (session 6)
- Max 5 slices. With 6 or more positive accounts: the 4 biggest +
  "Other" (last), coloured `iconInactive`. Other slices use the
  account's colour token.
- Only positive balances get a slice. Negatives show as an "Owed −₹…"
  line (`caption`, `inkMuted`) under the ring.
- Centre: "ASSETS" (`overline`) and the sum of the slices
  (`bodyStrong`). A selected slice swaps it to the account name and
  "₹… · %".
- Legend under the ring: dot, name, amount and %. Whole % adding to
  100; a share under 1% shows "<1%".
- First tap on a slice or legend row selects it: it pops out 6pt and a
  selection haptic plays. Second tap opens the account statement
  ("Other" does nothing).
- Sweep in `chartDraw`, morph on change `durationChart`; ring inside a
  `RepaintBoundary`. Reduce motion: final ring at once.

## Motion
| Token | Value | Use |
|-------|-------|-----|
| `durationFast` | 150ms | Pressed states, chip select, small fades |
| `durationMedium` | 250ms | Sheets, page transitions, list insert/delete |
| `durationSlow` | 300ms | Number roll, card carousel settle |
| `durationChart` | 400ms | Charts drawing in and morphing |
| `toastDuration` | 4000ms | How long the saved toast (with Undo) stays |
| `loadingIndicatorDelay` | 300ms | Start screen ring waits this long before it shows (no flash on fast starts) |
| `curveEnter` | `Curves.easeOutCubic` | Anything appearing or moving in |
| `curveExit` | `Curves.easeInCubic` | Anything leaving |
| `curveSpring` | soft spring (damping ratio about 0.8) | Card carousel snap |
| `springStiffness` | 200 | Spring of the card carousel snap (with `curveSpring`) |
| `springDampingRatio` | 0.8 | Spring damping of the carousel snap (`curveSpring`) |
| `durationStagger` | 40ms per item | Delay between items in a staggered entrance |
| `staggerMaxItems` | 8 | Items 1-8 are staggered; the rest appear together with item 8 |
| `cardEnterOffset` | 12 | Card entrance slide-up distance (pt) |
| `pageSlideOffset` | 24 | Pushed page shared-axis slide distance (pt, = `space6`) |
| `sheetSpring` | stiffness 380, damping ratio 0.82 | Quick Add sheet open: slight overshoot, settles in about 350ms |
| `tabFadeScaleFrom` | 0.98 | Incoming tab content scale start (to 1) |
| `successPopFrom` | 0.8 | Toast check mark scale start (to 1) |

### Motion patterns
| Pattern | Rule |
|---------|------|
| Card entrance | Fade + `cardEnterOffset` (12pt) slide up, `durationMedium`, `curveEnter`. In lists / groups each card waits `durationStagger` (40ms) more than the one before; max `staggerMaxItems` (8) staggered, the rest appear with the 8th |
| Balance numbers | `RollingAmount`, `durationSlow`. Rolls from 0 only the first time a screen shows per app launch; after that it rolls from the old value to the new one |
| Quick Add sheet open | `sheetSpring` (stiffness 380, damping 0.82), slight overshoot, settles in about 350ms. The sheet is usable from its first frame (pad takes taps during the spring). The 300ms open budget is about the first frame / interactive, not the settle. Close stays `durationMedium`, `curveExit` |
| Save success | In the toast: a check mark drawn inside a circle (stroke draws in) over `durationSlow`, with a small scale pop `successPopFrom` 0.8 → 1, `curveEnter` |
| Tab change (bottom bar) | Fade-through: outgoing content fades out `durationFast` (`curveExit`); incoming fades in + scales `tabFadeScaleFrom` 0.98 → 1 over `durationMedium` (`curveEnter`) |
| Pushed pages | Shared-axis horizontal: fade + `pageSlideOffset` (24pt) slide, `durationMedium`, `curveEnter` in, `curveExit` out |

Rules:
- Smooth and subtle. Numbers roll to new values; charts draw in and
  morph; list rows slide and fade.
- Nothing blocks the user while it animates.
- When the phone's "reduce motion" is on: no movement, no scale, no
  stagger, no spring (fades only or instant). Numbers show the final
  value at once. The mascot stays still (moods still change).
- 60fps rule:
  - Animate only opacity and transform (translate, scale, rotate).
  - Wrap each animated subtree in a `RepaintBoundary`.
  - No layout animations on lists (no animated heights / sizes of rows).
  - No animation may rebuild a whole screen; use `AnimatedBuilder` /
    transitions with a `child` so only the moving part repaints.

## Navigation
- Bottom bar: white background, no labels, 5 slots, icons only:
  1. Home (dashboard)
  2. Insights (charts)
  3. **Quick Add** (centre): `primary` circle, 56pt, `ink` + icon,
     `shadowFloat`
  4. Transactions
  5. Accounts
- Active tab indicator: `navIndicator` pill, 56x32, `radiusPill`, centred
  behind the 24pt icon. It fades and scales in (0.8 to 1) with
  `durationFast` and `curveEnter`; it fades out the same way. With reduce
  motion it only fades (no scale). Tap targets stay at least 44pt.
- Profile and settings: avatar button in the top bar of Home.
- Page header pattern: `pageEyebrow` in `accentText`, then
  `displayTitle` below it, both centred.

## Screen patterns
- **Home**: mint hero header (greeting, bell with `notifDot`, `overline`
  label, `displayAmount` total, area chart) → lime summary card
  overlapping the hero's bottom edge by about half its height → stat
  tiles → "Recent transactions" list.
- **Accounts**: horizontal card carousel; the current card fills the
  width, the next card peeks in about 24pt from the right in its own
  colour; a `primaryDeep` side-tab on the left shows the account name
  in vertical text.
- **List row**: leading 44pt circle (category icon on tinted circle),
  name in `bodyStrong`, amount below in `caption`, date on the right in
  `body`.
- **Stat tile**: `tile` background, `overline` label centred at top,
  one chart or number centred.
- Every screen has empty, loading and error states in this style.
- **Empty and error states**: illustration (see Illustrations) above
  the `title` and `body` text, centred, replacing the `iconLarge` icon
  where an illustration exists. The block enters with the card entrance.
- **Home** and the **setup wizard** show the 2.5D mascot (see Mascot).
- Cards and list groups on a screen use the card entrance with stagger
  (Motion patterns).

## Illustrations
Original flat vector SVGs, drawn with `flutter_svg`.

| Rule | Value |
|------|-------|
| Location | `assets/illustrations/*.svg` |
| Palette | DESIGN.md tokens only: `primary`, `primaryDeep`, `lime`, `sun` (yellow), `tile`, `ink`, `inkMuted`, `background` (white) |
| Style | Flat shapes, rounded corners, optional 2-3pt `ink` outlines, no gradients, no text inside the SVG, no photos of people. A friendly monkey character may appear |
| Size: empty / error states | 160pt tall; 120pt when the screen is short (height under 700pt) or text scale is 1.5 or more |
| Size: setup wizard | 200pt tall; 160pt on short screens / text scale 1.5+ |
| File size | Each file under 8KB |
| Semantics | Decorative: excluded from screen readers (`ExcludeSemantics`) |

| File | Where |
|------|-------|
| `empty_accounts` | Accounts, no accounts |
| `empty_transactions` | No transactions (used where an empty transaction list shows today) |
| `empty_statement` | Account statement, no entries |
| `empty_insights` | Insights tab placeholder |
| `empty_home` | Home with no data yet |
| `error_generic` | Any error state |
| `wizard_welcome` | Wizard step 1 |
| `wizard_pick` | Wizard: pick accounts |
| `wizard_balances` | Wizard: opening balances |
| `wizard_done` | Wizard: finished |
| `mascot_poster` | Still 2D poster of the mascot (see Mascot) |

## Mascot (Auditor Monkey)
The mascot is the **2.5D Auditor Monkey** (see "Motion & 3D"), drawn in
code in the `mascot_poster` palette: `primaryDeep` fur, `lime` face and
belly, `primary` inner ears, `ink` features, plus round glasses, a `sun`
clipboard and bow tie.

| Rule | Value |
|------|-------|
| Where | Home (hero, 92pt), setup wizard (welcome 168pt, review 180pt) |
| States | `idle`, `happy`, `worried`, `celebrating`, `sleeping` (each screen picks its state) |
| Tap | Reacts by zone (head, belly, ears, tail), double tap dances, stroke purrs; light haptic |
| Semantics | Button with the label "Auditor Monkey. Tap the head, belly, ears or tail, or stroke it. Double-tap for a dance." |
| Poster | `mascot_poster.svg` stays as the still 2D drawing (illustrations gallery) |
| 3D model | The `.glb` / WebView viewer is removed (see DECISIONS.md, 2026-11-13). A real model can come back later if it holds 60 fps on iPhone |

## Quality bar (permanent rule)
**Every new screen must ship with illustration, motion and interaction at
the Home dashboard's level.** Concretely, a screen (or sheet, dialog,
state) is done only when it has, where it fits:

| Area | Must have |
|------|-----------|
| Illustration | An original vector illustration (`assets/illustrations`, reference palette, pops in with `DepthPopIn`) or an animated mascot moment (`MascotMoment`) |
| Motion | Staggered entrance; numbers roll (`RollingAmount`); a living header (`AnimatedBlobs` / `WowHeader`) on top-level screens; Hero between related screens; `Shimmer` (via `SkeletonBlock`) while loading |
| 3D | Cards tilt (`Tilt3D`); headers parallax on scroll; 3D page / step transitions (built into pushed routes and the wizard); layered shadows on lifting cards |
| Interaction | Haptics on every tap (`AppHaptics`); springy buttons (`SpringPress`, `PrimaryButton`, `PressSurface`); swipe actions on list rows (`SwipeActionRow`); long-press previews (`LongPressPreview`); sheets via `showWowSheet` |
| Mascot | The Auditor Monkey reacts to what the user does on that screen (`MascotController.react / type / follow`) |

Reduce motion and 60 fps rules below apply to all of it. Track the work
in a checklist under `docs/plans/` (see `motion-illustration-pass.md`).

## Motion & 3D
A premium layer **on top of** the base design above. It adds depth and
motion only: no base colour, font, size or layout changes. Tokens live in
`app_depth.dart`, extra colours in the "Motion & 3D layer" part of
`app_colors.dart`, shadows in `app_shadows.dart`, widgets in
`lib/shared/wow/`.

### Tokens
| Token | Value | Use |
|-------|-------|-----|
| `perspective` | 0.0012 | Matrix4 entry (3,2) for every 3D transform |
| `tiltMax` | 8° | Card tilt under the finger |
| `pressScale` (depth) | 0.97 | Card press-in while tilted |
| `springy` | `Cubic(0.2, 1.6, 0.4, 1)` | Spring back after press / tilt; buttons, keys, chips, nav |
| `bouncy` | `Cubic(0.2, 1.3, 0.4, 1)` | Pop-ins, mascot reactions, previews |
| `press` | 200ms | Press scale time |
| `tiltSettle` | 450ms | Tilt follow / spring back |
| `parallaxBack` / `parallaxMid` | 0.35 / 0.18 | Share of the scroll a header layer moves |
| `flipDegrees` / `flip` | 70° / 420ms | `FlipSwitcher` page flip, `DepthTurn` |
| `pageTurnDegrees` / `pageRecedeScale` | 14° / 0.94 | Pushed page turn-in; page beneath recedes |
| `sheet` / `sheetOpen` | `Cubic(0.2, 1.1, 0.3, 1)` / 420ms | Bottom sheets rising (`showWowSheet`) |
| `stepTurnDegrees` | 28° | Wizard step turn (around the centre) |
| `blobLoop` | 14s | Header blob drift loop |
| `sceneRestAfter` | 15s | Endless loops (blobs, mascot) rest after the last touch |
| `shimmer` / `shimmerMax` | 1.4s / 10s | Skeleton sheen sweep; stops after 10s |
| `confetti` / `confettiPieces` | 1.8s / 60 | Goal confetti |
| `previewFrom` / `preview` | 0.86 / 320ms | Long-press preview scale-in |
| `chartDraw` | 900ms | Area chart drawing in |

| Colour | Value | Use |
|--------|-------|-----|
| `shadowContact` / `shadowKey` / `shadowAmbient` | ink 16% / 10% / 6% | Layered shadows |
| `blobMintLight` / `blobMintDeep` | `#9FE3CC` / `#4FBF9C` | Header blobs |
| `blobLime` / `blobSun` | lime 70% / sun 50% | Header blobs |
| `sheen` | white 35% | Tilt highlight, shimmer |
| `previewScrim` | ink 35% | Long-press preview backdrop (with 10pt blur) |
| `mascotFurLight` / `mascotFurShade` | `#6E9A8C` / `#33554A` | Mascot fur gradient around `primaryDeep` |
| `mascotFaceShade` | `#CDD15F` | Mascot face gradient around `lime` |
| `mascotTongue` | `#E07A6E` | Mascot open mouth |
| `confetti` | primary, lime, sun, primaryDeep, accountHand, accountOutside | Confetti pieces |

| Shadow | Value | Use |
|--------|-------|-----|
| `shadowLayered` | 0 1 2 (16%) + 0 6 14 (10%) + 0 18 36 −6 (6%) | Cards that lift: summary card, account cards |
| `shadowLifted` | 0 2 4 + 0 12 24 + 0 28 48 −8 | Pressed cards, long-press preview |

The base rule "cards are flat" still holds for tiles, rows and fields;
only the cards listed above lift.

### Building blocks (`lib/shared/wow/`)
| Widget | What it does |
|--------|--------------|
| `Tilt3D` | Perspective tilt towards the finger (up to `tiltMax`), press-in, moving sheen, spring back, light haptic |
| `SpringPress` / `PressSurface` / `PrimaryButton` | Springy press (`springy`), haptic on every tap |
| `Parallax` + `ScrollOffset` | Header layers move at `parallaxMid` / `parallaxBack` of the scroll and fade out |
| `FlipSwitcher` | 3D page flip between children (Y axis) |
| `AnimatedBlobs` | `primary` fill with drifting mint / lime / sun blobs and a slow light sweep; one painter |
| `Shimmer` | Sheen sweep over `SkeletonBlock` loading blocks |
| `Confetti` | 60 palette pieces burst, tumble in 3D and fall; removes itself |
| `LongPressPreview` | Long press: blur + scrim, the preview springs in; release / tap closes |
| `DepthPopIn` | One-shot entrance: tips forward 22° and grows from 0.9 (illustrations) |
| `WowHeader` | Living mint header (blobs, centred `PageHeader` in ink, parallax, mascot corner) for top-level screens |
| `MascotMoment` | The monkey for a state or step: mood + one reaction + speech, follows the finger |
| `SwipeActionRow` | Swipe actions on rows (delete removes the row; others spring back), warning haptic at the threshold, screen-reader actions |
| `showWowSheet` | Every bottom sheet: springy rise, `press` haptic, instant with reduce motion |
| `DepthTurn` / `ShakeIn` | 3D flip-board turn on a key change / error shake with warning haptic |
| `AppHaptics` | `tap` (keys, chips, tabs), `press` (buttons, cards), `success` (saved, goal, preview), `warning` (swipe threshold, refused tab, over plan) |

### Mascot in 2.5D
- One `CustomPainter`, 160×176 view box: radial fur gradient
  (`mascotFurLight` → `primaryDeep` → `mascotFurShade`), `lime` face
  gradient, `primary` rim light on head and body, a blurred contact
  shadow under the head and a ground shadow, glints on glasses and eyes,
  a soft `primaryLight` glow behind.
- Depth: the whole figure leans in perspective towards the finger
  (rotateY up to ±0.22 rad, rotateX ±0.14 rad). Layers shift by depth:
  tail −4pt, head +3pt, face +2.5pt more (parallax), so it reads as 3D.
- Follows touches: anywhere on Home and the wizard hero, the eyes and the
  lean follow the finger, easing back 2.5s after it lifts.
- Loops (from the CSS-keyframe port in `keyframes.dart`): breathing
  3.4s, head tilt 7s, tail swish 2.8s, blink 5.2s, glow float 8s, "zzz"
  3s while asleep. One-shots: jump, hop, shake, nod, dance ×2, spin,
  wave, ear twitch, purr, dizzy stars, star burst.
- Money events on Home: Quick Add save → hop + "Logged ₹…" (success
  haptic); month goes over plan (spending above income) → worried face,
  nod, warning haptic; back under → wave; savings goal (20% of income)
  reached after a save → dance, confetti, "Savings goal hit!"; pull to
  refresh → spin; swipe-delete → head shake. Idle 23:00–5:00 → asleep.

### Per screen
| Screen | Motion & 3D |
|--------|-------------|
| Home | `AnimatedBlobs` hero with parallax (text `parallaxMid`, chart `parallaxBack`, fades over 220pt); net worth rolls; area chart draws in (white line, `primaryLight` fill, end dot); mascot bottom-right; lime summary card tilts, `shadowLayered`, rolls; "Savings goal reached" card (`success_goal`) pops in and tilts; rows enter staggered, swipe left to delete (red, trash icon, `warning` haptic at 35%) with Undo, long-press preview; pull-to-refresh (`primaryDeep` ring on white) |
| Setup wizard | Welcome hero = `AnimatedBlobs` + 168pt mascot that waves hello and follows the finger; steps turn in 3D (`stepTurnDegrees`) while they slide and fade; review mascot celebrates; finishing set-up bursts confetti |
| Accounts | Carousel cards tilt (`Tilt3D`), lift on `shadowLayered`, and fly into the statement's balance card (`Hero`); list rows long-press to preview the card; pull-to-refresh |
| Statement | Receives the card `Hero`; chart bars draw in (base rule) |
| Quick Add | Haptic on every key, chip, pill, tab and account pick; springy presses; `warning` haptic on a refused tab; `success` haptic on save; mascot hops on Home |
| Empty / error / success states | Illustrations pop in with `DepthPopIn`; new `success_goal` illustration |
| Loading | `SkeletonBlock` shimmers (max 10s) |
| Bottom bar | Haptic on tab tap; Quick Add springs and gives a `press` haptic |
| Settings | Living header with back and monkey; rows tilt, spring, swipe right to run, long-press to preview; "Say hi" makes the monkey dance with confetti; opened from the gear on Home |
| Account sheets | Live preview card (tilts) + monkey that perks up while typing and nods on errors; springy sheet |
| Demo data sheet | Mascot moment, springy button, confetti when demo data loads |
| Pushed pages | Swing in 14° on the Y axis while the page beneath recedes to 0.94 and tilts away |
| Errors | Worried monkey moment (`ErrorState`); inline error cards shake in (`ShakeIn`) with a warning haptic |

### Rules
- **Reduce motion**: no tilt, parallax, flip, blobs, shimmer, confetti,
  pop-ins, chart draw or mascot movement. Things show their final state
  at once; transitions fade. Haptics, moods and speech still work.
- **60 fps on iPhone**: animate only transforms and opacity; each
  animated layer sits in its own `RepaintBoundary`; painters repaint
  through a `Listenable` (no widget rebuild per frame) and reuse their
  `Paint`s; endless loops rest after `sceneRestAfter`, shimmer after
  `shimmerMax`, and pause off-screen (`TickerMode`). No blur on scroll
  (blur only in the long-press preview).
- Money logic, data and schema are untouched; swipe-to-delete uses the
  existing soft delete and restore.

## Demo data
| Rule | Value |
|------|-------|
| Builds | Debug and profile only (never in release) |
| Ribbon | "Demo data" ribbon pinned at the top of the app shell while demo mode is on: `warning` fill, `ink` text in `caption` size at SemiBold 600, full width, above all content (below the status bar inset) |
| Purpose | Demo data can never be confused with real data |

## Accessibility
- Text contrast WCAG AA (4.5:1 normal, 3:1 large text and icons). All
  token pairs above were checked, e.g. `ink` on `primary` 6.6:1, `ink`
  on `lime` 9.3:1, `onDark` on `accountSbi` 4.7:1, active nav `ink` on
  `navIndicator` 10.6:1 and `ink` on white 12.2:1. The pill is decoration
  only (1.15:1 on white); the active state is also shown by the `ink` icon
  and the `selected` semantics.
- White on `primary` is **not allowed** (1.85:1).
- Supports large system text sizes without cutting off amounts.
- Decorative illustrations are excluded from semantics.
- The mascot has the semantic label "Auditor Monkey, tap to say hi".
- `ink` on `warning` (demo ribbon) is about 6.8:1.

## Assumptions
What was unclear in the reference, what we assumed, and the owner's
answer.

| # | Unclear | Assumption | Status |
|---|---------|------------|--------|
| A1 | Font not named; looks like a paid font (Gilroy / Sofia Pro style) | Use **Outfit** (free, close match); swap in one place if needed | Approved |
| A2 | Image is compressed, so edges blur | Hex codes taken from the middle of flat blocks; text colours rounded to `ink` and `inkMuted` | Approved |
| A3 | White text on mint fails contrast (1.85:1) | Use `ink` text and icons on mint | Approved |
| A4 | Only a light theme is shown | Light theme only in Phase 1; dark mode later from the same tokens | Approved |
| A5 | Centre nav slot is a profile photo | Make it the Quick Add + button; profile moves to Home's top bar | Approved |
| A6 | No red, amber or income colours in the reference | Added `success` `#3FA37F`, `warning` `#F2B84B`, `danger` `#C2453A`; income in `accentText` | Approved |
| A7 | Only four account colours were given | Suggested Food Card `#C9D86A`, Outside `#6BB8E0`, PF `#476E61` | Approved |
| A8 | Transaction rows show people's photos | Use category icons on tinted circles | Approved |
| A9 | The "42" badge and yellow strip on the card | Decoration: the strip is the next card peeking in; the badge is ignored | Approved |
| A10 | Sizes come from an image, not a design file | Approximate, rounded to the 4pt grid | Approved |
