# Working State
Updated: 2026-11-15

## Now
Methodology: hybrid
v0.3.0 (2026-11-16): committed, pushed, tagged, GitHub Pages enabled on the
owner's instruction. npm still has 0.2.1 until the owner publishes.
Always ask before any later commit, push or publish. No co-author trailer.

## Done this session
- `vibe new`: 9 recipes through official scaffolders, each run for real
  (exit 0, doctor 0 problems). Next.js and NestJS now ship their own
  AGENTS.md; the installer merged above it with markers.
- Landing page docs/index.html (not yet viewed in a browser by anyone).
- Second bin name `vibediscipline`.

## Next
1. Owner: `npm publish --access public` for 0.3.0; look at the landing page.
2. Owner: upgrade the demo project; one interactive session.
Ideas not built: two-app repositories, `vibe status`, second-turn evals.

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
