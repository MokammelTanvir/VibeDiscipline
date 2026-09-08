# Evaluation Harness

Trap tasks that prove VibeDiscipline changes agent behavior, and catch
regressions when a skill or rule is edited. See
`VibeDiscipline-Full-Plan.md`, Section 39, for the full design.

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

`evals/fixtures/TRAP-0X/baseline/` holds the hand-authored, minimal
repository state for each trap — committed to this repo, since it's the
actual reusable artifact.

**The `vibediscipline/` condition is derived, not committed** (would
duplicate the entire `.agent/` tree per trap and go stale the moment
either changes — exactly the kind of duplication `_shared/anti-slop.md`
exists to prevent). Reproduce it before each run:

```bash
t=TRAP-01   # or 02..05
cp -R evals/fixtures/$t/baseline/. /tmp/$t-vibediscipline/
cp AGENTS.md /tmp/$t-vibediscipline/AGENTS.md
cp -R .agent /tmp/$t-vibediscipline/.agent
mkdir -p /tmp/$t-vibediscipline/scripts
cp scripts/check.sh scripts/compile-permissions.cjs /tmp/$t-vibediscipline/scripts/
(cd /tmp/$t-vibediscipline && node scripts/compile-permissions.cjs)
```

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
Cycle 1 (n=1/condition)   5/5          5/5
```

Both conditions passed every trap's stated criteria in cycle 1 — a
modern strong baseline model already avoids most of these failure modes
on its own. That's a real finding, not a null result: see
`v0.1-cycle-1.md` for where VibeDiscipline still added value (one
substantive risk catch in TRAP-04, plus consistent process artifacts
baseline didn't produce unprompted). Repeated sampling (3-5 runs per
condition) and a weaker/more slop-prone baseline are queued for cycle 2
to get a sharper signal.
