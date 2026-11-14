---
id: TASK-002
title: Methodology selection (agile | waterfall | hybrid)
tier: M
status: approved
approved_by: Mokammel Tanvir
approved_at: 2026-10-26
depends_on: []
---

## Goal
Let the project owner select a software-development methodology once, and
have the agent follow it: how work is sequenced and where the human approval
gates sit. Methodology is orthogonal to ceremony tier: tier decides *how
much* process, methodology decides *in what order and where the gates are*.

## Approval note (read this)
The approval is the user's instruction "methodology option select korbe
tarpore oi standard onujayi project er moddhe ai code korbe oivabe koro" on
the design stated in the previous message: three options mapped onto the
tiers and approval gates, config key, hybrid = today's behaviour. The
question "default hybrid, or force a choice at init?" went unanswered;
assumption below.

## Acceptance Criteria
- [x] `.agent/config.yml` accepts `workflow.methodology: agile | waterfall | hybrid`;
      this repo's own value is `hybrid` (dogfood = today's behaviour)
- [x] `.agent/skills/_shared/methodology.md` defines, per methodology, the
      Tier M and Tier L process, change handling, and "done"; states the
      invariants (never changes the tier, never relaxes permissions.yml, never
      creates ceremony below the tier, approvals stay recorded artifacts)
- [x] `planning`, `handoff`, `ceremony-tiers`, `config-resolution` consume it;
      with no config the result is `hybrid` and nothing breaks (portability
      contract: `scripts/validate-portability.sh` passes)
- [x] `scripts/set-methodology.cjs` selects the value (menu or argument) and
      edits only that key; works with no `workflow:` block and no config file
- [x] `scripts/check.sh` warns (never fails) in waterfall mode when source
      changed and the PRD/TRD has no `approved_at`, and warns on an unknown
      value; prints nothing new for agile/hybrid/unset
- [x] AGENTS.md stays <= 100 lines and names the option; README, skills
      README and docs README mention it
- [x] Each script change verified in a scratch repo (not this one)
- [x] A trap spec exists for the behaviour (spec only: no fixture, not run)

## Non-goals
- A `vibe init` prompt: the CLI is v0.3. `set-methodology.cjs` is the stopgap
- PRD/TRD/ADR templates (v0.2); waterfall uses the shortest doc that names its
  consumer until they ship
- Making check.sh read `check.fail_on` (separate gap, logged in the plan)
- Running the new trap against agents (cost; needs a fixture)
- Bumping `.agent/VERSION`, committing, tagging

## Affected Areas
`.agent/config.yml`, `.agent/skills/_shared/{methodology,ceremony-tiers,config-resolution}.md`,
`.agent/skills/{planning,handoff}/SKILL.md`, `AGENTS.md`, `README.md`,
`.agent/skills/README.md`, `docs/README.md`, `scripts/set-methodology.cjs` (new),
`scripts/check.sh`, `evals/traps/TRAP-07-*.md` (new), `docs/tasks/BOARD.md`,
`.agent/state.md`, `VibeDiscipline-Full-Plan.md` (gitignored, not committed).

## Implementation Notes
- Differences are deliberately concentrated at Tier L and in change handling.
  At Tier M the three methodologies are nearly the same: M is a single
  feature, so inventing extra waterfall phases there would be ceremony
  inflation (TRAP-05).
- Tier XS/S are identical under every methodology.

## Testing Requirements
`scripts/validate-portability.sh`, `node scripts/compile-permissions.cjs`
twice (idempotent), AGENTS.md line limit, and scratch-repo runs of
`set-methodology.cjs` and `check.sh` for: unset, agile, hybrid, waterfall
without PRD, waterfall with approved PRD+TRD, unknown value.

## Open Questions
1. **Assumed (flagged):** default is `hybrid` when unset, and the agent does
   not force a choice. Basis: a forced prompt at first use is friction for
   Tier 1 (skills-only) installs. Impact: one line in `methodology.md`.
2. Not a failure-driven rule (plan §49: "every rule must trace to a real
   failure"). It is a requested product feature, so it is kept thin and the
   trap spec is the way to find out whether agents follow it.
