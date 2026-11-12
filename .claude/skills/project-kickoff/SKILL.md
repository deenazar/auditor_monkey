---
name: project-kickoff
description: Use at the start of every new project, when docs/PROJECT.md does not exist.
---

# Project Kickoff

1. If the owner gave a spec, use it as their answers. Otherwise ask in
   ONE message:
   - App name
   - Problem it solves
   - Users
   - Must-have features and later features
   - Platform and tech stack
   - Data storage
   - Cloud services and their account details (cloud-accounts skill)
   - Design (colors, fonts, theme, motion feel)
2. Write `docs/PROJECT.md` with these sections:
   - Overview
   - Users
   - Features
   - Out of scope
   - Tech stack
   - Design
   - Folder structure
   - Cloud accounts (IDs only, no secrets)
   - Project skills
   - Performance targets
   - Roadmap (one feature per session, in build order)
3. Pick project skills from the skills-catalog skill for this stack,
   install them into `.claude/skills/`, and list them in
   `docs/PROJECT.md` under "Project skills".
4. If the stack needs tools in cloud sessions (e.g. Flutter SDK), add a
   SessionStart hook in `.claude/settings.json` that installs them only
   when `CLAUDE_CODE_REMOTE` is `"true"`. Tell the owner if the network
   blocks it.
5. Set up cloud projects and keys with the cloud-accounts skill.
   Add `.env.example` and make sure `.env` is gitignored.
6. Create `docs/DECISIONS.md`, `docs/FEATURES.md` and `CHANGELOG.md`
   (format: see the feature-docs skill).
7. Open a pull request into `develop` (git-branching skill).
