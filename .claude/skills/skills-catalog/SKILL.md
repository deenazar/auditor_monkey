---
name: skills-catalog
description: List of approved external skills to install per project stack. Use during project-kickoff or when a project needs a new stack-specific skill. Nothing here is installed in the company template.
---

# Skills Catalog

This is a list only. Nothing is installed in the company template.

## How to install
```bash
npx skills add <source> -a claude-code -y
```
- Each skill must be a real folder in `.claude/skills/<name>/`
  (no symlinks), so cloud sessions can read it.
- Read each new SKILL.md and report anything risky to the owner
  (scripts it runs, commands it auto-approves, network downloads,
  licenses).
- List every installed skill in `docs/PROJECT.md` under "Project skills".

## Catalog

| When | Skills | Source |
|------|--------|--------|
| Any web UI | frontend-design | `https://github.com/anthropics/skills --skill frontend-design` |
| | shadcn | `https://github.com/shadcn-ui/ui --skill shadcn` |
| | design-taste | `h3nryprod01/design-taste` |
| Website / landing page | the web UI skills above + gsap-framer-scroll-animation | `https://github.com/github/awesome-copilot --skill gsap-framer-scroll-animation` |
| Flutter | Flutter skill | `https://github.com/saaip7/ipdev-mobileapps-skill` |
| | design-taste | `h3nryprod01/design-taste` |
| React Native | React Native skills | `https://github.com/maikotrindade/awesome-react-native-skills` |
| Promo / demo video | remotion (keep only best-practices, create, markup, render; delete the rest) | `remotion-dev/skills` |
