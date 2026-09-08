---
name: planning
description: >
  Use when a requirement is stated and before any code is written at
  Tier M or L. Turns a requirement into a tiered plan with testable
  acceptance criteria and a recorded approval gate.
loads: [_shared/ceremony-tiers.md, _shared/config-resolution.md]
---

# Planning

## Procedure

1. Confirm the ceremony tier (see `_shared/ceremony-tiers.md`). If XS or S,
   this skill is not needed — go straight to `implement`.

2. If the codebase is unfamiliar or `.agent/stack.lock.yml` is missing or
   stale, run `recon` first.

3. Write acceptance criteria — **testable statements only**. "Works well"
   is not a criterion. "Returns 422 with a `message` key" is — but check
   which surface this actually is first: a 422 JSON body only applies to
   an API/XHR consumer. A traditional server-rendered form (Blade, plain
   HTML) redirects back with session validation errors on failure — state
   whichever one the app actually is, don't default to the JSON framing.

4. Write explicit non-goals — the scope fence. Mandatory at Tier M+.

5. If `docs/tasks/` exists, write the task doc (template below) and add a
   row to `docs/tasks/BOARD.md`. If it does not exist, present the same
   content in the conversation instead of creating a docs tree uninvited.

6. **Stop and wait for approval** before implementing, at Tier M and L.
   Approval must be a recorded artifact, not an assumption:
   - Absence of an approval marker means NOT approved. Silence is never consent.
   - Write the marker only after an explicit human "approved" / "go ahead"
     on *that specific* plan.
   - A material change to scope, approach, or dependencies invalidates
     prior approval — re-ask.
   - Approval on the plan never overrides `.agent/permissions.yml`, if it
     exists — or the conservative confirm-by-default behavior from
     `_shared/config-resolution.md` when it does not.

7. State any assumption explicitly, with its basis and its impact:
   ```
   Assumption: verification links expire after 60 minutes.
   Basis:      no requirement given; matches the pattern in PasswordReset.
   Impact:     if wrong, one config constant changes.
   Proceeding — correct me if this is wrong.
   ```
   Low-impact assumptions are stated and work continues. High-impact
   assumptions block on an answer.

## Task doc template

```markdown
---
id: TASK-00X
title:
tier: M
status: planned        # planned | approved | in-progress | blocked | review | done
approved_by:
approved_at:
depends_on: []
---

## Goal

## Acceptance Criteria
- [ ]

## Non-goals

## Affected Areas

## Implementation Notes

## Testing Requirements

## Open Questions
```

## Rules

- One task = one atomic commit wherever possible.
- The agent works *against* acceptance criteria and reports completion
  *per criterion*, never as a vague "done".
- Never create a PRD/TRD/ADR for Tier M work — those are Tier L only
  (full templates ship in v0.2; until then, keep the plan to the task
  doc above and flag if the work turns out to be Tier L in disguise).
