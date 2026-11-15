# VibeDiscipline

> Make AI coding agents work like real software engineers.

VibeDiscipline is an open-source engineering discipline layer for AI
coding agents: ceremony tiers that scale process to the size of the
change, permissions compiled into real enforcement (not just prose an
agent can drift away from), framework detection that works on any stack
from day one, and an executable slop checker.

**Status: v0.1.0 pre-release. One stack (Laravel) and one host (Claude
Code) are covered in depth; the skills themselves are stack-neutral.**
Roadmap, current status and known limitations:
[`docs/ROADMAP.md`](./docs/ROADMAP.md).

## Quickstart (about a minute)

```bash
git clone https://github.com/MokammelTanvir/VibeDiscipline.git
VibeDiscipline/scripts/install.sh /path/to/your/project
```

Open the project in Claude Code, accept the trust dialog, and ask for a
change. The agent now states a tier before it starts
(`Tier: S — bug fix in cart total, single file.`), stops for your approval
on anything feature-sized, and cannot run what `.agent/permissions.yml`
denies. Try it:

- "Fix the typo in the footer" → edits, verifies, done. No plan, no doc.
- "Add notifications" → no code; it asks what kind, for whom, and how.
- `bash -c "git reset --hard"` → refused by the guard hook.

To remove it: delete `.agent/`, `.claude/hooks/vibe-*`, `.claude/skills/vibe-*`,
`.githooks/` (then `git config --unset core.hooksPath`), the generated
`permissions` block and the `vibe-guard` hook entry in `.claude/settings.json`,
and the VibeDiscipline block at the top of `AGENTS.md`. Remove the hook entry
together with the hook file, or every shell command will report a missing hook.

## What the evidence says so far

| Measured | Without | With | Source |
|---|---|---|---|
| Six traps, stated pass criteria (haiku, n=3) | 12/18 | 18/18 | [cycle 2](./evals/results/v0.1-cycle-2.md) |
| Asked instead of building on an ambiguous request | 0/3 | 3/3 | cycle 2, TRAP-01 |
| Regression test added with a bug fix | 0/3 | 3/3 | cycle 2, TRAP-02 |
| Denied command hidden in `bash -c` blocked | no | yes | [enforcement](./evals/results/enforcement-2026-11-15.md) |
| Work sequenced per the chosen methodology at Tier L | n/a | 9/9 | [TRAP-07](./evals/results/trap-07-2026-11-15.md) |
| Authorization check on a new endpoint | 6/6 | 6/6 | [TRAP-08](./evals/results/trap-08-2026-11-15.md) |

Read it as indicative, not proven: small samples, one model, graded by the
author. The gains are in process and enforcement. On classic code-level
mistakes a current model does about as well on its own, and the cost of
the process is real: an agent that stops to ask delivers nothing in an
unattended run.

## The three things that make this different

1. **Ceremony tiers.** A typo fix and a new auth subsystem never get the
   same process. See the table in [`AGENTS.md`](./AGENTS.md).
2. **Rules compiled into gates, not just read as prose.**
   `.agent/permissions.yml` is compiled into `.claude/settings.json`,
   git hooks, and CI — layers an agent cannot simply drift past.
   Seen blocking a denied command, a confirm-tier command and a denied
   file in a headless Claude Code run, including commands hidden inside
   `bash -c "..."`, which plain permission rules let through:
   [`evals/results/enforcement-2026-11-15.md`](./evals/results/enforcement-2026-11-15.md).
3. **Detect the stack, never assume it.** No adapter is required for a
   project to work correctly — `recon` derives commands from lockfiles,
   manifests, and CI, and caches them in `.agent/stack.lock.yml`.

## Install options

```bash
# Skills only — pure behavior, zero configuration, delete anytime
npx degit MokammelTanvir/VibeDiscipline/.agent/skills .agent/skills

# Skills only, as a Claude Code plugin (inside Claude Code)
/plugin install vibediscipline --marketplace MokammelTanvir/VibeDiscipline

# Skills + enforced permissions + AGENTS.md (recommended for most projects)
git clone https://github.com/MokammelTanvir/VibeDiscipline.git
VibeDiscipline/scripts/install.sh /path/to/your/project
#   --methodology agile|waterfall|hybrid   --skills-only   --dry-run   --force
```

The installer never copies this repo's own `state.md` or stack settings,
keeps every file you already have, and compiles the permissions. Then open
the project in Claude Code once and accept the trust dialog: until a
workspace is trusted, Claude Code ignores the compiled allow-list. A `vibe`
CLI replaces this script in v0.3.

### Already have an AGENTS.md or CLAUDE.md?

They are kept. The installer puts VibeDiscipline's `AGENTS.md` content
**above** yours in the same file, adds one pointer line to `CLAUDE.md`, and
leaves an existing `.claude/settings.json` permissions block and
`core.hooksPath` alone. If you copy by hand: merge, never overwrite.

Laravel Boost projects: Boost generates those files and re-renders the region
between its `<laravel-boost-guidelines>` tags (composer's `post-update-cmd`
runs `boost:update`). Content placed outside that region survives
`php artisan boost:update` — verified on a Laravel 13 + Boost project: a line
tampered inside the region was restored, VibeDiscipline's text above it was kept.

## Choose a methodology

Agents follow the methodology you select, on top of the ceremony tiers:
`agile` (small increments, approval per increment), `waterfall` (phases in
order, approval per phase) or `hybrid` (the default: iterative below Tier L,
document-first at Tier L). Methodology sets the order of work and where
approval gates sit; it never changes the tier or relaxes permissions.

```bash
node scripts/set-methodology.cjs              # menu
node scripts/set-methodology.cjs waterfall    # or pass the value
node scripts/set-methodology.cjs --show
```

It writes `workflow.methodology` in `.agent/config.yml`. Details:
`.agent/skills/_shared/methodology.md`.

## What's in v0.1

```
AGENTS.md                    the constitution (≤100 lines)
.agent/skills/                recon · planning · implement · code-review · git · handoff
.agent/skills/_shared/        ceremony-tiers · methodology · anti-slop · config-resolution
.agent/permissions.yml        compiled into .claude/settings.json + git hooks + CI
.agent/ecosystems/php/        PHP/Composer-level knowledge
.agent/adapters/laravel/      Laravel conventions + AI-specific pitfalls (Tier A)
scripts/check.sh              vibe check — scope, secrets, leftovers, dependency, tests
scripts/install.sh            install into an existing project
scripts/set-methodology.cjs   select agile | waterfall | hybrid
scripts/compile-permissions.cjs  permissions.yml -> settings, guard hook, git hooks, docs
scripts/vibe-guard.cjs        PreToolUse hook: catches denied commands inside wrappers
scripts/bridge-claude.cjs     makes the skills discoverable as /vibe-* in Claude Code
.claude-plugin/               plugin + marketplace manifest (skills-only install)
tests/                        guard, vibe check and installer scenarios (run in CI)
scripts/validate-portability.sh
evals/                        trap tasks proving the system changes agent behavior
```

Not yet built (see [`docs/ROADMAP.md`](./docs/ROADMAP.md)): the UI/UX skill, additional adapters, the `vibe` CLI, and the
template-repo bootstrap. v0.1 is deliberately narrow and deep — one real
stack working well beats twenty adapters that are never tested.

## Contributing

See [`CONTRIBUTING.md`](./CONTRIBUTING.md). The fastest way to help right
now is a new trap task in `evals/traps/` describing a real failure you've
seen an AI agent make.

## License

MIT — see [`LICENSE`](./LICENSE).
