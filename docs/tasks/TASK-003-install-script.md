---
id: TASK-003
title: Install script (stopgap for `vibe init`)
tier: M
methodology: hybrid
status: done
approved_by: Mokammel Tanvir
approved_at: 2026-11-15
depends_on: []
---

## Goal
Install VibeDiscipline into an existing project with one command instead of
the manual copy the README describes, without destroying anything the
project already has.

## Approval note
Step 10 of the maintainer roadmap in `CLAUDE.md`, which the owner reviewed
on 2026-11-15 and then instructed "baki kaj koro" (do the remaining work).
No separate design review was held; the assumptions are listed below.

## Acceptance Criteria
- [x] `scripts/install.sh <target>` copies `.agent/` (never `state.md` or
      `stack.lock.yml`), `AGENTS.md`, a two-line `CLAUDE.md` pointer and the
      three scripts, writes `.agent/VERSION`, then compiles permissions
- [x] An existing `AGENTS.md` is kept: VibeDiscipline's text goes above it
      between markers, and a second run does not add it twice
- [x] An existing `CLAUDE.md` is kept; only a pointer line is added, once
- [x] Existing files under `.agent/` and `scripts/` are skipped and listed,
      unless `--force`
- [x] The installed `config.yml` carries no `stack:` block from this repo
- [x] An existing `.claude/settings.json` with a `permissions` key is not
      overwritten: compile is skipped and the user is told
- [x] The compiler leaves an already-set `core.hooksPath` alone
- [x] `--skills-only` copies `.agent/skills/` and nothing else
- [x] `--dry-run` changes nothing; `--methodology <m>` sets it
- [x] Verified in scratch directories: empty project, project with its own
      AGENTS.md/CLAUDE.md/settings.json/hooksPath, re-run, skills-only, dry-run

## Non-goals
- The `vibe` CLI, an npm package, upgrade with three-way merge (v0.3)
- Detecting the stack or adapting `permissions.yml` to it
- Copying `.github/workflows/`
- Windows support (bash only)

## Affected Areas
`scripts/install.sh` (new), `scripts/compile-permissions.cjs`, `README.md`,
`CHANGELOG.md`, `docs/ROADMAP.md`, `CLAUDE.md`

## Testing Requirements
Scratch-directory runs for each acceptance criterion; `scripts/check.sh`,
`scripts/validate-portability.sh`, compile idempotency in this repo.

## Open Questions
1. **Assumed (flagged):** the installer needs a local clone of this repo
   (`git clone` then run). A `curl | sh` installer is not offered, since the
   shipped permission policy itself denies that pattern.
2. **Assumed (flagged):** the shipped `permissions.yml` is copied as-is,
   with its Laravel command lists; the installer tells the user to edit it.
