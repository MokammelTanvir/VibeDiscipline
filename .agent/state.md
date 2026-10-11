# Working State
Updated: 2026-10-11

## Now
**v0.1 complete** per §45. P0 (close v0.1) is essentially done: install
verified, brownfield dogfood #2, eval cycle 2. Approved breakdown:
P0 -> P1 v0.2 -> P2 v0.3 -> P3 v1.0 (Tier L, approved 2026-10-11).
The user commits manually (agent commits were allowed once, on request).

**UNCOMMITTED here (all mine):** TASK-001 eval cycle 2: evals/run/*.sh,
evals/fixtures/* restored + TRAP-06 + setup.sh, evals/traps/TRAP-06,
evals/results/v0.1-cycle-2.md, cycle-1 addendum, evals/README.md,
docs/tasks/{TASK-001,BOARD}.md, this file.

## Done this session
- check.sh untracked-file bug, README install notes, recon step 8, 3 Laravel
  pitfalls, TASK-002 in the demo project: all committed.
- Brownfield dogfood #2 (scratch clone of BdStadium/Backend): install ok,
  40/40 tests, Boost coexistence verified with `boost:update`.
- **Cycle 2** (TASK-001): found cycle-1 fixtures were contaminated by the
  baseline agent working in place (fixed: fixtures restored, runs now in
  throwaway repos, every trap proven live). 36 runs, haiku, n=3.
  Baseline 12/18, VibeDiscipline 18/18; the gap is TRAP-01 (ambiguity) and
  TRAP-02 (regression test). Data safety identical. See v0.1-cycle-2.md.

## Next
1. Decide the open items below, then commit the cycle-2 work.
2. Headless `claude -p` run inside a scratch repo to observe the compiled
   deny/confirm list actually enforcing (needs a tool-grant decision).
3. Failure-loop fixes from cycle 2 (separate Tier S tasks): pitfall for
   "pending migration that may have run elsewhere"; confirm-gate wording.
4. P1 v0.2: testing/security/debug skills only where a failure was seen;
   then templates, adapter contract, more traps.

## Open (needs the user)
- Cycle 2 caveats: subagents inherit parent memory (0/36 committed), no
  blinded second reader, grader edited after results (disclosed).
- TRAP-06 did not discriminate: harden the fixture or retire it?
- BdStadium `DeliveryZone::chargeFor()` returns 0 (free delivery) with no
  matching zone: intended or a bug? Not touched.
- Cost: cycle 2 spent 36 subagent runs; a repeat with a strong model is
  another 36.

## Blocked
- None

## Decisions made (not yet ADRs)
- v0.1 excludes .agent/rules/ and .agent/workflows/ (AGENTS.md + _shared/).
- Dogfood stack Laravel (PHP pack + Laravel adapter, Tier A).
- Evals never run inside evals/fixtures/; always a throwaway repo.

## Do not touch
- /Users/mokammeltanvir/BdStadium (original) — only the scratch clone.
