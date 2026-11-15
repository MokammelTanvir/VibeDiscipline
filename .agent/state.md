# Working State
Updated: 2026-11-15

## Now
Methodology: hybrid
v0.1.0 released 2026-11-15. v0.2 under way; pushed through 4971397, CI green.
UNCOMMITTED (all mine, this session): TRAP-08 (fixture, spec, results),
evals/run/{headless.sh,grade.sh}, evals/README.md, README.md, CHANGELOG.md,
CLAUDE.md, this file.
Always ask before commit or push. No co-author trailer.

## Done this session
- TASK-004 committed and pushed: guard hook, skills bridge, plugin, tests in CI.
- PRD/TRD/ADR templates; check.sh debug patterns per language.
- TRAP-08 (IDOR): 12 headless haiku runs, both conditions 6/6 even after
  hardening the fixture. No security skill written.
- headless.sh: baseline condition; VD condition built by the real installer.
- README quickstart + evidence table.

## Next
Full list: CLAUDE.md maintainer section (model per step is there too).
1. Owner reviews and commits the uncommitted work above; push.
2. Owner decides whether to cut the 10-skill list (see Open).
3. Candidates with evidence behind them: second-turn eval (behaviour after
   approval), a second model, JavaScript pack, full vibe check.

## Open (needs the user)
- Methodology default: assumed hybrid when unset, no forced prompt (TASK-002 Q1).
- TRAP-06 did not discriminate: harden the fixture or retire it?
- Hybrid Tier L: document set written or only proposed before approval?
- Cut the planned 10 skills? Three evals show no code-level failure to fix.
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
- Permission mode lives only in permissions.yml; removed from config.yml.
- `require_git_diff_review` removed: a non-negotiable cannot be a flag.
- Public roadmap is docs/ROADMAP.md; the full plan stays gitignored.
- Guard fails open; bridge stubs are prefixed `vibe-`; templates live under
  planning/ until a product skill exists.

## Do not touch
- /Users/mokammeltanvir/BdStadium (original) — only the scratch clone.
