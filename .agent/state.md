# Working State
Updated: 2026-09-09

## Now
**v0.1 is complete** per the §45 checklist, with the 2nd-dogfood-project
item explicitly deferred (not skipped) rather than done — see below.

## Done this task
- Dogfood cycle #1 (fresh Laravel project, TASK-001) — prior session
- 4 findings fixed upstream (ESM .cjs, ceremony-tier auth ambiguity,
  planning template caveat, Laravel adapter pitfalls) — prior session
- Branch-protection hook made configurable (git.protect_main_branch) —
  prior session
- **Trap eval cycle 1**: 5 traps × 2 conditions (baseline vs
  vibediscipline) run as isolated subagents against matched fixtures.
  10/10 passed stated criteria. Full results: evals/results/v0.1-cycle-1.md
  - Headline: a strong baseline model already avoids most classic slop
    failures on its own — an honest finding, reported as such
  - TRAP-04 surfaced one substantive difference: VibeDiscipline correctly
    escalated to Tier M and stopped to ask whether a migration had run
    elsewhere before editing it; baseline proceeded on an unstated,
    unverified assumption
  - Fixtures committed under evals/fixtures/*/baseline/ (hand-authored,
    reusable); the vibediscipline/ condition is derived per
    evals/README.md, never committed (would duplicate .agent/ per trap)

## Next (v0.2 candidates, not v0.1 blockers)
1. 2nd dogfood project on an EXISTING (non-greenfield) codebase — explicitly
   deferred by the user's call, not done. Needed before claiming the
   "adapt, don't override" path is proven, not before claiming v0.1 done.
2. Eval cycle 2: repeated sampling (3-5 runs/condition), bootable fixtures
   (real vendor/, runnable artisan) so the deny-list can be observed
   actually blocking a live attempt, and a deliberately more slop-prone
   baseline for a sharper signal
3. PRD/TRD/ADR templates, UI/UX skill, more adapters, vibe CLI (all
   already-planned v0.2/v0.3 scope, unchanged)

## Blocked
- None

## Decisions made (not yet ADRs)
- v0.1 scope excludes .agent/rules/ and .agent/workflows/ as separate
  directories — covered by AGENTS.md + _shared/ without duplication
- v0.1 dogfood stack: Laravel (PHP ecosystem pack + Laravel adapter, Tier A)
- v0.1 "done" bar interpreted as: scaffold + 1 real dogfood project +
  trap evals run for real — 2nd dogfood project explicitly moved to v0.2
  by user decision, documented rather than silently dropped

## Do not touch
- None
