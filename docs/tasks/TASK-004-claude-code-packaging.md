---
id: TASK-004
title: Claude Code native packaging (guard hook, skills bridge, plugin)
tier: M
methodology: hybrid
status: done
approved_by: Mokammel Tanvir
approved_at: 2026-11-15
depends_on: [TASK-003]
---

## Goal
Close a measured hole in the compiled permissions and make the skills
discoverable by Claude Code itself, not only through `AGENTS.md`.

## Approval note
Step 11 of the maintainer roadmap in `CLAUDE.md`. The owner instructed
"v0.2 er baki kaj koro" (do the remaining v0.2 work) on 2026-11-15.

## The failure this traces to
Probes on 2026-11-15, Bash broadly allowed, compiled rules in place:
`git clean -fd` was denied and `cd app && git clean -fd` was denied, but
`bash -c "git clean -fd"` ran and deleted untracked files, including
`.claude/settings.json` itself. `sh -c "git merge ..."` passed the confirm
rule the same way. Host rules match the start of each sub-command; a
shell wrapper hides the real command.

## Acceptance Criteria
- [x] The compiler writes `.claude/hooks/vibe-guard.cjs` and registers it as
      a `PreToolUse` hook for Bash, keeping any hooks already in settings
- [x] The guard denies a deny-pattern and asks on a confirm-pattern when the
      command is wrapped (`bash -c`, `sh -c`, `eval`, `env`, `sudo`,
      `xargs`, `$(...)`) or chained; it stays silent otherwise
- [x] A quoted mention is not a hit: `git commit -m "undo git reset --hard"`
      passes
- [x] Unit cases for the guard run in CI; compile stays idempotent
- [x] The wrapped probes are re-run headless and the outcome recorded,
      whichever way it goes
- [x] `scripts/bridge-claude.cjs` generates `.claude/skills/vibe-<name>/SKILL.md`
      stubs that point at `.agent/skills/<name>/SKILL.md`; it touches no
      other skill directory; idempotent
- [x] `.claude-plugin/plugin.json` and `marketplace.json` pass
      `claude plugin validate`
- [x] The installer copies and runs the bridge; README documents all three

## Non-goals
- Catching a command written to a script file and then executed
- Bridges for Cursor, Copilot, Windsurf, Codex (v0.3)
- Shipping the guard inside the plugin (it needs the project's own policy)
- Submitting the plugin to a public directory

## Affected Areas
`scripts/compile-permissions.cjs`, `scripts/bridge-claude.cjs` (new),
`scripts/install.sh`, `tests/*` (new), `.claude/*` (generated),
`.claude-plugin/*` (new), `.github/workflows/quality-gates.yml`,
`README.md`, `CHANGELOG.md`, `docs/ROADMAP.md`, `docs/PERMISSIONS.md`,
`evals/results/enforcement-2026-11-15.md`, `CLAUDE.md`

## Testing Requirements
`tests/guard.test.cjs` (unit), scratch-repo headless probes, installer
scenarios, `claude plugin validate`, the existing gates.

## Open Questions
1. **Assumed (flagged):** the guard fails open. If its input cannot be
   parsed it stays silent and the host rules still apply; a crashing guard
   must not block every command.
2. **Assumed (flagged):** bridge skill names carry a `vibe-` prefix, since
   `code-review` and others collide with built-in or existing skills.
