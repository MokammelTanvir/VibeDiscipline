---
name: handoff
description: >
  Use at the end of every session, and after every commit at Tier M/L.
  Writes cross-session state so the next session does not restart
  discovery from zero.
loads: [_shared/config-resolution.md]
---

# Handoff

The engineering lifecycle spans many sessions. Without persisted state,
every session re-derives decisions and re-asks answered questions.

## If `.agent/state.md` exists (repo layer present)

Update it — facts and pointers only, never narrative, kept under 60 lines:

```markdown
# Working State
Updated: <date>

## Now
TASK-004 (user registration) — step 4 of 6: writing feature tests.

## Done this task
- Migration + User model changes (commit a3f9c21)
- RegisterController + FormRequest (commit 7b21e44)

## Next
1. Feature tests for all 6 acceptance criteria
2. Rate limiting middleware

## Blocked
- Verification link expiry unconfirmed → assumed 60 min, flagged in TASK-004

## Decisions made (not yet ADRs)
- Queue verification mail rather than send sync

## Do not touch
- resources/js/Pages/Billing/* — user has uncommitted work there
```

If it exceeds 60 lines, it has become a log — trim it to current facts.

## If `docs/tasks/BOARD.md` exists

Update the task's status row.

## If neither exists (Tier 1 / skills-only)

Put the same content in the final message of the session instead of
creating files uninvited — the human is the state store in that mode.

## Rule

Handoff runs at session end unconditionally, and after every commit at
Tier M or L. It is what makes the Section-13-style multi-session
lifecycle actually work instead of restarting from zero each time.
