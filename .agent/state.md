# Working State
Updated: 2026-11-15

## Now
Methodology: hybrid
v0.1.0 tagged, pushed and released (GitHub pre-release) 2026-11-15. v0.2 under way.
UNCOMMITTED (all mine, this session): TASK-004 (scripts/{vibe-guard,bridge-claude,
compile-permissions}.cjs, scripts/install.sh, .claude/{settings.json,hooks,skills},
.claude-plugin/, tests/, CI workflow), planning/templates/{PRD,TRD,ADR}.md and the
skill/doc lines that reference them, README, CHANGELOG, ROADMAP, CLAUDE.md,
docs/PERMISSIONS.md, evals/results/enforcement addendum, BOARD, this file.
Always ask before commit or push. No co-author trailer.

## Done this session
- Found: `bash -c "git clean -fd"` and `sh -c "git merge"` pass the compiled
  rules (host matches the start of each sub-command). Guard hook closes it;
  re-probed headless, both blocked. 32 unit cases.
- Skills bridge (6 stubs), plugin + marketplace manifest (validate passes;
  `--plugin-dir` shows vibediscipline:* skills).
- tests/: guard 32, check 16, install 31 scenarios; added to CI.
- PRD/TRD/ADR templates.

## Next
Full list: CLAUDE.md maintainer section (model per step is there too).
1. Owner reviews and commits the uncommitted work above; push.
2. Skills, one at a time, each with a trap: testing, security, debug.
3. JavaScript pack + Next.js adapter; full vibe check; eval runner on 2 models.

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
- Guard fails open; bridge stubs are prefixed `vibe-`; templates live under
  planning/ until a product skill exists.

## Do not touch
- /Users/mokammeltanvir/BdStadium (original) — only the scratch clone.
