# Working State
Updated: 2026-11-15

## Now
Methodology: hybrid
v0.2.1 (2026-11-16): committed, pushed, tagged and published to npm on the
owner's instruction in this session. Still ask before any later commit, push
or publish. No co-author trailer.

## Done this session
- Checked ~/vibediscipline-demo-laravel (read only): a 0.1 install that `init`
  was run over; scripts were old and the guard hook missing. Fix: `vibe upgrade`.
- Fixed: `init` refuses on an existing install; `upgrade` handles a pre-marker
  AGENTS.md; `doctor` compares files, not the version file.
- CLI: colours, arrow-key menus, grouped doctor, `vibe uninstall`.
- npm: `vibediscipline` published; docs use `npx vibediscipline`.

## Next (owner)
1. `npx vibediscipline upgrade` in the demo project, then an interactive session.
2. Try node/python presets on real projects; record a demo GIF.
Ideas not built: `vibe status`, second-turn evals, JavaScript pack.

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
