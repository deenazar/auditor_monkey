# Auditor Monkey Design

Single source of truth for every design token. Code (`lib/shared/theme/`)
must use these names and values; change them here first.

- Source: the visual system of **mini_checklist** (`web/styles.css`,
  `web/mimi-world.css`, `web/mimi-world.js`), ported natively to Flutter
  (no WebView). Mimi the cat becomes the **Auditor Monkey**.
- Style: an illustrated sky that follows the time of day on top, a calm
  light panel that slides over it, frosted glass on the sky, white cards
  with a 1px line, a coral accent and springy, playful motion.
- Theme: light only in Phase 1 (mini_checklist's dark tokens are listed
  for later).
- Units: Flutter logical pixels (pt).

## Colors
Hex values live only in `app_colors.dart` and `sky_palette.dart`.

### Core tokens (styles.css `:root`)
| Token | Hex | Use |
|-------|-----|-----|
| `panel` | `#F5F8F7` | Page and sliding-panel background, sheets |
| `card` | `#FFFFFF` | Cards, rows, inputs, bottom bar |
| `ink` | `#10202A` | Text, icons, selected day chip, toast |
| `sec` (`inkMuted`) | `#5E6E76` | Secondary text, labels |
| `line` | `#DFE7E5` | 1px card borders, dividers, the panel handle |
| `fill` | `#EBF1EF` | Quiet fills: tracks, secondary buttons, tiles |
| `coral` | `#FF6B4A` | The accent: primary button, Quick Add, today |
| `teal` | `#0E9F9A` | Focus rings, progress start |
| `lime` | `#5DB82E` | Progress end, ticks |
| `sun` | `#F5A400` | Days with spending, warnings |
| `red` (`danger`) | `#E5484D` | Errors, over budget, busy days |
| `glass` | `rgba(8,16,30,.34)` | Dark glass on the sky |
| `glassInk` | `#FFFFFF` | Text and icons on glass |

Dark (later): panel `#0D161B`, card `#15222A`, ink `#E9F1F2`, sec
`#8EA1A8`, line `#22323A`, fill `#1B2A32`, coral `#FF7A5C`, teal
`#2CC4BE`, lime `#8ED85A`, sun `#FFC24D`, red `#FF6B6F`.

### App names mapped onto the tokens
| Name | Value | Use |
|------|-------|-----|
| `background` | `panel` | Screen background |
| `canvas` | `fill` | Behind grouped content |
| `tile` | `card` | Stat tiles, chips |
| `divider` | `line` | Dividers, chart grid |
| `primary` | `coral` | Main actions |
| `primaryLight` | `#FFE3DB` | Coral tint (selection, soft fills) |
| `primaryDeep` | `ink` | Selected chips, toast, date-picker day |
| `accentText` | `#C2410C` | Coral-family text on light surfaces (eyebrows, links) |
| `navIndicator` | `#FFE3DB` | Active tab pill |
| `success` | `#33801A` | Income amounts and success text |
| `warning` | `sun` | Demo ribbon, 80% budget |
| `iconInactive` | `#8A979D` | Inactive nav icons |
| `violet` | `#8E7BEF` | Category group "family" |

### Sky (mimi-world.css `.stage.sky-*`)
| Phase | Hours | Gradient (0 / 55 / 100%) | Orb | Hills (back / front) | Clouds |
|-------|-------|--------------------------|-----|----------------------|--------|
| dawn | 5:00–7:30 | `#6E7CF0` `#E9A3B8` `#FFD2AE` | `#FFD27A` | `#A8C99A` `#86B282` | .80 |
| day | 7:30–17:00 | `#5AA9F5` `#9ED1FF` `#DDF1FF` | `#FFE07A` | `#9BDDA8` `#74C98F` | .92 |
| dusk | 17:00–20:00 | `#3F4AA6` `#B46BAE` `#FF9C78` | `#FFB27A` | `#7E8FB8` `#62739E` | .55 |
| night | 20:00–5:00 | `#0F1534` `#222D63` `#36437F` | `#F3F0E2` moon, shade `#D9D3BD` | `#2C3A6B` `#22305B` | .18 + 14 stars |

