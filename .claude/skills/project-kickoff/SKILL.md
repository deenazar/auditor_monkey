---
name: project-kickoff
description: Use at the start of every new project, when docs/PROJECT.md does not exist.
---

# Project Kickoff

## Steps
1. Ask the owner these questions in ONE message:
   - App name
   - What problem it solves
   - Who uses it
   - Main features (must-have vs later)
   - Web or mobile
   - Data storage needs
   - Any design changes from the company default
2. From the answers, write `docs/PROJECT.md` with these sections:
   - Overview
   - Users
   - Features (numbered, must-have first)
   - Out of scope
   - Tech stack
3. Use the project-manager agent to split the features into a
   one-feature-per-session order. Add that order to `docs/PROJECT.md`
   as a "Roadmap" section.
4. Create `docs/DECISIONS.md` (an empty log for important decisions).
5. Open a pull request.
