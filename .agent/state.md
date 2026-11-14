# Working State
Updated: 2026-11-15

## Now
Methodology: hybrid
v0.1.0 release prep. TASK-002 committed (3489369). UNCOMMITTED (all mine,
this session, list A steps 2-7): AGENTS.md, README.md, CHANGELOG.md (new),
CLAUDE.md, docs/{ROADMAP (new),README,PERMISSIONS}.md, .agent/{config,permissions}.yml,
.agent/skills/{README,_shared/config-resolution}.md, .claude/settings.json,
scripts/{check.sh,compile-permissions.cjs}, evals/README.md,
evals/results/enforcement-2026-11-15.md (new), this file.
The user commits manually; always ask before commit or push. No co-author trailer.

## Done this session
- check.sh: `scope` check (task doc Affected Areas), `--task`, and
  `check.fail_on/warn_on/ignore` honoured. 10 scratch-repo scenarios pass.
- Compiler: `mode` (auto/guided/strict), `files.allow`, Edit-deny for denied
  files, `network` documented as advisory, inline YAML lists, `--help`.
- Headless `claude -p` run: deny, confirm and file-deny all blocked. Finding:
  the allow-list is ignored until the workspace trust dialog is accepted.
- Dead plan links replaced by docs/ROADMAP.md; degit command verified.

## Next
Full list: CLAUDE.md maintainer section (model per step is there too).
1. Owner reviews and commits the uncommitted work above.
2. Push, tag v0.1.0, GitHub pre-release, topics (each needs confirmation).
3. TRAP-07 fixture + runs; TRAP-06 decision.
4. v0.2 starts with the install script and Claude Code native packaging.

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
- Permission mode lives only in permissions.yml; removed from config.yml.
- `require_git_diff_review` removed: a non-negotiable cannot be a flag.
- Public roadmap is docs/ROADMAP.md; the full plan stays gitignored.

## Do not touch
- /Users/mokammeltanvir/BdStadium (original) — only the scratch clone.
