# Changelog

Notable changes to VibeDiscipline. Versions follow `.agent/VERSION`.

## Unreleased

### Added
- Guard hook (`scripts/vibe-guard.cjs`, installed as a Claude Code
  `PreToolUse` hook by the compiler). Denied and confirm-tier commands
  hidden inside `bash -c`, `eval`, `env`, `sudo`, `xargs` or `$(...)` are
  now caught; plain permission rules let them through.
- `scripts/bridge-claude.cjs`: `.claude/skills/vibe-<name>` stubs so Claude
  Code discovers the skills natively.
- Claude Code plugin and marketplace manifest for a skills-only install.
- PRD, TRD and ADR templates in `.agent/skills/planning/templates/`.
- `tests/`: guard unit cases, vibe check and installer scenarios, run in CI.

### Changed
- The compiler keeps hooks already present in `.claude/settings.json`.
- The installer copies the guard and bridge scripts and runs the bridge.

## 0.1.0 — 2026-11-15

First pre-release: one stack (PHP and Laravel), narrow and deep.

### Added
- `AGENTS.md` constitution with the ceremony tiers XS, S, M and L.
- Skills: recon, planning, implement, code-review, git, handoff. Shared
  docs: ceremony-tiers, methodology, anti-slop, config-resolution.
- `.agent/permissions.yml`, compiled by `scripts/compile-permissions.cjs`
  into `.claude/settings.json`, git hooks and `docs/PERMISSIONS.md`.
  The permission mode (`auto`, `guided`, `strict`) and the file allow and
  deny lists are compiled; the network section is documented as advisory.
- `scripts/check.sh` (vibe check): scope against the task doc's Affected
  Areas, secrets, debug leftovers, dependency changes, missing tests and
  the waterfall phase gate. Severity and ignored paths come from `check.*`
  in `.agent/config.yml`.
- Methodology selection (`agile`, `waterfall`, `hybrid`) with
  `scripts/set-methodology.cjs`.
- PHP ecosystem pack and a Tier-A Laravel adapter.
- Eval harness: seven traps run, a headless runner
  (`evals/run/headless.sh`), and a headless run showing the compiled deny
  and confirm rules enforcing (`evals/results/`).
- `scripts/install.sh`: installs into an existing project without
  overwriting its `AGENTS.md`, `CLAUDE.md`, settings or git hooks path.
- `docs/ROADMAP.md` with status and known limitations.

### Known limitations
See `docs/ROADMAP.md`. In short: eval samples are small and graded by the
author, only Claude Code is a compile target, and only Laravel has been
dogfooded.
