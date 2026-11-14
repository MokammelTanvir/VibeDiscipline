---
name: methodology
description: >
  Shared routing logic loaded by planning and handoff. Decides in what order
  work is sequenced and where the human approval gates sit: agile, waterfall
  or hybrid. Orthogonal to ceremony tiers.
---

# Methodology

Ceremony tier answers **how much** process a change deserves. Methodology
answers **in what order, and where the human gates sit**. Both always apply;
neither replaces the other.

## Resolve it

1. If `.agent/config.yml` exists, read `workflow.methodology`
   (`agile | waterfall | hybrid`).
2. Otherwise, or if the key is unset: `hybrid`. Say so once, at the first
   Tier M/L plan: `Methodology: hybrid (default; set workflow.methodology to change).`
3. A human saying "use waterfall for this one" overrides the config for that
   piece of work. Write the override into the task doc.
4. An unknown value is a typo: ask, do not guess.

## Invariants (all three)

- Never changes the tier. XS and S are identical in every methodology.
- Never creates a document below what the tier requires (anti-ceremony rule).
- Never relaxes `.agent/permissions.yml`, if it exists.
- Approval stays a recorded artifact: a missing `approved_at` means not
  approved, silence is not consent, a material change re-asks.

## What differs

| | agile | waterfall | hybrid (default) |
|---|---|---|---|
| **Tier M** | Task doc as a user story ("As a ..., I want ..., so that ...") plus acceptance criteria. Approval per task. Smallest vertical slice. | Task doc with Goal, criteria, Affected Areas and Implementation Notes all complete before approval. No code before it. | Task doc plus criteria. Approval per task. |
| **Tier L** | One-page product brief and a backlog on the board. Split into increments; the first is the thinnest end-to-end slice. Gates: brief + increment 1, then each next increment. | Five phases in order, each ending in a recorded approval: **1 Requirements** (PRD) → **2 Design** (TRD, architecture/ADR, UI/UX) → **3 Implementation** (task breakdown, M-loop per task) → **4 Verification** (full tests, security review) → **5 Release** (docs, handoff). No phase starts before the previous is approved. | Full Tier L document set up front, one approval, then the M-loop per task. |
| **Requirement changes** | New board row, taken as a later increment. The running task's non-goals still hold. | Change request: update the PRD/TRD and re-approve before touching code. | A material change re-asks approval. |
| **"Done" means** | The increment's criteria shown one by one; leftovers become new board rows. | The phase's exit criteria met and approved; at Verification every task's criteria checked. | Each task's criteria shown one by one. |

At Tier M the three are close on purpose: M is a single feature, and extra
phases there would be ceremony inflation. The difference concentrates at
Tier L and in how change is handled.

## Phase and approval markers (waterfall)

PRD and TRD carry the same frontmatter as a task doc: `approved_by` and
`approved_at`. Empty or missing means the phase gate is not passed. Start
from `planning/templates/PRD.md` and `TRD.md`. Where the docs tree exists the paths are `docs/product/PRD.md` and
`docs/technical/TRD.md`; if it does not exist, hold the phase gate in the
conversation instead of creating a docs tree uninvited.

## Recording and switching

- `handoff` writes `Methodology: <value>` into the working state and, under
  waterfall, `Phase: <n of 5, name>`.
- Switching mid-project changes how *future* work is sequenced; work already
  approved keeps its approval. Ask first, then record the switch as a decision.
- A check in `scripts/check.sh` warns, never fails, when waterfall is set,
  source changed and the PRD/TRD is unapproved. It cannot tell an XS/S fix
  from feature work, so the agent must not treat the warning as the rule.
