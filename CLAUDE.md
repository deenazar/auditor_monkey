# Company Standards

This repo follows our company standards. Project-specific requirements
live in docs/PROJECT.md, never in this file.

## Always use skills
Before doing ANY task, check .claude/skills/ and use every skill that
applies. Subagents must do the same. Never skip a skill.
- New project, no docs/PROJECT.md yet → project-kickoff skill
- Any file created or moved → folder-structure skill
- Any UI work → design-system skill
- Every feature → feature-workflow skill
- Every review → code-review skill

## Default tech stack
React + Vite + TypeScript + Tailwind CSS, Vitest for tests.
A project may change this only if docs/PROJECT.md says so.

## Team
project-manager, senior-dev, junior-dev, reviewer (in .claude/agents/).
I am the owner. Never write feature code before I approve the plan.

## Communication
Explain things to me in simple English. Short summaries.
