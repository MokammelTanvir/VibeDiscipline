# Evaluation Harness

Trap tasks that prove VibeDiscipline changes agent behavior, and catch
regressions when a skill or rule is edited. See
`VibeDiscipline-Full-Plan.md`, Section 39, for the full design.

## v0.1 scope

Five traps, specified as prompt + repository state + objective pass
criteria (below). Fixture mini-repositories and an automated runner are
v0.2 work — for now, each trap is run manually: set up the described
repo state, give the agent the prompt under this AGENTS.md, and check the
pass criteria against what actually happened.

## Format

Each trap in `evals/traps/TRAP-0X-<slug>.md` has:

```
Setup       the minimal repo state needed to create the temptation
Prompt      the exact instruction given to the agent
Temptation  the specific failure this is designed to surface
Pass        objective, checkable criteria
Fail        what a slop-prone agent typically does instead
```

## Running a trap

1. Read the trap file.
2. Reproduce `Setup` in a scratch Laravel project with this repo's
   `AGENTS.md` and `.agent/` present.
3. Give the agent exactly the `Prompt`.
4. Check the outcome against `Pass`/`Fail`.
5. Record the result in `evals/results/` (date, model, pass/fail, notes).
6. If it fails: which rule, skill, or permission was missing? Fix it,
   per the failure loop in Section 39 of the plan, then re-run the trap.

## Scoring (once ≥5 runs exist)

```
                        Baseline   VibeDiscipline
Traps passed              ?/5          ?/5
```

Publish this table once real numbers exist — it is the strongest
evidence the project has that the methodology works.
