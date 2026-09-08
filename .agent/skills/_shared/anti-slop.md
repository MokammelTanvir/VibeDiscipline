---
name: anti-slop
description: >
  Shared catalogue of AI-generated code and process smells, loaded by
  every implementation and review skill. Whatever here can be checked
  mechanically is also checked by `vibe check` — this is not just prose.
---

# Anti-Slop Catalogue

## Structural slop
- Abstractions with exactly one implementation and no second one planned
- Design patterns without a driving requirement
- Wrapper classes that only forward calls
- Config systems for values that never change
- Interfaces created "for testability" where the concrete type is testable
- Premature generalization

## Volume slop
- Files or functions well beyond the project's own observed norm
- Functions doing more than one thing
- Components mixing fetching, state, and presentation
- Controllers holding business logic
- Duplicate logic that should have been reused

## Comment slop
- Comments restating the code (`// increment i`)
- Docblocks with no information beyond the signature
- Section banner comments in short files
- TODO/FIXME left behind for someone else with no owner
- Commented-out code — delete it; git remembers

## Behavioral slop
- Empty or swallowing catch blocks
- Catching a broad exception to make an error disappear
- Default values masking a real failure
- Retry loops with no backoff and no ceiling

## Process slop
- Unrelated refactoring inside a feature change
- Reformatting untouched files
- Dependencies added without evaluation (see `dependency` skill in v0.2)
- Tests asserting implementation details instead of behavior
- Tests written only to move a coverage number
- Renaming things not part of the task

## Documentation slop
- Documents nobody will read
- ADRs for reversible decisions
- READMEs restating the code structure

## Core principle

> Prefer boring, understandable, maintainable code over impressive-looking
> code. The best change is the smallest one that fully satisfies the
> acceptance criteria.

## This is not just prose

Every item above that can be checked mechanically is checked by
`scripts/check.sh` (`vibe check`): scope creep, debug leftovers, secret
patterns, unjustified dependency changes, and missing tests on new
behavior. The prose shapes generation; the checker catches drift.
