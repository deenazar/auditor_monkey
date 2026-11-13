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
| Toast | `primaryDeep` fill, `onDark` `body` text, action `bodyStrong` `onDark`, `radiusCard`, `shadowFloat`, margin `space6`, above the nav bar, stays `toastDuration`. In: `space4` slide up + fade `durationMedium` `curveEnter`; out: fade `durationFast` `curveExit`. Reduce motion: fade only |
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

Rules:
- Smooth and subtle. Numbers roll to new values; charts draw in and
  morph; list rows slide and fade.
- Nothing blocks the user while it animates.
- When the phone's "reduce motion" is on, show final values instantly
  (fades only, no movement).

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

## Accessibility
- Text contrast WCAG AA (4.5:1 normal, 3:1 large text and icons). All
  token pairs above were checked, e.g. `ink` on `primary` 6.6:1, `ink`
  on `lime` 9.3:1, `onDark` on `accountSbi` 4.7:1, active nav `ink` on
  `navIndicator` 10.6:1 and `ink` on white 12.2:1. The pill is decoration
  only (1.15:1 on white); the active state is also shown by the `ink` icon
  and the `selected` semantics.
- White on `primary` is **not allowed** (1.85:1).
- Supports large system text sizes without cutting off amounts.

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
