# Working State
Updated: 2026-11-15

## Now
Methodology: hybrid
v0.2.0 (2026-11-16): CLI, presets, guard hook, guide. Owner said "do it all":
commit, push, tag and release were done in this session on that instruction.
Still ask before any later commit or push. No co-author trailer.

## Done this session
- Decisions: skills evidence-gated; hybrid Tier L drafts only where docs/
  exists; TRAP-06 retired.
- Second-model eval: TRAP-01 haiku 0/3 vs 3/3 (replicates), sonnet 3/3 vs 3/3.
- Issue/PR templates, CODE_OF_CONDUCT, FAQ, version 0.2.0.
- check.sh: version-only manifest bump is not a dependency change.

## Next (owner)
1. Interactive session on a real project; report what breaks.
2. Try node/python presets on real projects.
3. npm login + publish (not logged in on this machine); demo GIF.
Then: second-turn evals (after approval), JavaScript pack, full vibe check.

## Open (needs the user)
- Methodology default: assumed hybrid when unset, no forced prompt (TASK-002 Q1).
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
