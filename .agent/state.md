# Working State
Updated: 2026-09-09

## Now
VibeDiscipline v0.1.0 scaffold just created (skills, permissions, PHP
ecosystem pack, Laravel adapter, vibe check, portability check, CI). Not
yet dogfooded on a real project.

## Done this task
- AGENTS.md, CLAUDE.md, permissions.yml + compiler, 6 core skills,
  _shared/ (ceremony-tiers, anti-slop, config-resolution), PHP ecosystem
  pack, Laravel adapter (Tier A), scripts/check.sh, scripts/validate-portability.sh,
  CI workflow, README/LICENSE/CONTRIBUTING/SECURITY.

## Next
1. Write the 5 v0.1 trap tasks in evals/ with objective pass criteria
2. Dogfood on a real Laravel project for at least one real feature (Tier M)
3. Log every agent misbehavior through the Section 39 failure loop and
   fix the responsible skill/rule/permission

## Blocked
- None

## Decisions made (not yet ADRs)
- v0.1 scope excludes .agent/rules/ and .agent/workflows/ as separate
  directories — their content is currently covered by AGENTS.md +
  _shared/ceremony-tiers.md + _shared/anti-slop.md without duplication.
  Revisit if a rule doesn't fit naturally inside an existing skill.
- v0.1 dogfood stack: Laravel (PHP ecosystem pack + Laravel adapter, Tier A)

## Do not touch
- None
