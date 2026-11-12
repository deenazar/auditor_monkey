---
name: design-system
description: Use for ANY UI, styling or layout work.
---

# Design System — "Warm Paper"

Our signature look is "Warm Paper": calm, warm, confident, not generic.

## Colors
Put these in `src/styles/tokens.css` as CSS variables.

| Token       | Light     | Notes            |
|-------------|-----------|------------------|
| paper       | `#FAF7F2` | background       |
| surface     | `#FFFFFF` |                  |
| ink         | `#1C1B22` | text             |
| muted       | `#6B6875` |                  |
| line        | `#E7E2D9` | borders          |
| accent      | `#E8772E` | saffron          |
| accent-dark | `#B85A1C` |                  |
| success     | `#2F8F6B` |                  |
| danger      | `#C8463D` |                  |
| warning     | `#D9A21B` |                  |

Dark mode: background `#16151B`, surface `#201F27`, text `#F2EFEA`,
same accent.

## Typography
- Headings: "Bricolage Grotesque" 600
- Body: "DM Sans" 400/500
- Numbers and amounts: "JetBrains Mono"
- Base 16px. Scale: 12 / 14 / 16 / 20 / 24 / 32 / 44.

## Shape
- Radius: 14px cards, 10px buttons/inputs, 999px pills.
- Borders: 1px, line color.
- Soft shadow only on raised elements:
  `0 1px 2px rgba(28,27,34,.06), 0 8px 24px rgba(28,27,34,.06)`

## Spacing
4px grid: 4, 8, 12, 16, 24, 32, 48.

## Signature details (always use)
- Page titles have a small saffron underline bar (24px × 4px).
- Key numbers are shown big in JetBrains Mono.
- Empty states have a friendly one-line message + one clear action.
- Only ONE saffron primary button per screen.

## Rules
- Never use default Tailwind blue/indigo.
- No gradients.
- No emoji as icons — use `lucide-react`.
- Mobile-first; every screen works at 360px width.
- WCAG AA contrast.
- Visible focus rings in saffron.
- shadcn components must be themed with Warm Paper tokens. Never ship
  default shadcn look.
