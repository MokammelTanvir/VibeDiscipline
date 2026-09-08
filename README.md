# VibeDiscipline

> Make AI coding agents work like real software engineers.

VibeDiscipline is an open-source engineering discipline layer for AI
coding agents: ceremony tiers that scale process to the size of the
change, permissions compiled into real enforcement (not just prose an
agent can drift away from), framework detection that works on any stack
from day one, and an executable slop checker.

**Status: v0.1.0 — pre-release, being dogfooded on real Laravel projects.**
The full design rationale lives in
[`VibeDiscipline-Full-Plan.md`](./VibeDiscipline-Full-Plan.md).

## The three things that make this different

1. **Ceremony tiers.** A typo fix and a new auth subsystem never get the
   same process. See the table in [`AGENTS.md`](./AGENTS.md).
2. **Rules compiled into gates, not just read as prose.**
   `.agent/permissions.yml` is compiled into `.claude/settings.json`,
   git hooks, and CI — layers an agent cannot simply drift past.
3. **Detect the stack, never assume it.** No adapter is required for a
   project to work correctly — `recon` derives commands from lockfiles,
   manifests, and CI, and caches them in `.agent/stack.lock.yml`.

## Install into an existing project

```bash
# Skills only — pure behavior, zero configuration, delete anytime
npx degit <org>/vibediscipline/.agent/skills .agent/skills

# Skills + enforced permissions + AGENTS.md (recommended for most projects)
npx vibe init --tier governed     # ships in v0.3; for now, copy manually:
#   .agent/  AGENTS.md  CLAUDE.md  scripts/
#   then run: node scripts/compile-permissions.cjs
```

## What's in v0.1

```
AGENTS.md                    the constitution (≤100 lines)
.agent/skills/                recon · planning · implement · code-review · git · handoff
.agent/skills/_shared/        ceremony-tiers · anti-slop · config-resolution
.agent/permissions.yml        compiled into .claude/settings.json + git hooks + CI
.agent/ecosystems/php/        PHP/Composer-level knowledge
.agent/adapters/laravel/      Laravel conventions + AI-specific pitfalls (Tier A)
scripts/check.sh              vibe check — executable slop detection
scripts/compile-permissions.cjs
scripts/validate-portability.sh
evals/                        trap tasks proving the system changes agent behavior
```

Not yet built (see the roadmap in the full plan, Section 45): PRD/TRD/ADR
templates, the UI/UX skill, additional adapters, the `vibe` CLI, and the
template-repo bootstrap. v0.1 is deliberately narrow and deep — one real
stack working well beats twenty adapters that are never tested.

## Contributing

See [`CONTRIBUTING.md`](./CONTRIBUTING.md). The fastest way to help right
now is a new trap task in `evals/traps/` describing a real failure you've
seen an AI agent make.

## License

MIT — see [`LICENSE`](./LICENSE).
