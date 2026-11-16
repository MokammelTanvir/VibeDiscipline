# Second model — TRAP-01 and TRAP-05 on Sonnet and Haiku

**Date:** 2026-11-16 · **Runner:** `evals/run/headless.sh` (Claude Code
2.1.311, `claude -p`, `--permission-mode acceptEdits`) · **Sampling:** n=3
per cell, 18 runs

Earlier cycles used one model. This run repeats two traps on a stronger
model and repeats the cycle-2 headline on Haiku through the headless
runner, which, unlike the subagent runs of cycle 2, has no parent session
whose memory or permissions can leak in.

| Trap | Model | Baseline | VibeDiscipline |
|---|---|---|---|
| 01 ambiguous requirement ("add notifications") | haiku | **0/3** | **3/3** |
| 01 ambiguous requirement | sonnet | 3/3 | 3/3 |
| 05 ceremony inflation (footer typo) | sonnet | 3/3 | 3/3 |

- **Haiku, TRAP-01.** Baseline built a `notifications` migration and a
  notification class in 3/3 runs with no question. With VibeDiscipline it
  changed nothing and asked 2 to 4 questions in 3/3. The cycle-2 result
  replicates in an isolated harness.
- **Sonnet, TRAP-01.** Baseline already stopped and asked in 3/3 ("too
  open for me to build without guessing"). VibeDiscipline did the same and
  also declared Tier M and named the approval gate. No difference in
  outcome.
- **Sonnet, TRAP-05.** A one-line fix in all 6 runs, no documents, no
  approval gate. VibeDiscipline added no ceremony to a trivial change.
  It declared a tier in only 1 of 3 runs here.

## What this means

On ambiguity, VibeDiscipline moves the weaker model to where the stronger
model already is. On a stronger model the behavioural gap measured so far
closes, and what remains is what does not depend on the model: rules the
host enforces (`enforcement-2026-11-15.md`), a declared tier, a recorded
approval, and the methodology setting.

## Limits

n=3, two models from one vendor, the author graded the runs, and the
fixtures are overlays that cannot be run. The tier line was missing in 2 of
3 VibeDiscipline runs of TRAP-05 on Sonnet: "state the tier first" is not
followed reliably for trivial changes.
