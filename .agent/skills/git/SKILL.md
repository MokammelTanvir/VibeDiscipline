---
name: git
description: >
  Use for any git operation — session start, pre-commit, pushing,
  branching. Enforces professional, atomic, honest git behavior.
loads: [_shared/config-resolution.md]
---

# Git

## Session start

```bash
git status
git branch --show-current
git log --oneline -20        # learn THIS project's real conventions
```

If the working tree is dirty, identify which changes are pre-existing and
state explicitly that they will not be touched or committed.

## Branching

Use these defaults **only** if `git log` shows no existing convention:

```
feature/<slug>   fix/<slug>   refactor/<slug>
docs/<slug>      test/<slug>  chore/<slug>
```

If the project already uses something else (e.g. `TICKET-123-description`),
adopt it. Never commit directly to the default branch without confirmation.

## Pre-commit sequence — never skipped

1. `git status` — what is staged, what is not
2. `git diff` — unstaged
3. `git diff --cached` — staged, reviewed line by line
4. Run tests
5. Run lint / format / typecheck
6. Run `scripts/check.sh` (`vibe check`)
7. Scan for secrets
8. Verify every change belongs to this task
9. Stage precisely — never `git add -A` in a dirty tree
10. Commit

## Commit messages

```
<type>(<scope>): <imperative summary under 72 chars>

<why this change was needed>
<what approach was taken, if non-obvious>

<refs: TASK-004>
```

Types: `feat · fix · refactor · test · docs · chore · perf · build · ci · style · revert`

Forbidden: `update`, `changes`, `fix stuff`, `final`, `final fix`, `wip`,
`misc improvements`, `various changes`.

## Atomic commits

One commit = one logical change. Never mix a feature with an unrelated
refactor, or a fix with reformatting of untouched files.

**The pre-existing changes rule:** never commit modifications that existed
in the working tree before this session started. Name them and leave
them alone.

## Attribution

Whether commits carry an AI attribution trailer is the project's choice.
If `.agent/config.yml` exists, follow its `commit.attribution_trailer`
setting. If it does not exist, default to no trailer unless the human
states a preference — do not decide this unilaterally either way.
