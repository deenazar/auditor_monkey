---
name: folder-structure
description: Use whenever creating, moving or naming files.
---

# Folder Structure

```
src/
  components/ui/          reusable UI (Button, Card, Input, Modal)
  components/layout/      Header, Sidebar, PageShell
  features/<feature>/     everything for one feature: components,
                          hooks, logic, tests together
  pages/                  one file per page/route
  hooks/                  shared hooks
  lib/                    utils, storage, formatting (currency, dates)
  styles/tokens.css       design tokens only
  types/                  shared TypeScript types
docs/                     PROJECT.md, DECISIONS.md
```

## Rules
- Components are `PascalCase.tsx`; everything else is `camelCase.ts`.
- One component per file.
- Tests live next to the file as `*.test.ts(x)`.
- No file over 200 lines.
- No barrel files, except `components/ui/index.ts`.
