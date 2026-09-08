# AGENTS.md — Project Constitution

This project uses **VibeDiscipline**: an engineering discipline layer that
makes AI coding agents behave like disciplined professional engineers.
Full methodology: see `.agent/skills/README.md`. This file is the only
always-loaded instruction — keep it under 100 lines. Detail lives in skills.

## Ceremony tiers — decide this FIRST, before any other step

| Tier | Covers | Required process |
|---|---|---|
| **XS** | Typo, copy, comment, config value | Edit → verify → commit. No plan, no doc, no test. |
| **S** | Bug fix, small enhancement, single file | Reproduce → root cause → fix → regression test → self-review → commit |
| **M** | New feature in existing system, schema addition | Recon → plan w/ acceptance criteria → **approval** → implement → tests → review → security scan → diff review → commit → docs |
| **L** | New subsystem/service, architectural change, new auth/payment/multi-tenancy *architecture* | Discovery → PRD → TRD → Architecture/ADR → UI/UX → task breakdown → **approval** → M-tier loop per task |

State the tier in one line before starting: `Tier: S — bug fix in cart total, single file.`
**Default to the lowest plausible tier.** Escalate only if: new auth *architecture* (not
a routine feature using an existing auth pattern), payments/PII, a changed schema or
public API, a new dependency, affects >~5 files, or the
requirement is ambiguous. Never invent ceremony no one asked for — see
`.agent/skills/_shared/ceremony-tiers.md` for the full routing rules.

## Where things live

```
.agent/skills/         how to perform each kind of task (recon, planning, implement,
                        code-review, git, handoff) — read the relevant SKILL.md before acting
.agent/skills/_shared/  ceremony-tiers.md · anti-slop.md · config-resolution.md
.agent/rules/           general engineering behavior
.agent/ecosystems/php/  PHP/Composer-level knowledge
.agent/adapters/laravel/ Laravel-specific conventions and pitfalls
.agent/permissions.yml  what may/may not be done — compiled into real enforcement,
                        this is not optional reading
.agent/stack.lock.yml   detected commands for THIS project (run `recon` if missing)
.agent/state.md         cross-session working memory — read at session start,
                        write at session end
docs/                   PRD, TRD, architecture, ADRs, task docs (Tier M/L only)
docs/tasks/BOARD.md     live task status
```

## Session protocol

**Start:** read `.agent/state.md` (if present) → read `.agent/stack.lock.yml`
(if missing, run the `recon` skill first) → `git status` → report what you're
resuming and name any pre-existing uncommitted changes you will not touch.

**End:** update `.agent/state.md` and `docs/tasks/BOARD.md` (if present) with
what's done, what's next, and what's blocked.

## Non-negotiables

1. **Never bypass `.agent/permissions.yml`.** A DENY is never worked around.
   Auto mode never means unrestricted mode.
2. **Never invent a requirement.** Ambiguity gets a question, not an assumption
   — or a stated, flagged assumption if the impact is low.
3. **Never commit an unreviewed diff**, or changes that pre-existed in the
   working tree before this session started.
4. **Silence is not approval.** Tier M/L work needs a recorded approval
   (see `.agent/skills/planning/SKILL.md`) before implementation begins.
5. **Detect the stack — never assume a command.** If `stack.lock.yml` is
   stale or missing, re-run `recon` before running anything destructive.

## Adapt, don't override

If this codebase already has its own git style, test layout, or naming —
follow the codebase, not this document's defaults. Recon before advising.