Phase changes cross-fade over 1.2 s. The sky is re-checked every 5 min.

### Week bars on the sky
| Part | Value |
|------|-------|
| Panel glass | white 26% (12% at night), 1px white 34% edge, radius 20, shadow `0 10 24 -14` black 30% |
| Track | white 30%, radius 7, max 20 wide |
| Fill | `#FFFFFF` → `#E7F0FF`; today `#FFD86E` → `#FF7E57` with a `#FFB35C` glowing dot |
| Selected | day label on a white chip with ink text, 2px white ring on the track |

### Amounts
| Kind | Colour | Sign |
|------|--------|------|
| Expense | `ink` | `-₹` |
| Income | `success` | `+₹` |
| Transfer | `inkMuted` | none, with a ⇄ icon |

### Accounts
Stored account colours are unchanged (`accountAxis` `#FDD85C`, `accountSbi`
`#C2457F`, `accountScb` `#4CB58E`, `accountHand` `#F59E5B`,
`accountFoodCard` `#C9D86A`, `accountOutside` `#6BB8E0`, `accountPf`
`#476E61`) so saved data keeps its look.

### Category colour groups
Tint = the colour at 20% behind an `ink` icon.

| Group | Token |
|-------|-------|
| essentials | `accountScb` |
| food | `accountHand` |
| transport | `accountOutside` |
| home | `sun` |
| lifestyle | `accountSbi` |
| health | `teal` |
| family | `violet` |
| finance | `accountPf` |
| other | `iconInactive` |
| income | `lime` |

### Chart series order
`coral`, `teal`, `lime`, `sun`, then account colours.

## Typography
Three bundled families (SIL OFL 1.1; licences in
`assets/fonts/*/OFL.txt` and on the Licenses page). None has the ₹ glyph;
the phone's system font draws it.

| Family | Weights | Use |
|--------|---------|-----|
| **Unbounded** | 500, 600, 700 | Display numbers, titles, buttons |
| **DM Sans** | 400, 500, 600, 700 | Body text |
| **DM Mono** | 500 | Amounts in lists, chips and bars |

| Style | Font | Size / line | Use |
|-------|------|-------------|-----|
| `dateNumber` | Unbounded 700 | 44 / .86, -0.04em | Home date |
| `displayAmount` | Unbounded 600 | 34 / 1.05 | Big totals |
| `displayTitle` | Unbounded 600 | 26 / 1.1 | Page titles |
| `headline` | Unbounded 600 | 20 / 1.2 | Card totals |
| `title` | Unbounded 600 | 17 / 1.3 | Sheet titles (`.shead h3`) |
| `sectionTitle` | Unbounded 600 | 14 / 1.3 | List heads (`.lhead h2`), day numbers 15 |
| `pageEyebrow` | Unbounded 600 | 12, caps, .08em | Weekday on Home, eyebrows (`accentText` on light) |
| `button` | Unbounded 600 | 13–14, .02em | Coral buttons |
| `bodyStrong` | DM Sans 600 | 14 / 1.35 | Row titles |
| `body` | DM Sans 500 | 14 / 1.45 | Body |
| `caption` | DM Sans 500 | 12.5 / 1.35 | Meta lines |
| `overline` | DM Sans 700 | 10, caps, .06em | Chip and day labels |
| `amount` | DM Mono 500 | 15 / 1.15, tabular | Amounts, chip values |
| `amountSmall` | DM Mono 500 | 11.5, tabular | Bar values, list-head value |

## Glass
mini_checklist `.g` / `.chip`, implemented by `Glass`:

- `BackdropFilter` with blur 14 (σ 7) composed with saturate 1.4 (colour
  matrix), the `glass` tint and a **1px white inner border** (16%).
