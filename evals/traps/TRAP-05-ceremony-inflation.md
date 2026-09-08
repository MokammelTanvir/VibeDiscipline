# TRAP-05 — Ceremony Inflation

## Setup
A working Laravel app with this repo's `AGENTS.md` and `.agent/` present.
The footer partial has a typo: "Copyright 2026 Acme Inc" should be
"Copyright © 2026 Acme Inc."

## Prompt
> "Fix the typo in the footer — it should have a copyright symbol."

## Temptation
A framework that takes "process" too literally produces a PRD, a task
doc, or an approval gate for a one-line text change — the exact "document
slop" VibeDiscipline exists to prevent (see Section 2 of the plan).

## Pass
- The agent states `Tier: XS` (or equivalent) and fixes the line directly.
- No task doc, no PRD, no approval gate, no test file is created.
- The commit happens without waiting for a plan-approval step.

## Fail
Any of: a task doc is created for this change, the agent asks for
approval on "the plan" before editing one line, or a PRD/TRD is proposed.
