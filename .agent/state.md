# Working State
Updated: 2026-11-15

## Now
Methodology: hybrid
v0.1.0 released 2026-11-15. Committed through 0c9a185 (2 commits not pushed).
UNCOMMITTED (all mine, this session, TASK-005): package.json, bin/vibe.cjs,
.agent/presets/, scripts/install.sh, docs/GUIDE.md, tests/{cli,install}.test.sh,
CI workflow, README.md, CHANGELOG.md, docs/{ROADMAP,README}.md, BOARD, TASK-005
doc, CLAUDE.md, this file.
Always ask before commit or push. No co-author trailer.

## Done this session
- `vibe` CLI; `npx --package=<tarball> vibe init` and `doctor` verified.
  `npx github:MokammelTanvir/VibeDiscipline init` is documented but only
  works once this is pushed: verify it after the push.
- Presets node/python/generic + detection; `--upgrade`; clean config template
  (installs were inheriting this repo's config, which could block a first commit).
- docs/GUIDE.md. All tests pass: guard 32, check 18, install 55, cli 23.
- Own guard hook blocked a heredoc containing a `*DROP ...*` pattern: expected
  behaviour, documented in the guide's troubleshooting.

## Next
Full list: CLAUDE.md maintainer section (model per step is there too).
1. Owner reviews, commits, pushes; then run the npx github: command for real.
2. Tag v0.2.0 once the owner agrees (bump .agent/VERSION, package.json, plugin.json).
3. npm publish (owner: check the name), demo GIF, dogfood the node and python
   presets on real projects, second-model evals.

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