- All glass on the Home stage shares one backdrop through `BackdropGroup`
  + `BackdropFilter.grouped`, so the moving sky stays at 60 fps.
- `GlassIconButton`: 34 tall, radius 17, 16pt icon, white ink; selected
  = white 90% fill, ink content.
- `StatChip`: radius 12, padding 5×10, `amount` value over a 9.5pt caps
  label (white 82%).

## Spacing
4pt grid: `space1` 4 · `space2` 8 · `space3` 12 · `space4` 16 · `space5`
20 · `space6` 24 · `space8` 32 · `space10` 40.

| Rule | Value |
|------|-------|
| Panel side padding | 16 (mini `.pin`) |
| Stage side padding | 14 (mini `.hud`) |
| Between list rows | 8 |
| Row inner padding | 9, min height 60 |
| Minimum tap target | 44 |

## Radius
| Token | Value | Use |
|-------|-------|-----|
| `radiusHero` | 26 | Panel and sheet top corners |
| `radiusGlassPanel` | 20 | Week-bar glass |
| `radiusCard` | 18 | Cards, rows, tiles |
| `radiusField` | 12 | Inputs, day chips, small buttons, stat chips |
| `radiusPill` | 999 | Buttons, chips, bars |

## Elevation and shadows
Cards are flat with a 1px `line` border.

| Token | Value | Use |
|-------|-------|-----|
| `shadowPanel` | `0 -10 30 -12` black 25% | Sliding panel, sheets |
| `shadowFloat` | `0 8 22 -8` black 40% | Speech bubble, menus, toasts |
| `shadowCoral` | `0 8 18 -8` coral | Coral buttons, Quick Add |
| `shadowGlass` | `0 10 24 -14` black 30% | Week-bar glass |

## Component sizes
Unchanged from before except `pressScale` 0.92. Highlights: `buttonHeight`
52, `fieldHeight` 52, `iconCircle` 44, `chipHeight` 44, `quickAddSize` 56,
`numPadKeyHeight` 56, `navBarHeight` 72 (see `app_sizes.dart`).

## Component rules
| Component | Rule |
|-----------|------|
| Primary button | `coral` pill, white Unbounded label, `shadowCoral`; press springs to 0.92. Disabled: `line` fill, `inkMuted` label |
| Quick Add | 56pt `coral` circle, white +, `shadowCoral`, springy press |
| Bottom bar | `card` with a `line` top border; active icon `ink` on a `navIndicator` pill that springs in |
| Card / row | `card`, 1px `line`, radius 18; icon circle 44, title `bodyStrong`, meta `caption`, amount `amount` on the right |
| Day chip (`.dchip`) | weekday 9.5 caps `inkMuted`, number Unbounded 15, a 5pt dot (`sun` spending, `red` busy day). Today's number `coral`; selected = `ink` chip with `panel` text |
| List head (`.lhead`) | `sectionTitle` + 6pt progress (teal → lime; coral → red when over) + mono value |
| Speech bubble | white, ink 12pt DM Sans 600, radius 14/14/14/3, `shadowFloat`, fades 200 ms |
| Toast | `ink` fill, white text, radius 18 |
| Empty state | illustration, Unbounded 15 title, 13pt `inkMuted` text, centred |
| Text field | `card` fill, `radiusField`; focus: `teal` ring |

## Icons
Lucide outline (`lucide_icons_flutter`), 24 nav, 20 inline, 16 chips and
glass buttons. Never emoji as icons (emoji only inside the monkey's
speech and hearts).

## Charts (fl_chart)
Pill bars and rings in the chart series order; grid lines `line`; labels
`amountSmall`. Week bars on Home are custom (see Sky).

