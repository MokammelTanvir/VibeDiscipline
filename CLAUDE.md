See [AGENTS.md](./AGENTS.md) — the constitution for this repository.
Do not duplicate its content here; edit AGENTS.md instead.

<!-- MAINTAINER SECTION: status of the VibeDiscipline repo itself.
     Strip everything below this line when installing into another project. -->

# Project status and roadmap (audited 2026-11-15)

Live state: `.agent/state.md` · tasks: `docs/tasks/BOARD.md` · full design:
`VibeDiscipline-Full-Plan.md` (gitignored, §45 roadmap, §45A readiness).
Overall ≈ 32% of v1.0. Repo is PUBLIC; tagged v0.1.0 on 2026-11-15; no GitHub release yet.

## Done
- v0.1 core: AGENTS.md (72 lines), 6 skills (recon, planning, implement,
  code-review, git, handoff), 4 `_shared` docs, PHP pack, Laravel adapter.
- `permissions.yml` → `.claude/settings.json` + git hooks + CI (idempotent).
- `scripts/check.sh` (secrets, leftovers, dependency, tests, methodology).
- Evals: 6 traps, 2 cycles, 36 scored runs (baseline 12/18 vs VD 18/18, n=3, haiku).
- TASK-001, TASK-002 done and committed.
- Steps 1-7 of list A, done 2026-11-15: public `docs/ROADMAP.md` replaces the dead plan links;
  `<org>` filled in and the degit command verified; dead `.agent/rules/`
  line removed; check.sh has `scope`, `--task` and honours `check.*`;
  the compiler handles `mode`, `files.allow`, file-deny edits and
  `network` (advisory); `workflow.*` flags defined in config-resolution.md;
  headless enforcement run recorded in `evals/results/enforcement-2026-11-15.md`.
- CHANGELOG.md written; `v0.1.0` tagged and pushed.
- Step 8: TRAP-07 run headless, 18 runs (`evals/results/trap-07-2026-11-15.md`);
  `evals/run/headless.sh` is the first automated runner.
- Step 10 (TASK-003): `scripts/install.sh`.

## A — Publishable v0.1.0 (what is left)
8. Decide TRAP-06 (harden or retire). Decide for hybrid Tier L whether the
   document set is written or only proposed before approval (TRAP-07 finding).
9. GitHub pre-release for `v0.1.0`, repo topics (owner confirms each).
Note: `.agent/stack.lock.yml` is deliberately absent here; a template repo
must not ship its own detected stack. `recon` writes it per project.

## B — v0.2 Broaden (the bulk)
11. Claude Code native packaging: bridge `.agent/skills` → `.claude/skills`,
    plugin manifest, PreToolUse hook for confirm-tier commands (reasoning
    alone failed the confirm gate in 4 eval runs).
12. Skills, failure-driven order: testing, security, debug, then database,
    refactor, dependency, discovery, product, architecture, ui-ux (0/10).
13. Templates: PRD, TRD, ADR, API-SPEC, UI-UX (1/6; waterfall needs them).
14. JavaScript pack + Next.js adapter (second stack proves universality);
    then python, react, vue, nestjs, django.
15. Full vibe check: scope, size, duplication, error-handling, docs.
16. Evals: automated `claude -p` runner, 2+ models, n≥5, blinded grading,
    retained transcripts, traps 7 → 15. Fix the memory-leak isolation issue.
17. Adapter contract: `_TEMPLATE`, schema validation in CI. Tests for scripts/.
18. README: 60-second quickstart, before/after demo, eval table, FAQ.

## C — v0.3 Tooling, then v1.0
19. `vibe` CLI (init, doctor, compile, check, upgrade); check npm name first.
20. Bridges: Cursor, Copilot, Windsurf, Codex. Replace hand-rolled YAML parser.
21. Remaining packs (ruby, go, jvm, dotnet, rust); upgrade path with merge.
22. v1.0: spec freeze + compatibility promise, docs site, governance,
    10+ Tier-A adapters, issue/PR templates, CODE_OF_CONDUCT.

## Model assignment (step numbers refer to the lists above)

An agent cannot switch its own model. Before starting a step, compare the
model you are running on with this table. If it differs, say so in one line
and name the model to switch to (`/model fable|opus|sonnet|haiku`), then
wait for the owner; do not silently continue on the wrong model.

| Model | Steps | Kind of work |
|---|---|---|
| **Sonnet** | 1, 2, 3, 4, 6, 9, 10, 13, 18, 21 | Mechanical edits, links, CHANGELOG, templates, README, install script, pack boilerplate |
| **Fable** | 5, 7, 8, 11, 12, 15, 16 (design + grading), 17, 19 (design), 20, 22 | Skill wording, enforcement/hook design, check.sh rules, eval design, CLI architecture, spec freeze, audits |
| **Sonnet** after a Fable design | 14, 19 (implementation) | Adapters and CLI code built from an approved design |
| **Haiku + Sonnet** | 8, 16 (as eval subjects only) | Run the traps; never the model that wrote the skill under test |
| **Opus** | fallback | Use for Fable rows when Fable's usage limit is hit |

Switch up to Fable mid-task when: the change touches AGENTS.md, a SKILL.md,
`permissions.yml` semantics or a trap's pass criteria; a requirement is
ambiguous; the same fix has failed twice; or the tier escalates to M/L.
Switch down to Sonnet when: the plan is approved and what remains is
executing it, or the work is Tier XS/S docs and config.

Eval rules: subjects are Haiku and Sonnet (a strong model hides the gap);
the grader is a different model from the subject, reading blind; every
new or changed skill is re-run on Sonnet before it counts as done.

## Open decisions (owner)
- Methodology default when unset (assumed hybrid, no forced prompt).
- Stop-and-ask vs finish-the-task in non-interactive runs (TRAP-01/04 cost).
- Publish the full plan, or only a trimmed ROADMAP.md.
