# Working State
Updated: 2026-11-15

## Now
Methodology: hybrid
v0.1.0 tagged 2026-11-15 (owner asked for commit, push and tag). Working
tree clean at handoff. No GitHub release or repo topics yet.
Always ask before commit or push. No co-author trailer.

## Done this session
- check.sh scope + config; compiler mode/files/network; headless enforcement
  run; public ROADMAP; CHANGELOG (all committed).
- TRAP-07: 18 headless haiku runs. Wishlist prompt read as Tier M 9/9 (no
  discrimination); marketplace prompt Tier L 9/9, methodologies differ as
  designed, 0 code, 0 self-approval.
- TASK-003: scripts/install.sh, 27 scratch checks pass. Compiler now leaves
  an existing core.hooksPath alone.

## Next
Full list: CLAUDE.md maintainer section (model per step is there too).
1. GitHub pre-release for v0.1.0 and repo topics (needs confirmation).
2. v0.2: Claude Code native packaging (step 11), then skills (step 12).

## Open (needs the user)
- Methodology default: assumed hybrid when unset, no forced prompt (TASK-002 Q1).
- TRAP-06 did not discriminate: harden the fixture or retire it?
- Hybrid Tier L: document set written or only proposed before approval?
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

## Do not touch
- /Users/mokammeltanvir/BdStadium (original) — only the scratch clone.
