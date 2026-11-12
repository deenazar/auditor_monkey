---
name: performance
description: Use for every feature, especially screens, lists, data loading, images and background work.
---

# Performance

- Targets (unless `docs/PROJECT.md` overrides): app start < 2s, smooth
  60fps, screen load < 300ms, lists virtualized/paginated.
- Avoid unnecessary re-renders/rebuilds; cache wisely; lazy-load.
- Heavy work off the main thread. Optimize images and assets.
- Measure before and after for anything performance-sensitive.