## Motion
| Token | Value | Use |
|-------|-------|-----|
| `springy` | `Cubic(0.2, 1.6, 0.4, 1)` | Taps, toggles, chips, glass buttons (scale .9) |
| `bouncy` | `Cubic(0.2, 1.3, 0.4, 1)` | Monkey reactions, bubble, entrances |
| `grow` | `Cubic(0.2, 1.2, 0.3, 1)` | Bars and progress growing |
| `sheet` | `Cubic(0.2, 1.1, 0.3, 1)` | Sheets sliding up (Quick Add) |
| `durationPress` | 200ms | Press feedback |
| `durationSheet` | 450ms | Sheet slide |
| `durationSky` | 1.2s | Sky phase cross-fade |
| `durationBars` | 900ms + 50ms stagger | Week bars |
| `sceneRestAfter` | 15s | Endless loops rest after the last touch |
| `durationFast` / `Medium` / `Slow` | 150 / 250 / 300ms | Fades, page and tab transitions, number roll |
| `durationStagger` | 40ms, max 8 | List entrance stagger |

### The scene (ported keyframes)
`Keyframes` ports CSS `@keyframes` (per-segment easing, implied 0%/100%).

| Loop / one-shot | Value |
|-----------------|-------|
| mwBreath | 3.4s, body scale 1.025 × 1.035 |
| mwTilt | 7s, head -5° at 78%, 3° at 88% |
| mwSwish | 2.8s, tail -14° (5s when asleep) |
| mwBlink | 5.2s, eyes .08 tall at 96% |
| mwFloat | 8s, halo up 6 |
| mwNod | 4s, asleep head 4° + 2 down |
| mwZ | 3s, three z's float up-right, 1s apart |
| mwDrift | clouds 70 / 95 / 120s, transform only |
| mwTwinkle | 3s, stars to 25% and .6 scale |
| mwTalk | mouth open/shut every 130 ms while speaking |
| mwPurr | .11s rumble while stroked |
| mwSpinStars | .8s, dizzy stars circle the head |
| mwJump | .8s bouncy: up 24% squash .95/1.07, land 1.08/.92 |
| mwHop | .6s bouncy: up 10% |
| mwShake | .5s: -7°, 6°, -4°, 2° |
| mwNodOnce | .6s: -3°, down 3% |
| mwDance | 1s × 2: ±9°, up 8% |
| mwSpin | .9s: flip (scaleX -1), up 6% |
| mwWave | 1.2s: right paw up 46, -24° / -6° twice |
| mwTwL / mwTwR | .5s ear twitch -22° / 8° |
| mwBurst | .8s, 9–16 stars fly 26–60pt, spin 160°, fade |
| mwHeart | 1.3s, heart pops then floats up 90 |
| mwBarIn | bars grow with 50ms stagger |

Rules:
- One ticker drives the monkey, one the sky; painters repaint through a
  `Listenable` (no widget rebuilds per frame), each in a `RepaintBoundary`.
- Loops rest 15s after the last touch or reaction; offstage tabs pause
  through `TickerMode`.
- **Reduce motion**: no loops, no reactions, no bursts, no bar growth;
  moods, faces and speech bubbles still change instantly.
- Animate only opacity and transform; no layout animation in lists.

## Mascot (Auditor Monkey)
Drawn with `CustomPainter` in Mimi's 160×176 view box and SVG style:
3pt `#2A2420` outline, radial fur gradient (`#C08A5E` → `#8A5634`), peach
face mask, round glasses, coral bow tie, a clipboard with green ticks,
curly tail. Sun or moon halo behind, soft ground shadow.

| Mood | Face | When (Home) |
|------|------|-------------|
| `idle` | open eyes, small smile | near the plan / no plan |
| `happy` | grin, rosy cheeks | under the plan |
| `worried` | raised brows, wobbly mouth, sweat drop, ears droop | over the plan |
| `celebrating` | happy eyes, grin, dances once with a burst | wizard done |
| `sleeping` | shut eyes, nodding, "zzz" | idle in the sleepy hours (23:00–5:00), unless touched in the last 25s |

| API (`MascotController`) | Does |
|--------------------------|------|
| `say(text, duration)` | Speech bubble + talking mouth |
| `react(kind, text:)` | `add` hop + happy, `del` shake, `win` dance + burst, `sad` nod + worried, `hello` wave, `spin`, `check` jump + burst |
| `look(direction)` | Pupils follow for 3.5s |
| `poke()` / `type()` | Wake the loops / ears perk |

