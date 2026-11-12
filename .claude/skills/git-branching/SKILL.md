---
name: git-branching
description: Use at the start of every session (before the first change of the day) and whenever creating a branch, committing, or opening a pull request.
---

# Git Branching

## Branch hierarchy

```
main          production. Protected. Only release/* and hotfix/* merge here.
 └─ develop   integration. All daily work merges here by PR.
     ├─ feature/*   new features
     ├─ fix/*       bug fixes
     ├─ refactor/*  code cleanup, no behaviour change
     ├─ docs/*      docs only
     └─ chore/*     config, deps, tooling
release/*     cut from develop → merge to main AND back to develop
hotfix/*      cut from main → merge to main AND back to develop
```

- Never commit directly to `main` or `develop`.
- No `develop` yet → create it from `main` and push it.

## Branch name rules

Format: `<type>/<YYYYMMDD>-<short-slug>`

- type: `feature`, `fix`, `refactor`, `docs`, `chore`, `hotfix`
- date: today's date (owner's timezone)
- slug: lowercase, kebab-case, 2–5 words, no spaces, no special chars
- Max 50 characters total
- Releases: `release/vX.Y.Z` (no date)

Good: `feature/20261112-google-sign-in`, `fix/20261112-login-crash`
Bad: `Feature/GoogleSignIn`, `my-branch`, `fix_bug`, `claude/xyz`

## Daily rule: branch before the first query

Before doing ANY work on the first request of the day (or of a new
session), run:

```bash
git fetch origin
git checkout develop && git pull origin develop   # create from main if missing
git checkout -b <type>/<YYYYMMDD>-<short-slug>
```

- Pick the type and slug from the owner's first request.
- Tell the owner the branch name in one line.
- Same day, same task → keep using today's branch.
- Same day, new unrelated task → new branch from `develop`.
- Never reuse an old day's branch for new work; branch again from
  `develop`.

## Commits

- Small commits. Message: `<type>: <what changed>` (e.g.
  `feature: add Google sign-in button`).
- Never commit secrets, `.env`, keys or service-account files.

## Pull requests

- feature/fix/refactor/docs/chore → PR into `develop`.
- release/* and hotfix/* → PR into `main`, then merge back to `develop`.
- PR title = branch type + short summary. Body: what, why, how tested.
