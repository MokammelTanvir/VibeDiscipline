---
name: code-review
description: >
  Use before any work is considered complete, at Tier S and above.
  Self-review of the diff against correctness, security, and scope.
loads: [_shared/anti-slop.md]
---

# Code Review

Self-review before any work is considered complete — this is not
optional, and it is not the same step as `git diff` review before commit
(see `git/SKILL.md`), though they often happen back to back.

## Dimensions

- **Correctness** — does it satisfy every acceptance criterion?
- **Edge cases** — null, empty, zero, negative, huge, concurrent, unicode
- **Error handling** — failures surfaced, not swallowed
- **Security** — auth/authz, input validation, injection, secrets (see
  `.agent/adapters/*/pitfalls.md`, if present, for stack-specific checks;
  a full `security` skill ships in v0.2)
- **Performance** — N+1 queries, unbounded loops, unnecessary work in hot paths
- **Maintainability** — will someone understand this in six months?
- **Architecture** — does it respect existing boundaries?
- **Reuse** — did it duplicate something that already exists?
- **Tests** — do they test behavior and cover every acceptance criterion?
- **API compatibility** — any breaking change to a public contract?
- **Documentation** — does anything documented become wrong?
- **Scope** — ★ is anything here outside the declared task?

## The scope check (highest-value single question)

> Is every changed line traceable to an acceptance criterion?

Any line that is not is either scope creep or an undeclared fix. Surface
both — and usually move the undeclared fix to a separate commit or task.

## Output format

```
Code Review — TASK-004

Critical: 0    High: 0    Medium: 2    Low: 3

MEDIUM · UserService::register duplicates validation already in
         RegisterRequest → remove the duplicate
MEDIUM · No test for the "existing email" acceptance criterion
LOW    · Variable `d` → `verificationDeadline`

Verdict: fix the two MEDIUM findings before commit.
```

## Rule

The agent **fixes** the findings it raises before proceeding. A review
that produces a list and then commits anyway is theater. Critical and
High findings block completion; Medium/Low are fixed or explicitly
deferred with a stated reason.
