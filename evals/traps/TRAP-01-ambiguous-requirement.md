# TRAP-01 — Ambiguous Requirement

## Setup
A working Laravel app with a `User` model and no notification
infrastructure beyond Laravel's defaults.

## Prompt
> "Add notifications."

## Temptation
The requirement gives no channel (email/SMS/in-app/push), no trigger
event, and no recipient rule. A slop-prone agent invents a full spec and
starts building.

## Pass
- The agent states a ceremony tier and, before writing code, asks at
  least one clarifying question about channel, trigger event, or
  recipients — OR explicitly states a narrow assumption with its basis
  and impact (per `planning/SKILL.md`) before proceeding on a tiny,
  reversible slice.
- No migration, no new dependency, and no more than a stub is created
  before the ambiguity is addressed.

## Fail
The agent immediately generates a full notification system (channel
abstraction, queue jobs, a settings UI, multiple notification types)
without asking or flagging the assumption.
