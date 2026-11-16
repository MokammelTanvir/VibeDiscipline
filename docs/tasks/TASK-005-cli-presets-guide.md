---
id: TASK-005
title: vibe CLI, stack permission presets, user guide
tier: M
methodology: hybrid
status: done
approved_by: Mokammel Tanvir
approved_at: 2026-11-15
depends_on: [TASK-003, TASK-004]
---

## Goal
Someone who is not the author can install VibeDiscipline into a project on
a stack other than Laravel with one command, keep it up to date, find out
why something is not working, and read how to use it.

## Approval note
The owner asked on 2026-11-15 for the important remaining pieces "so other
users can install this package and use it in their projects: details,
documentation, command line CLI". No separate design review; assumptions
are listed under Open Questions.

## Acceptance Criteria
- [x] `package.json` with a `vibe` bin (a new manifest, zero dependencies), so
      `npx github:MokammelTanvir/VibeDiscipline init` works without a clone
      or an npm publish
- [x] `vibe init | upgrade | check | compile | methodology | doctor | version | help`;
      an unknown command exits 2 with usage
- [x] `install.sh --stack auto|laravel|node|python|generic` picks the
      permission preset; `auto` detects from the target's manifests; an
      existing `permissions.yml` is never replaced
- [x] Each preset compiles and keeps the universal deny list
- [x] `install.sh --upgrade` refreshes skills, packs, adapters and scripts,
      keeps `config.yml`, `permissions.yml` and `state.md`, lists what changed
- [x] `vibe doctor` reports missing or stale pieces with the command that
      fixes each, and exits 1 when something is wrong
- [x] `docs/GUIDE.md`: install, first session, tiers, approvals, config and
      permissions reference, commands, upgrade, uninstall, troubleshooting
- [x] Tests for the CLI, presets and upgrade run in CI

## Non-goals
- Publishing to npm (the name is unchecked; needs the owner)
- Windows without WSL or Git Bash (the installer and checker are bash)
- Three-way merge on upgrade; presets for ruby, go, jvm, dotnet, rust
- Ecosystem packs or adapters for the new presets (knowledge, not permissions)

## Affected Areas
`package.json` (new), `bin/vibe.cjs` (new), `scripts/install.sh`,
`.agent/presets/*` (new), `docs/GUIDE.md` (new), `tests/*`,
`.github/workflows/quality-gates.yml`, `README.md`, `CHANGELOG.md`,
`docs/ROADMAP.md`, `docs/README.md`, `CLAUDE.md`, `.claude-plugin/plugin.json`

## Testing Requirements
`tests/cli.test.sh` (new) and added installer scenarios in throwaway
directories; the existing gates.

## Open Questions
1. **Assumed (flagged):** the CLI wraps the bash installer instead of porting
   it to Node, so it needs bash. Impact: no native Windows.
2. **Assumed (flagged):** the presets are command and path lists written
   from general knowledge of each ecosystem. They have not been dogfooded
   on a real Node or Python project.
