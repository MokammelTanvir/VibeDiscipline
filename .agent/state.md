# Working State
Updated: 2026-11-15

## Now
Methodology: hybrid
v0.1 complete; **TASK-002 methodology selection done, UNCOMMITTED** (all mine):
.agent/config.yml, _shared/{methodology (new),ceremony-tiers,config-resolution}.md,
planning + handoff SKILL.md, AGENTS.md, README.md, skills/README.md,
docs/README.md, docs/tasks/{TASK-002 (new),BOARD}.md, scripts/set-methodology.cjs
(new), scripts/check.sh, evals/traps/TRAP-07 (new, spec only), this file.
The user commits manually; always ask before commit or push.
Roadmap: P0 close v0.1 -> P1 v0.2 -> P2 v0.3 -> P3 v1.0 (Tier L, approved 2026-10-11).

## Done this session
- v1.0 readiness audit: ~30% overall, ~70% remains. Full table in the plan
  (VibeDiscipline-Full-Plan.md §45A, gitignored). Plan updated to v2.1 (§12A).
- Methodology verified in a scratch repo (selector: unset/block/no-block/
  bad value/no tty/pty menu; check.sh: 7 cases). Gates pass: portability,
  line limits, compile idempotent, vibe check clean.

## Next (critical path to a publishable v0.1.0, plan §45A "A")
Full A-to-Z list (22 steps, re-audited 2026-11-15): CLAUDE.md maintainer section.
1. Plan is gitignored but README links to it: publish it or strip the links.
2. Replace `<org>` with MokammelTanvir in README.md:30, skills/README.md:9.
3. Tag v0.1.0 + CHANGELOG. 4. Add a `scope` check; make check.sh honour check.*.
5. Headless `claude -p` run to see deny/confirm enforce, or say "not yet observed".
6. Run TRAP-07 (needs a fixture; ~3 runs x 3 methodologies).

## Open (needs the user)
- Methodology default: assumed hybrid when unset, no forced prompt (TASK-002 Q1).
- TRAP-06 did not discriminate: harden the fixture or retire it?
- Corrected confirm-gate wording (TRAP-06 VD, n=3) not re-tested.
- Eval caveats: n=3, haiku only, same author grades and judges.
- BdStadium `DeliveryZone::chargeFor()` returns 0 with no matching zone:
  intended or a bug? Not touched.

## Blocked
- None

## Decisions made (not yet ADRs)
- v0.1 excludes .agent/rules/ and .agent/workflows/.
- Dogfood stack Laravel (PHP pack + Laravel adapter, Tier A).
- Evals never run inside evals/fixtures/; always a throwaway repo.
- Methodology = sequencing + gate placement, never the tier (TASK-002).

## Do not touch
- /Users/mokammeltanvir/BdStadium (original) — only the scratch clone.
