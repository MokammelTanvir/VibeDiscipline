# VibeDiscipline Skills — The Portable Layer

Everything under `.agent/skills/` is pure behavior. It has no required
dependency on anything else in this repository — see
`_shared/config-resolution.md` for the exact contract. You can copy this
directory alone into any existing project:

```bash
npx degit <org>/vibediscipline/.agent/skills .agent/skills
```

Nothing outside `.agent/skills/` will be created. No existing file is
modified. Uninstalling is deleting one directory.

## What's here (v0.1)

```
_shared/
  ceremony-tiers.md      how much process a change deserves — read this first
  anti-slop.md           the catalogue of AI-generated code/process smells
  config-resolution.md   the graceful-degradation contract every skill follows

recon/SKILL.md           understand an existing codebase before touching it
planning/SKILL.md        turn a requirement into a tiered plan + acceptance criteria
implement/SKILL.md       the coding discipline: inspect → plan → implement → verify
code-review/SKILL.md     self-review before anything is considered done
git/SKILL.md             professional git behavior: diff review, atomic commits
handoff/SKILL.md         write cross-session state before a session ends
```

More skills (discovery, product, architecture, ui-ux, testing, security,
database, debug, refactor, dependency) ship in v0.2 once this core set is
proven. See the full plan for the complete roadmap.

## How a skill decides how much to do

Every workflow skill starts by consulting `_shared/ceremony-tiers.md`.
A one-line typo fix and a new auth subsystem go through the *same* skill,
at different depths — never a different skill.

## Full system vs. skills only

This directory is one part of VibeDiscipline. The full template
(this repository) additionally provides `permissions.yml` compiled into
real enforcement, framework adapters, document templates, and a task
board. See the root `README.md` and `AGENTS.md` for the complete picture.
