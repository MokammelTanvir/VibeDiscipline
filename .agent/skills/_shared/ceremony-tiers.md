---
name: ceremony-tiers
description: >
  Shared routing logic loaded by every workflow skill. Decides how much
  process a piece of work deserves before any other skill acts.
---

# Ceremony Tiers

The single most important decision in VibeDiscipline: **how much process
does this deserve?** Get this wrong and the system either produces
document slop (a PRD for a typo) or unsafe shortcuts (no plan for a
schema change).

## The tiers

| Tier | Covers | Required process |
|---|---|---|
| **XS** | Typo, copy text, comment, formatting, config value, version bump | Edit → verify → commit. No plan. No doc. No test. |
| **S** | Bug fix, small enhancement, single-file change, copy/UI tweak with logic | Reproduce → root cause → fix → regression test → self-review → commit. Root-cause note in the commit body. No standalone doc. |
| **M** | New feature inside an existing system, new endpoint, new screen, schema addition | Recon → plan with acceptance criteria → human approval → implement → tests → review → security scan → diff review → atomic commit(s) → docs update. TASK doc required. |
| **L** | New subsystem, new service, new project, architectural change, migration, auth/payment/multi-tenancy | Discovery → PRD → TRD → Architecture → ADR → UI/UX → task breakdown → approval gate → M-tier loop per task. Full document set required. |

## Routing rules

1. **Default to the lowest plausible tier.** The agent justifies escalation,
   never de-escalation. AI agents over-produce by default — the bias must
   push down.

2. **Escalate one tier if any of these is true:**
   - Touches authentication, authorization, payments, or PII
   - Changes a database schema or a data migration
   - Changes a public API contract or a shared interface
   - Requires a new dependency
   - Affects more than ~5 files or ~200 lines
   - Introduces a new architectural boundary
   - The requirement is ambiguous
   - The blast radius is unclear

3. **De-escalate only when the human explicitly says so.**

## Tier declaration

Before any work, state one line:

```
Tier: S — bug fix in the cart total calculation, single file, has a repro.
```

The human can override with one word. This makes the process decision
**visible and cheap to correct** instead of a hidden assumption.

## The anti-ceremony rule

> Never create a document that no one will read.
>
> Every artifact must have a named consumer: a human reviewer, a future
> session, a test, or a downstream task. If it has none, do not write it.

## Consuming this file

Every workflow skill (`recon`, `planning`, `implement`, `code-review`,
`git`, `handoff`) starts by determining the tier, then executes only the
subset of the full lifecycle that tier requires. One process, four depths
— never a different process per tier.
