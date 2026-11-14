# Changelog

Notable changes to VibeDiscipline. Versions follow `.agent/VERSION`.

## 0.1.0 — unreleased

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
- Eval harness: seven trap specs, six of them run over two cycles, and a
  headless run showing the compiled deny and confirm rules enforcing
  (`evals/results/`).
- `docs/ROADMAP.md` with status and known limitations.

### Known limitations
See `docs/ROADMAP.md`. In short: eval samples are small and graded by the
author, only Claude Code is a compile target, and only Laravel has been
dogfooded.
