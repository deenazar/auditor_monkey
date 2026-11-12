---
name: feature-workflow
description: Use for every feature or change request.
---

# Feature Workflow

1. Read `docs/PROJECT.md` and `docs/DECISIONS.md`.
2. project-manager makes a plan: tasks, files, acceptance criteria,
   senior or junior for each task, and what runs in parallel.
3. Show the owner the plan. **WAIT for approval.**
4. senior-dev and junior-dev build; run independent tasks in parallel.
5. reviewer checks with the code-review skill; fix High/Medium issues.
6. `npm run build` and tests must pass.
7. Update `docs/PROJECT.md` (mark the feature done) and log key
   decisions in `docs/DECISIONS.md`.
8. Open a pull request and give the owner a short, simple summary.
