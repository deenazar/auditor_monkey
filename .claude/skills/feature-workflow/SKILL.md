---
name: feature-workflow
description: Use for every feature or change request.
---

# Feature Workflow

0. Branch first (git-branching skill): first request of the day /
   session → new branch from `develop`.
1. Read `CLAUDE.md`, `docs/PROJECT.md`, `docs/DECISIONS.md` and
   `docs/FEATURES.md`.
2. project-manager plans: tasks, files, acceptance criteria, owner
   (senior-dev or junior-dev), skills each task uses, and what runs in
   parallel.
3. Show the owner the plan. **WAIT for approval.**
4. senior-dev and junior-dev build; run tasks in parallel where they
   are independent.
5. qa-reviewer tests and reviews; devs fix High and Medium issues.
6. Build, lint and all tests pass.
7. project-manager updates `docs/FEATURES.md`, `CHANGELOG.md` and
   `docs/DECISIONS.md`.
8. Open a pull request into `develop` with a short summary.
