# Changelog

One entry per pull request, grouped as Added / Changed / Fixed / Security.

## 2026-11-12: New design from reference screenshot

### Added
- `docs/design/reference.png`: the owner's design reference.

### Changed
- `DESIGN.md` at the repo root: all design tokens (colours as hex,
  typography, spacing, radius, shadows, icons, charts, motion,
  navigation) and the design assumptions with their approval status.
- Design section of `docs/PROJECT.md` replaced with a short summary
  and a link to `DESIGN.md`; the dark navy theme is gone.
- Roadmap session 1 now sets up the new theme.
- `docs/DECISIONS.md`: logged the design change.

## 2026-11-12: Project kickoff

### Added
- `docs/PROJECT.md`: overview, users, Phase 1 and 2 features, out of
  scope, tech stack, data model, design, folder structure, project
  skills, performance targets and the 11-session roadmap.
- `docs/DECISIONS.md` with the first decisions (Flutter, Riverpod,
  Drift, offline-first, Supabase, paise, login built late, pinned
  Flutter SDK).
- `docs/FEATURES.md` with all features marked Planned.
- Project skills `flutter-mobile-design` and `design-taste` in
  `.claude/skills/`, tracked in `skills-lock.json`.
- SessionStart hook (`.claude/hooks/session-start.sh`, registered in
  `.claude/settings.json`) that installs Flutter 3.47.9 in Claude Code
  cloud sessions and runs `flutter pub get` once `pubspec.yaml` exists.
