# Company Standards

This repo follows our company standards. Project-specific requirements
live in docs/PROJECT.md, never in this file.

## Always use skills
Before doing ANY task, check .claude/skills/ and use every skill that
applies. Subagents must do the same. Never skip a skill.
- New project, no docs/PROJECT.md → project-kickoff
- Any file created or moved → folder-structure
- Every feature → feature-workflow
- Every review → code-review + design-taste
- Any UI work → design-system + frontend-design + shadcn
- Website or landing page scroll animation → gsap-framer-scroll-animation
  (only if docs/PROJECT.md says it is a website or landing page)
- Promo or demo video → remotion skills (remotion-best-practices,
  remotion-create, remotion-markup, remotion-render), only when I ask
  for a video

Priority rule: if skills disagree, design-system wins for colors,
fonts, spacing and brand. Other design skills are for quality and craft.
Use only the skills that apply. Do not load video or animation skills
for normal app screens.

## Default tech stack
React + Vite + TypeScript + Tailwind CSS, with shadcn/ui components on
top of Tailwind, themed with our design-system tokens. Vitest for tests.
A project may change this only if docs/PROJECT.md says so.

## Team
project-manager, senior-dev, junior-dev, reviewer (in .claude/agents/).
I am the owner. Never write feature code before I approve the plan.

## Communication
Explain things to me in simple English. Short summaries.
