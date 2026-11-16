---
id: TASK-006
title: vibe new (scaffold through official tools) and a landing page
tier: M
methodology: hybrid
status: done
approved_by: Mokammel Tanvir
approved_at: 2026-11-16
depends_on: [TASK-005]
---

## Goal
Start a new project and get VibeDiscipline in it in one command, without
this package shipping or maintaining any framework boilerplate; and give
the project a page that explains it and how to install it.

## Approval note
The owner asked on 2026-11-16 for a boilerplate-style flow (pick a backend
and a frontend, or skip) and an HTML page with package details and an
install tutorial, after the design was stated: run each framework's own
scaffolder, then install on top.

## Acceptance Criteria
- [x] `vibe new [name]` with `--backend`, `--frontend`, `--methodology`,
      `--dry-run`; menus in a terminal, flags elsewhere
- [x] Recipes: laravel, laravel+react, laravel+vue, nextjs, django, nestjs,
      react, vue, angular; each runs the official scaffolder and then the
      installer with the matching preset
- [x] A pair with no official starter is refused with the reason; a missing
      tool, a bad name and a non-empty target are refused before anything runs
- [x] A scaffolder failure stops before VibeDiscipline is installed
- [x] All nine recipes run for real on one machine (2026-11-16, macOS):
      each exited 0 and `vibe doctor` reported 0 problems
- [x] `package.json` gains a second bin name, `vibediscipline`, and the
      homepage; still zero dependencies
- [x] `docs/index.html`: self-contained, light and dark, phone width
- [x] Dry-run and refusal cases in `tests/cli.test.sh`

## Non-goals
- Backend and frontend as two apps in one repository (needs prefixed
  permission paths; not built)
- Express and FastAPI (no official scaffolder to delegate to)
- Running the real scaffolders in CI (network, minutes per run)
- Enabling GitHub Pages (a repository setting; the owner's call)

## Affected Areas
`bin/vibe.cjs`, `package.json`, `tests/cli.test.sh`, `docs/index.html` (new),
`docs/.nojekyll` (new), `docs/GUIDE.md`, `docs/README.md`, `README.md`,
`CHANGELOG.md`, `docs/ROADMAP.md`, `CLAUDE.md`, `.claude-plugin/plugin.json`

## Open Questions
1. **Assumed (flagged):** scaffolder flags (`create-next-app --yes`,
   `@angular/cli new --defaults`, the Laravel starter-kit package names) are
   those that worked on 2026-11-16. Upstream can change them; the dry-run
   test pins what we send, not what upstream accepts.
