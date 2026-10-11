# Working State
Updated: 2026-10-11

## Now
**v0.1 complete** per §45. P0 (close v0.1) in progress; breakdown
P0 -> P1 v0.2 -> P2 v0.3 -> P3 v1.0 approved 2026-10-11 (Tier L, each task
its own Tier M cycle). The user commits manually; `git commit` is blocked
for the agent by the auto-mode classifier — do not retry or work around.

**UNCOMMITTED here (all mine, this session):**
- README.md: install notes (skip state.md/config.yml; merge existing
  AGENTS.md/CLAUDE.md; Laravel Boost coexistence)
- scripts/check.sh: worktree mode now sees untracked files
- .agent/skills/recon/SKILL.md: step 8 "existing agent instructions"
- .agent/state.md (this file)

## Done this session
- Tier 2 install verified from a clean copy (compile exits 0, emits
  settings.json, hooks, PERMISSIONS.md); portability check passes.
- check.sh bug fixed + verified: old script said "no changes" on an
  untracked file containing dd() and a key literal; new one FAILs on both.
- TASK-002 password reset done in vibediscipline-demo-laravel (uncommitted).
- **Brownfield dogfood #2** on a scratch clone of BdStadium/Backend
  (Laravel 13, Filament, Sanctum, Boost; original untouched): baseline
  40/40; after install still 40/40, Pint + vibe check clean. Findings:
  1. README's literal "copy AGENTS.md CLAUDE.md" silently overwrote the
     Boost-generated files (fixed in README + recon step 8).
  2. Boost coexistence verified with `php artisan boost:update`: content
     outside `<laravel-boost-guidelines>` survives, tampering inside is
     restored.
  3. Default branch `master`, sentence-case commits (no Conventional
     Commits) — the git skill must adapt, not impose.
  4. Money-path gap reported, NOT fixed (no requirement): see Open below.
- Cycle 1 evals (earlier): 10/10 pass, TRAP-04 the one real difference.

## Next
1. Tier S: sync the fixed check.sh into the demo project's own scripts/.
2. Eval cycle 2: 3-5 runs/condition, bootable fixtures, slop-prone baseline
   (Tier M — needs a plan + approval first).
3. P1 v0.2: testing/security/debug skills first, only where a failure was
   observed; then templates, adapter contract, more traps.
4. (done, uncommitted) 3 Laravel pitfalls added to
   adapters/laravel/pitfalls.md (queued ResetPassword, neutral reset
   reply, redirect-status test). Also uncommitted in this repo.

## Open (needs the user)
- BdStadium `DeliveryZone::chargeFor()` returns 0 (free delivery) when no
  zone matches — intended or a bug? Not touched.
- Which project for further brownfield runs; 1 clone is n=1.

## Blocked
- None

## Decisions made (not yet ADRs)
- v0.1 excludes .agent/rules/ and .agent/workflows/ (AGENTS.md + _shared/).
- Dogfood stack Laravel (PHP pack + Laravel adapter, Tier A).

## Do not touch
- /Users/mokammeltanvir/BdStadium (original) — only the scratch clone.
