---
name: implement
description: >
  Use whenever writing or editing code, at any tier. Enforces
  inspect-before-edit, reuse-before-create, and scope discipline.
loads: [_shared/ceremony-tiers.md, _shared/anti-slop.md, _shared/config-resolution.md]
---

# Implement

```
INSPECT → UNDERSTAND → PLAN → IMPLEMENT → VERIFY → REVIEW
```

## Before writing any code

- [ ] Read the task's acceptance criteria (or, at Tier XS/S, the exact
      requirement as stated)
- [ ] Read the files that will change — completely, not partially
- [ ] Search for an existing implementation of this behavior
- [ ] Search for an existing utility, helper, hook, service, or component
      that already solves this
- [ ] Identify the conventions in the surrounding code (or in
      `docs/CONVENTIONS.md` / `.agent/adapters/*/conventions.md` if present)
- [ ] Identify the boundaries the change touches
- [ ] Confirm the ceremony tier is still correct now that the code is visible

## While implementing

- Match the surrounding code's style, naming, and idiom — not personal
  preference
- Reuse before creating. Never build a new abstraction when an existing
  one already solves the problem — if a near-match exists, extend it or
  state explicitly why extending it is wrong
- Keep the change inside the declared scope; do not refactor unrelated code
- Handle the error and empty paths, not only the happy path
- No debug output (`console.log`, `dd()`, `dump()`, `var_dump`), no
  commented-out experiments
- Adding a dependency requires justification recorded in the task doc
  (Tier M+) or stated in-conversation (Tier S)

## Before declaring done

- [ ] Every acceptance criterion demonstrably satisfied, one by one
- [ ] Tests written and passing
- [ ] Lint / format / typecheck passing
- [ ] `scripts/check.sh` (`vibe check`) clean
- [ ] Diff reviewed line by line — see `code-review` skill
- [ ] Nothing outside the declared scope was touched

## The reuse rule

> Never create a new abstraction when an existing one already solves the
> problem. Search first. If a near-match exists, extend it or state
> explicitly why extending it is wrong.

## See also

`.agent/skills/_shared/anti-slop.md` for the full catalogue of smells this
skill exists to prevent. If present, `.agent/ecosystems/<lang>/pitfalls.md`
and `.agent/adapters/<framework>/pitfalls.md` add stack-specific failure
modes — load whichever matches the detected stack in `stack.lock.yml`.
