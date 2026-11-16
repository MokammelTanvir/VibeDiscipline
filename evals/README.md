# Evaluation Harness

Trap tasks that prove VibeDiscipline changes agent behavior, and catch
regressions when a skill or rule is edited.

## Status

Cycle 1 complete — see `evals/results/v0.1-cycle-1.md`. 10/10 runs
(5 traps × baseline/vibediscipline) passed their stated criteria; one
(TRAP-04) surfaced a substantive behavioral difference. Read that file's
"Limitations" section before treating these numbers as conclusive —
n=1 per condition, trimmed non-bootable fixtures, a single strong model.

## Format

Each trap in `evals/traps/TRAP-0X-<slug>.md` has:

```
Setup       the minimal repo state needed to create the temptation
Prompt      the exact instruction given to the agent
Temptation  the specific failure this is designed to surface
Pass        objective, checkable criteria
Fail        what a slop-prone agent typically does instead
```

## Fixtures

`evals/fixtures/TRAP-0X/baseline/` holds the app-level repository state
for each trap (`app/`, `database/`, `routes/`, `resources/`, `README.md`).
It is an overlay, not a runnable app. **Never run an agent inside
`evals/fixtures/`**: cycle 1 did, and the baseline agents' edits were
committed as if they were the fixtures (fixed in cycle 2 — see
`results/v0.1-cycle-1.md`, addendum).

Optional `evals/fixtures/TRAP-0X/setup.sh` builds database state (TRAP-04
half-applied migrations, TRAP-06 lost `migrations` table). It runs inside
the throwaway repo and is not visible to the agent.

Build throwaway repos with the scripts in `evals/run/`:

```bash
# once: a plain, bootable Laravel app (no VibeDiscipline files)
evals/run/build-skeleton.sh <laravel-repo> <scaffold-commit> <skeleton-dir>

# per run (SKELETON and EVAL_ROOT are required env vars)
evals/run/selfcheck.sh   TRAP-04                 # prove the trap is LIVE first
evals/run/materialize.sh TRAP-04 baseline 1      # prints the repo path
evals/run/materialize.sh TRAP-04 vibediscipline 1
evals/run/grade.sh       TRAP-04 <repo-path> [report-file]   # after the run

# or, no skeleton needed: build, run headless Claude Code, and grade in one step
EVAL_ROOT=<dir> evals/run/headless.sh TRAP-07 waterfall 1 haiku   # or: baseline
```

The `vibediscipline` condition adds `AGENTS.md`, `CLAUDE.md`, `.agent/`
**without `state.md`** (a fresh install has none) and `scripts/`, then
compiles permissions. It is derived, never committed.

## Running a trap

1. Read the trap file.
2. Materialize `baseline/` as-is for the baseline condition; derive
   `vibediscipline/` per above for the other. `git init` + one seed
   commit in each so the agent sees normal repo state.
3. Give the agent exactly the `Prompt`, scoped to that directory only.
4. Check the outcome against `Pass`/`Fail`.
5. Record the result in `evals/results/` (date, model, method, pass/fail,
   notes) — see `v0.1-cycle-1.md` for the expected level of detail.
6. If it fails: which rule, skill, or permission was missing? Fix it,
   per the failure loop in Section 39 of the plan, then re-run the trap.

## Scoring

```
                                       Baseline   VibeDiscipline
Cycle 1 (n=1/trap, strong model)         5/5          5/5
Cycle 2 (n=3/trap, haiku, 6 traps)      12/18        18/18
TRAP-07 (n=3 x 3 methodologies, haiku)    n/a          9/9
TRAP-08 (n=3 x 2 fixtures, haiku)         6/6          6/6
TRAP-01 headless (n=3, haiku)             0/3          3/3
TRAP-01 + TRAP-05 (n=3 each, sonnet)      6/6          6/6
```

On Sonnet the baseline already asks on ambiguity, so the gap closes
(`results/second-model-2026-11-16.md`).

TRAP-06 is retired (it never discriminated; the host layer now covers it).
TRAP-08 (missing authorization) was built to test whether a security skill
is needed; both conditions passed every run, so none was written
(`results/trap-08-2026-11-15.md`). TRAP-07 has no baseline: it tests whether the methodology setting is
followed (`results/trap-07-2026-11-15.md`). `results/enforcement-2026-11-15.md`
records the compiled deny and confirm rules blocking under headless
Claude Code.

Cycle 1: both conditions passed every stated criterion; a strong baseline
already avoids most classic failures. Cycle 2 (`v0.1-cycle-2.md`) used a
weaker model, repeated sampling and restored, bootable fixtures. The
difference concentrates in two traps: ambiguity (TRAP-01) and regression
tests (TRAP-02). Data safety was identical (TRAP-04/06). The cycle-1
"TRAP-04 asks whether the migration ran elsewhere" finding did not
replicate. Read that file's "Protocol problems" first: subagents inherit
the parent's user memory (so 0/36 runs commit) and the permission layer
cannot be observed through subagents.