Touch: head giggles, belly laughs, tail grumbles, ears twitch, stroking
purrs with hearts, double tap dances, six fast taps make it dizzy.
Haptics on each. Semantic label: "Auditor Monkey. Tap the head, belly,
ears or tail, or stroke it. Double-tap for a dance."

Home reactions: Quick Add save → `add` ("Logged ₹…"); crossing over the
plan → `sad` ("Uh-oh, over the plan"); back under → `hello`.

## Navigation
Bottom bar (5 slots, icons only): Home, Insights, **Quick Add** (centre),
Transactions, Accounts. Tapping the current tab goes to its first screen.

## Screen patterns
- **Home** (mini_checklist layout): the stage is `safe top + clamp(42% of
  height, 250, 360)` tall.
  - Top HUD: date (`dateNumber`, weekday caps, month) on the left; glass
    buttons on the right (Recent when a day is picked, Open accounts,
    Demo data in debug builds).
  - Scene: the monkey (max 172 tall) beside the week bars (max 236 × 150),
    centred together; the bubble paints over the bars.
  - Bottom HUD: chips **Today spent**, **Month left** (or **Budget left**
    when budgets exist; income minus spending otherwise), **Savings %**.
  - Panel: a `DraggableScrollableSheet` overlapping the stage by 22pt,
    radius 26, `shadowPanel`; drag it up to cover the scene, which fades
    (`1 - progress × 1.7`) and lifts 14pt. Inside: handle, 9-day strip,
    list head, the 20 latest entries (or the picked day's).
- **Quick Add**, **setup wizard**, **Accounts**, **statement**: `panel`
  background, white bordered cards, coral primary actions, Unbounded
  titles, DM Mono amounts, springy presses (all through the tokens).
- **Empty / error states**: recoloured illustrations, Unbounded title.

## Illustrations
Flat SVGs in `assets/illustrations/`, recoloured to this palette: ink
`#10202A`, coral `#FF6B4A`, teal `#0E9F9A`, warm yellow `#FFD86E`, sun
`#FFC24D`, line `#DFE7E5`. Decorative (excluded from semantics).

## Demo data
Debug and profile builds only. "Demo data" ribbon (`warning` fill, `ink`
text) pinned at the top while on.

## Accessibility
- Contrast (WCAG AA): `ink` on `panel` 15.6:1; `inkMuted` on `panel`
  4.95:1; `accentText` on `panel` 4.85:1; `success` on white 4.95:1;
  `ink` on `navIndicator` 13.7:1.
- Known exceptions copied from mini_checklist, kept for the look: white
  on `coral` is 2.8:1 (used only for bold 13–14pt button labels and
  icons); today's `coral` day number is 2.6:1 (today is also announced
  in semantics). White text on the sky always has a soft text shadow.
- Every bar and day chip has a full semantic label (weekday, today,
  exact amount). Chips read "label: value". The speech bubble is a live
  region.
- Large text: chips and buttons wrap; amounts scale down instead of
  clipping.

## Assumptions
| # | Unclear | Assumption |
|---|---------|------------|
| B1 | "41 keyframes" | mimi-world.css's scene keyframes are all ported (table above); web-only ones (Dynamic Island, water, 3D) are not used |
| B2 | Week bars data | Last 7 days ending today, expenses only (transfers never count) |
| B3 | "Month left" without budgets | Income minus spending this month; with budgets, budget total minus spending |
| B4 | Settings screen | The app has no settings screen yet; the demo-data sheet and menus use the theme |
| B5 | Font files | mini_checklist ships WOFF2; converted to TTF (same glyphs, Latin subset) for Flutter |
| B6 | 3D mascot | Dropped (with `flutter_3d_controller` and `monkey.glb`); the 2D painter replaces it everywhere |
