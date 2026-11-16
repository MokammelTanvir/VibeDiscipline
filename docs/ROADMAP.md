# Roadmap and status

Where VibeDiscipline stands and what comes next. Percentages are
effort-weighted estimates, not time tracking. Overall: about 45% of v1.0.

## v0.1 — Prove the concept (narrow and deep)

Shipped:

- `AGENTS.md` (100 lines or fewer) with the ceremony tier table
- 6 skills: recon, planning, implement, code-review, git, handoff
- `_shared/`: ceremony-tiers, methodology, anti-slop, config-resolution
- `permissions.yml` compiled to `.claude/settings.json`, git hooks, CI
- Universal stack detection, cached in `.agent/stack.lock.yml`
- PHP ecosystem pack and a Tier-A Laravel adapter
- `scripts/check.sh` (vibe check): scope, secrets, leftovers, dependency,
  tests, methodology
- 7 trap tasks run (see `evals/results/`), and a headless runner
  (`evals/run/headless.sh`)
- Methodology selection: agile, waterfall or hybrid
- `scripts/install.sh` for existing projects

Not in v0.1: PRD/TRD/ADR templates, the UI/UX skill, more adapters, the
`vibe` CLI, the template-repo bootstrap.

## v0.2 — Broaden

Done so far: a guard hook for commands hidden in shell wrappers, a Claude
Code skills bridge, a plugin manifest, tests for the scripts, PRD, TRD
and ADR templates, permission presets for Node and Python, and a user guide.

Remaining:

- Skills, **only where a trap shows a failure**. Three evals found no
  code-level failure for a skill to fix on a current model, so the earlier
  list of ten is no longer a commitment. Candidates stay: testing, debug,
  security, database, ui-ux
- Document templates: API-SPEC, UI-UX
- Ecosystem packs: javascript, python. Tier-A adapters: nextjs, react,
  vue, nestjs, django
- Full vibe check: size, duplication, error handling, docs
- Evals: automated runner, two or more models, larger samples, blinded
  grading, 15 traps
- Adapter contract: template, schema validation in CI

## v0.3 — Tooling

- The `vibe` CLI: a first version ships now (init, upgrade, doctor, check,
  compile, methodology) and runs through `npx github:...`. Still to do: an
  npm release, a Node port of the installer for native Windows
- Bridges for Cursor, Copilot, Windsurf and Codex
- Remaining ecosystem packs: ruby, go, jvm, dotnet, rust
- Three-way merge on upgrade (today an upgrade replaces edited skills)

## v1.0 — Standard

- Stable core specification (layout, skill contract, adapter contract,
  permission schema) with a compatibility promise
- All 8 ecosystem packs, 10 or more Tier-A adapters
- Documentation site and a governance model

## Known limitations

Read these before relying on the project.

- **Eval evidence is thin, and model-dependent.** Three runs per cell, two
  models, and the author both wrote the harness and graded the runs. The
  behavioural gap shows on Haiku and closes on Sonnet; what holds on any
  model is host enforcement and the recorded process.
- **Stopping to ask has a cost.** In a non-interactive run, an agent that
  correctly stops for approval delivers nothing.
- **The confirm gate is not reliable as prose.** In eval runs agents
  executed confirm-tier commands before asking. Host enforcement
  (`.claude/settings.json` plus the guard hook) is the layer that holds.
  A command written to a script file and then run is still not caught.
- **Only Claude Code is a compile target.** Other tools get the git hooks
  and CI layers only.
- **One stack is proven.** Laravel is the only adapter that has been
  dogfooded.
