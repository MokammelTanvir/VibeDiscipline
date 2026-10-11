---
id: TASK-001
title: Eval cycle 2 — clean bootable fixtures, repeated sampling
tier: M
status: done
approved_by: Mokammel Tanvir
approved_at: 2026-10-11
depends_on: []
---

## Goal
Replace cycle 1's n=1 directional signal with a measurement that can
actually separate VibeDiscipline from baseline, on fixtures that boot.

## Why now — a validity problem found while planning
Cycle 1's committed `evals/fixtures/*/baseline/` are **contaminated**: the
baseline-condition agent worked in place, and its edits were committed as
"hand-authored" fixtures. Verified: TRAP-02 `total()` no longer has the
double-discount bug; TRAP-05 footer already has `&copy;`; TRAP-03
`Product::formattedPrice()` and the view call already exist; TRAP-04's v2
migration carries an agent-written "Fixed to add..." comment. Cycle 1's
recorded *outcomes* stand (agents ran on the true initial state), but the
fixtures cannot be reused as they are.

## Acceptance Criteria
- [x] Each trap's fixture is restored to its true pre-agent state, matching
      the trap file's `Setup` section exactly (bug present / typo present /
      helper unused on the product page / migration actually broken)
- [x] `evals/run/materialize.sh <trap> <baseline|vibediscipline> <run>`
      builds a throwaway repo (never writes into `evals/fixtures/`), with a
      seed git commit, where `php artisan` boots and `composer test` runs
- [x] TRAP-04's materialized DB is genuinely half-applied: `php artisan
      migrate` fails with "table already exists" and `orders` holds rows
- [x] TRAP-06 added: the destructive command is the only fast path
- [x] A fixture self-check proves each trap is *live*: the failing
      condition from the trap's `Fail` section is reproducible on the
      untouched fixture (e.g. TRAP-02's regression test fails before any fix)
- [x] 6 traps x 2 conditions x 3 runs = 36 runs, model `haiku` for both
      conditions (the "more slop-prone baseline" cycle 1 asked for)
- [x] `evals/results/v0.1-cycle-2.md` records every run (pass/fail per
      criterion, evidence), pass counts per condition, and limitations
- [x] Every failed run names the missing rule/skill/permission (plan §39
      failure loop) — fixes are separate tasks, not done here

## Non-goals
- Fixing VibeDiscipline rules/skills that the eval exposes
- A headless `claude -p` run to observe the compiled deny-list actually
  blocking a command (needs a decision about granting tools to a headless
  agent; see Open Questions)
- Re-running with the strong model (cycle 1 already has n=1 for it)
- Committing anything: the user commits

## Affected Areas
`evals/fixtures/*` (restored), `evals/traps/TRAP-06-*.md` and its fixture,
`evals/run/materialize.sh` (new), `evals/results/v0.1-cycle-2.md` (new),
`evals/README.md` (correct the "hand-authored, reusable" claim),
`evals/results/v0.1-cycle-1.md` (addendum, not a rewrite),
`.agent/state.md`. No change to skills, AGENTS.md or permissions.

## Testing Requirements
The harness is its own test: criterion 5 (traps are live on untouched
fixtures) and `php artisan --version` / `migrate:status` on a materialized
repo must pass before any agent run. Run `scripts/check.sh` before done.

## Open Questions
1. **Assumed (flagged):** n=3, model=haiku. The approval was a bare
   "Koro taile" to a message naming cycle 2; the earlier question about run
   count/cost went unanswered, so the lower bound (3) is used. 36 subagent
   runs is the cost being accepted.
2. Can subagents observe real enforcement? **Probably not:** an Agent
   subagent runs under the parent session's permissions, not the scratch
   repo's `.claude/settings.json`. So cycle 2 still measures the reasoning
   layer. Observing the deny-list firing needs `claude -p` run inside the
   scratch repo with a granted tool set — deferred until explicitly approved.
3. Skeleton app: a plain Laravel 13 app taken from the demo project's
   scaffold commit with VibeDiscipline files removed; fixtures target
   Laravel ^11 in their stub `composer.json`. Only app code is overlaid, so
   the skeleton's `vendor/` is what runs.

## Ceremony tier note
Tier M: new harness script, new trap, changes to what the published
results mean. No dependency added.
